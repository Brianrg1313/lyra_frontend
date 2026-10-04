import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/connection/cloud_presence.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_service.dart';

/// One app, one session on a device with a master (`docs/plan-offline-lan.md` §9.6, D14, D16):
/// an online sign in opens the master's session too and runs `hybrid`, "work offline" keeps it,
/// the internet going and coming back locks and opens the cloud-only areas in place.
void main() {
  setUpAll(() => AppController.devMode = true);
  setUp(() => Deployment.use(DeploymentMode.cloud, paired: DeploymentRole.client));
  tearDown(() {
    Deployment.use(DeploymentMode.cloud);
    CapabilityService().internet = true;
    CapabilityService().linked = true;
  });

  HybridService service(_Master master) => HybridService(lan: master, presence: _Presence(true));

  group('join', () {
    test('a password sign in opens the master with the same password and runs hybrid', () async {
      final master = _Master();
      final hybrid = service(master);

      expect(await hybrid.join("ada@lyra.app", password: "correct horse battery"), HybridJoin.joined);
      expect(master.signIns, [("ada@lyra.app", "correct horse battery")]);
      expect(Deployment.mode, DeploymentMode.hybrid);
      expect(Deployment.role, DeploymentRole.client);
      expect(hybrid.joined, isTrue);
      hybrid.dispose();
    });

    test('a code sign in, or a master password other than the cloud one, asks for it once', () async {
      final master = _Master(password: "the master's own");
      final hybrid = service(master);

      expect(await hybrid.join("ada@lyra.app"), HybridJoin.needsPassword);
      expect(master.signIns, isEmpty);
      expect(await hybrid.join("ada@lyra.app", password: "the cloud's"), HybridJoin.needsPassword);
      expect(Deployment.mode, DeploymentMode.cloud);

      expect(await hybrid.signIn("ada@lyra.app", "the master's own"), isTrue);
      expect(Deployment.mode, DeploymentMode.hybrid);
      hybrid.dispose();
    });

    test("a master session left by someone else is signed out, not taken", () async {
      final master = _Master(signedInAs: "grace@lyra.app");
      final hybrid = service(master);

      expect(await hybrid.join("ada@lyra.app"), HybridJoin.needsPassword);
      expect(master.signedOut, 1);
      hybrid.dispose();
    });

    test("the same person's kept session is taken as it is", () async {
      final master = _Master(signedInAs: "ada@lyra.app");
      final hybrid = service(master);

      expect(await hybrid.join("ADA@lyra.app"), HybridJoin.joined);
      expect(master.signedOut, 0);
      hybrid.dispose();
    });

    test('no master answering, or none at all, leaves the app online', () async {
      final away = service(_Master(reach: LanStatus.unreachable));
      expect(await away.join("ada@lyra.app", password: "x"), HybridJoin.unavailable);
      expect(Deployment.mode, DeploymentMode.cloud);
      away.dispose();

      Deployment.use(DeploymentMode.cloud);
      final unpaired = service(_Master());
      expect(await unpaired.join("ada@lyra.app", password: "x"), HybridJoin.unavailable);
      unpaired.dispose();
    });
  });

  test('starting the app resumes hybrid only when the master keeps the session', () async {
    final kept = service(_Master(signedInAs: "ada@lyra.app"));
    expect(await kept.resume(), isTrue);
    expect(Deployment.mode, DeploymentMode.hybrid);
    kept.dispose();

    Deployment.use(DeploymentMode.cloud, paired: DeploymentRole.client);
    final signedOut = service(_Master());
    expect(await signedOut.resume(), isFalse);
    expect(Deployment.mode, DeploymentMode.cloud);
    signedOut.dispose();
  });

  test('work offline keeps the session and locks the cloud areas; work online opens them', () async {
    final hybrid = service(_Master(signedInAs: "ada@lyra.app"));
    await hybrid.resume();
    expect(CapabilityService().shows("messages"), isTrue);

    hybrid.workOffline();
    expect(Deployment.mode, DeploymentMode.local);
    expect(hybrid.offline, isTrue);
    expect(CapabilityService().of("messages"), Capability.needsInternet);
    expect(CapabilityService().shows("sales"), isTrue);

    hybrid.workOnline();
    expect(Deployment.mode, DeploymentMode.hybrid);
    expect(CapabilityService().shows("messages"), isTrue);
    hybrid.dispose();
  });

  test('the internet going and coming back locks and opens the cloud areas in place, at once', () async {
    final presence = _Presence(false);
    final hybrid = HybridService(lan: _Master(signedInAs: "ada@lyra.app"), presence: presence);
    await hybrid.resume();

    expect(presence.started, isTrue);
    expect(CapabilityService().internet, isFalse);
    expect(CapabilityService().of("messages"), Capability.needsInternet);
    expect(Deployment.mode, DeploymentMode.hybrid);

    presence.live.value = true;
    expect(CapabilityService().shows("messages"), isTrue);

    presence.live.value = false;
    expect(CapabilityService().of("messages"), Capability.needsInternet);

    hybrid.stop();
    expect(presence.started, isFalse);
    expect(Deployment.mode, DeploymentMode.cloud);
    hybrid.dispose();
  });

  test('before the socket answers, the cloud areas stay as they were', () async {
    final presence = _Presence();
    final hybrid = HybridService(lan: _Master(signedInAs: "ada@lyra.app"), presence: presence);
    await hybrid.resume();

    expect(CapabilityService().internet, isTrue);

    presence.live.value = false;
    expect(CapabilityService().internet, isFalse);
    hybrid.stop();
    hybrid.dispose();
  });

  test('a session on the master alone follows the backend and goes online with a sign in', () async {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.client);
    final presence = _Presence(false);
    final master = _Master(signedInAs: "ada@lyra.app");
    final hybrid = HybridService(lan: master, presence: presence);
    await master.open();
    master.changed();

    expect(presence.started, isTrue);
    expect(hybrid.masterOnly, isTrue);
    expect(hybrid.canGoOnline, isFalse);

    presence.live.value = true;
    expect(hybrid.canGoOnline, isTrue);
    // The home opens the online sign in by itself once; after that it waits to be asked.
    expect(hybrid.shouldOfferOnline, isTrue);
    hybrid.offeredOnline();
    expect(hybrid.shouldOfferOnline, isFalse);

    // Signed out of the master, there is nothing to take online.
    await master.signOut();
    master.changed();
    expect(hybrid.canGoOnline, isFalse);
    expect(presence.started, isFalse);

    await master.signIn("ada@lyra.app", "correct horse battery");
    master.changed();
    expect(hybrid.canGoOnline, isTrue);

    expect(await hybrid.join("ada@lyra.app"), HybridJoin.joined);
    expect(Deployment.mode, DeploymentMode.hybrid);
    expect(hybrid.canGoOnline, isFalse);
    hybrid.stop();
    hybrid.dispose();
  });

  test('a company not joined with its company online locks the cloud areas with their own reason', () {
    Deployment.use(DeploymentMode.hybrid, role: DeploymentRole.client);
    CapabilityService().linked = false;

    expect(CapabilityService().of("messages"), Capability.needsLink);
    expect(CapabilityService().locked("messages"), isTrue);
    expect(CapabilityService().shows("sales"), isTrue);
    expect(CapabilityService().cloudServices, isFalse);
  });

  test("a master made online starts from the company's profile and its link", () {
    final profile = BusinessProfileModel.fromJson({
      "name": " Lovelace Café ", "country": "ve", "currency": "usd", "language": "es", "activity_type": "REAL_ESTATE"
    });

    expect(HybridService.companyFrom(profile, "cloud-1"), {
      "name": "Lovelace Café", "country": "VE", "currency": "USD", "language": "es", "activity": "REAL_ESTATE", "cloudId": "cloud-1"
    });

    final unknown = BusinessProfileModel.fromJson({"name": "Nowhere", "country": "ZZ", "currency": "USD"});
    expect(HybridService.companyFrom(unknown, "cloud-1"), isNull);
  });

  test("a master company with none online is made there from its profile", () {
    final profile = BusinessProfileModel.fromJson({
      "name": " Lovelace Café ", "legal_name": "Lovelace Café C.A.", "country": "ve", "currency": "usd", "language": "ES",
      "activity_type": "FOOD"
    });

    expect(HybridService.cloudCompanyFrom(profile), {
      "LEGAL_NAME": "Lovelace Café C.A.", "NAME": "Lovelace Café", "ACTIVITY_TYPE": "FOOD", "COUNTRY": "VE", "LANGUAGE": "es"
    });

    // The cloud requires a legal name and an activity: the name stands in, "other" for none.
    final bare = BusinessProfileModel.fromJson({"name": "Nowhere"});
    expect(HybridService.cloudCompanyFrom(bare), {"LEGAL_NAME": "Nowhere", "NAME": "Nowhere", "ACTIVITY_TYPE": "OTHER"});
  });

  test("an unlinked company's cloud socket isn't opened: the cloud doesn't know the company", () async {
    Deployment.use(DeploymentMode.hybrid, role: DeploymentRole.client);
    CapabilityService().linked = false;

    var moved = 0;
    void count() => moved++;
    ConnectionService().addListener(count);

    await ConnectionService().open();

    ConnectionService().removeListener(count);
    expect((moved, ConnectionService().isConnected), (0, false));
  });

  test("the server section is wherever a master can be: a paired device, any computer online", () {
    Deployment.use(DeploymentMode.cloud, paired: DeploymentRole.client);
    expect(CapabilityService().exists("local_server"), isTrue);
    expect(Ops.all.map((op) => op.name), contains("business.link"));
  });
}

/// A paired master: [reach] when opened, signed in as [signedInAs] if anyone, taking [password].
class _Master extends LanService {
  _Master({this.reach = LanStatus.signedOut, this.signedInAs, this.password = "correct horse battery"})
    : super(store: MemoryLanIdentityStore());

  final LanStatus reach;
  final String password;
  String? signedInAs;

  final signIns = <(String, String)>[];
  int signedOut = 0;

  LanStatus _now = LanStatus.idle;

  @override
  LanStatus get status => _now;

  @override
  Future<LanStatus> open() async => _now = signedInAs != null && reach == LanStatus.signedOut ? LanStatus.ready : reach;

  @override
  Future<LanStatus> signIn(String login, String password) async {
    signIns.add((login, password));
    if (password != this.password) return LanStatus.signedOut;

    signedInAs = login;
    return _now = LanStatus.ready;
  }

  /// The real service notifies on every status change; this one only when told.
  void changed() => notifyListeners();

  @override
  Future<void> signOut() async {
    signedOut++;
    signedInAs = null;
    _now = LanStatus.signedOut;
  }

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async => switch (op) {
    Ops.sessionBootstrap => {"client": {"email": signedInAs, "username": "ada"}},
    _ => null
  };
}

/// The backend's socket, said by the test: [live] null until it answers.
class _Presence extends CloudPresence {
  _Presence([bool? live]) {
    this.live.value = live;
  }

  bool started = false;

  @override
  void start() => started = true;

  @override
  void stop() => started = false;
}
