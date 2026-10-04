import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/toolkit/api.dart' show cloudReachable;
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/client/sources/session_cloud_source.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import './lan_service.dart';

/// What [HybridService.join] did with an online sign in on a device with a master.
enum HybridJoin {
  /// The master took the session too: the app runs `hybrid`.
  joined,

  /// The master answered but needs this person's password on it (a sign in by code, or a
  /// master password other than the cloud's): asked once, [HybridService.signIn].
  needsPassword,

  /// No master here, or it doesn't answer (away from the office): the app runs `cloud`.
  unavailable
}

/// One app, one session on a device with a master (`docs/plan-offline-lan.md` §9.6, D14, D18).
///
/// Signing in online there opens the person's session on the master too ([join]), so it
/// outlives the internet, the subscription and a restart; the app then runs `hybrid`: the
/// master's domains always from the master, the cloud-only areas from the cloud while
/// [CapabilityService.internet] holds, which this service keeps current by looking at the
/// backend every [every] while it answers and every [retry] while it doesn't. The cloud's socket
/// says it first: connecting proves the backend is there, and dropping makes it look right away
/// instead of at the next turn (a socket also drops when its handshake is refused, so a drop is a
/// reason to look, not an answer). "Work offline" ([workOffline]) is the same session without the
/// cloud.
///
/// It also links the master's company to its cloud company ([link], `business.md` B-30), which
/// the cloud-only areas need to know which company they serve.
///
/// A session opened on the master alone (signed in while the backend didn't answer) has no
/// cloud session to go back to, so nothing would ever bring it online: while it lasts the
/// backend is looked at too, and [canGoOnline] says when an online sign in would join it.
///
/// App-wide (`initial_builder.dart`), like the [LanService] it works over.
class HybridService extends ChangeNotifier {
  HybridService({
    required LanService lan,
    Future<bool> Function()? cloud,
    ValueListenable<SocketStatus>? socket,
    this.every = const Duration(seconds: 10),
    this.retry = const Duration(seconds: 3),
    this.wait = const Duration(seconds: 6)
  }) : _lan = lan, _cloud = cloud ?? cloudReachable, _socket = socket ?? ConnectionService().listenable {
    _lan.addListener(_follow);
    _socketWas = _socket.value;
    _socket.addListener(_socketChanged);
  }

  final LanService _lan;
  final Future<bool> Function() _cloud;

  /// The cloud's socket status (`ConnectionService.listenable`).
  final ValueListenable<SocketStatus> _socket;
  late SocketStatus _socketWas;

  /// How often the backend is looked at while it answers.
  final Duration every;

  /// How often it is looked at while it doesn't: its return is what someone is waiting for.
  final Duration retry;

  /// How long the master gets to answer before the app goes on with the cloud alone.
  final Duration wait;

  Timer? _watch;

  /// Whether this session was opened online too: only such a session goes back online.
  bool _joined = false;
  bool get joined => _joined;

  /// Whether the person chose to work without the internet: the server section's switch.
  bool get offline => _joined && Deployment.mode == DeploymentMode.local;

  bool _backendAnswers = false;

  /// A session on the master alone while the backend answers: an online sign in as the same
  /// person ([join]) turns it `hybrid` without leaving it.
  bool get canGoOnline => _backendAnswers && masterOnly;

  bool _offeredOnline = false;

  /// [canGoOnline] and not offered yet this session: the home opens the online sign in by itself
  /// once ([offeredOnline]); after a "not now" it stays in the server section and locked sections.
  bool get shouldOfferOnline => canGoOnline && !_offeredOnline;

  void offeredOnline() => _offeredOnline = true;

  /// A session on the master alone: signed in while the backend didn't answer, so no cloud
  /// session to go back to.
  bool get masterOnly =>
    !_joined && Deployment.mode == DeploymentMode.local && Deployment.paired != null && _lan.status == LanStatus.ready;

  /// Starting the app: a device with a master and a stored cloud session enters `hybrid` when
  /// its master answers with the stored session. Answers whether it did; otherwise the app
  /// goes on as `cloud`, as it would away from the office.
  Future<bool> resume() async {
    if (Deployment.paired == null) return false;

    final status = await _open();
    if (status != LanStatus.ready) return false;

    _start();
    return true;
  }

  /// An online sign in just succeeded as [login] (an e-mail): the master's session for the same
  /// person, reusing [password] when the sign in was by password.
  Future<HybridJoin> join(String login, {String? password}) async {
    if (Deployment.paired == null) return HybridJoin.unavailable;

    var status = await _open();

    // A master session left by someone else on this computer is not this person's.
    if (status == LanStatus.ready && !await _isSignedInAs(login)) {
      await _lan.signOut();
      status = _lan.status;
    }

    if (status == LanStatus.ready) {
      _start();
      return HybridJoin.joined;
    }

    if (status != LanStatus.signedOut) return HybridJoin.unavailable;
    if (password == null) return HybridJoin.needsPassword;

    return await signIn(login, password) ? HybridJoin.joined : HybridJoin.needsPassword;
  }

  /// The person's password on the master, asked once after a sign in by code. The refusal is
  /// [LanService.error].
  Future<bool> signIn(String login, String password) async {
    if (await _lan.signIn(login, password) != LanStatus.ready) return false;

    _start();
    return true;
  }

  /// "Work offline": the master's session alone, the cloud-only areas locked, nothing signed out.
  void workOffline() {
    if (Deployment.mode != DeploymentMode.hybrid) return;

    _stopWatching();
    Deployment.offline();
    ConnectionService().close();
    CapabilityService().modeChanged();
    notifyListeners();
  }

  /// Back online from [workOffline].
  void workOnline() {
    if (!offline) return;

    _start();
  }

  /// The session ended (sign out): nothing is watched until the next one, and the sign in page
  /// picks the mode again from the network.
  void stop() {
    _stopWatching();
    _joined = false;
    _backendAnswers = false;
    _offeredOnline = false;
    if (Deployment.mode == DeploymentMode.hybrid) Deployment.online();
    CapabilityService().internet = true;
    notifyListeners();
  }

  /// Whether to ask, once, to join the master's company with its cloud company: the master's
  /// owner, online, the company not linked and no "not now" given.
  bool get shouldAskLink {
    if (Deployment.mode != DeploymentMode.hybrid || !CapabilityService().internet) return false;

    final active = businessService.activeId == null ? null : businessService.active;
    if (active == null || active.cloudId != null) return false;

    return PermissionsService().owns() && !PreferencesService().linkDeclined;
  }

  /// The cloud companies this account manages (`business.settings.edit` in the cloud's tree),
  /// the one named like the master's first: what [link] may join it to (`business.md` B-32).
  Future<List<BusinessModel>> linkCandidates() async {
    final init = await const SessionCloudSource().bootstrap();
    final permissions = init["permissions"];
    final name = businessService.activeId == null ? "" : businessService.active.name.trim().toLowerCase();

    bool manages(BusinessModel business) {
      if (permissions is! Map) return false;

      Object? node = permissions[business.id];
      for (final key in const ["business", "settings", "edit"]) {
        if (node is! Map) return false;
        node = node[key];
      }

      return node == true;
    }

    final candidates = BusinessModel.fromTable(init["businesses"]).where(manages).toList();
    candidates.sort((a, b) {
      final aSame = a.name.trim().toLowerCase() == name;
      final bSame = b.name.trim().toLowerCase() == name;

      return aSame == bSame ? 0 : (aSame ? -1 : 1);
    });

    return candidates;
  }

  /// Joins the master's company with [cloud] (`business.link`): its cloud-only areas open.
  Future<void> link(BusinessModel cloud) async {
    await _lan.call(Ops.businessLink, args: {"cloudId": cloud.id});
    businessService.linked(cloud.id);
    notifyListeners();
  }

  /// The company a master made from the cloud starts with (plan D16, `business.md` B-30): the
  /// cloud company's profile as far as the engine's catalogues take it, and its id; the rest
  /// arrives with the sync (phase 6). Null when the profile can't make one (no country or
  /// currency the engine knows): the welcome then creates it.
  static Map<String, Object?>? companyFrom(BusinessProfileModel profile, String cloudId) {
    final country = profile.country.trim().toUpperCase();
    final currency = profile.currency.trim().toUpperCase();
    if (profile.name.trim().isEmpty || Catalogs.country(country) == null || !Catalogs.hasCurrency(currency)) return null;

    final language = profile.language.trim().toLowerCase();
    final activity = profile.activity == BusinessActivity.unknown ? "" : profile.activity.value;

    return {
      "name": profile.name.trim(),
      "country": country,
      "currency": currency,
      "language": Catalogs.languages.contains(language) ? language : "en",
      if (Catalogs.activities.contains(activity)) "activity": activity,
      "cloudId": cloudId
    };
  }

  /// The master just made on this computer from the cloud (the server section): this device is
  /// its master, and [login]'s session there opens with [password], so the app runs `hybrid`.
  /// When the engine doesn't take it, the app stays online, the pairing kept.
  Future<bool> adopt(String login, String password) async {
    Deployment.attach(DeploymentRole.master);

    if (await join(login, password: password) == HybridJoin.joined) return true;

    Deployment.online();
    CapabilityService().modeChanged();
    return false;
  }

  /// "Not now" to [shouldAskLink]: the server section still offers it.
  void declineLink() => PreferencesService().declineLink();

  Future<LanStatus> _open() async {
    if (_lan.status == LanStatus.ready) return LanStatus.ready;

    try {
      return await _lan.open().timeout(wait);
    } on TimeoutException {
      return LanStatus.unreachable;
    }
  }

  Future<bool> _isSignedInAs(String login) async {
    try {
      final card = (await _lan.call(Ops.sessionBootstrap) as Map)["client"];
      if (card is! Map) return false;

      final wanted = login.trim().toLowerCase();

      return card["email"]?.toString().toLowerCase() == wanted || card["username"]?.toString().toLowerCase() == wanted;
    } on Object {
      return false;
    }
  }

  void _start() {
    _joined = true;
    _backendAnswers = false;
    Deployment.hybrid();
    CapabilityService().modeChanged();
    _watchNow();
    notifyListeners();
  }

  /// Whether a look at the backend is running or scheduled.
  bool _watching = false;

  /// Bumped by [_stopWatching]: a look that was on its way when watching stopped or restarted
  /// neither writes its answer nor schedules the next one.
  int _turn = 0;

  /// Looks now, and from there on at [every] or [retry] ([_look] schedules the next turn).
  void _watchNow() {
    _stopWatching();
    _watching = true;
    unawaited(_look());
  }

  /// One look at the backend for whichever session is watched: `hybrid` (the cloud-only areas
  /// lock and open with it) or one on the master alone ([canGoOnline]).
  Future<void> _look() async {
    final turn = _turn;
    final reachable = await _cloud();
    if (turn != _turn) return;

    if (_joined && Deployment.mode == DeploymentMode.hybrid) {
      final returned = reachable && !CapabilityService().internet;
      CapabilityService().internet = reachable;

      if (returned) unawaited(ConnectionService().open());
    } else if (masterOnly) {
      if (reachable != _backendAnswers) {
        _backendAnswers = reachable;
        notifyListeners();
      }
    } else {
      return _stopWatching();
    }

    _watch = Timer(reachable ? every : retry, () => unawaited(_look()));
  }

  /// The cloud's socket in `hybrid`: connected, the backend is there; dropped from connected,
  /// it is looked at now rather than at the next turn.
  void _socketChanged() {
    final was = _socketWas;
    final now = _socket.value;
    _socketWas = now;

    if (!_joined || Deployment.mode != DeploymentMode.hybrid) return;

    if (now == SocketStatus.connected) {
      CapabilityService().internet = true;
    } else if (was == SocketStatus.connected && (now == SocketStatus.reconnecting || now == SocketStatus.disconnected)) {
      _watchNow();
    }
  }

  /// The master's connection changed: a session on it alone starts looking at the backend, and
  /// stops when it ends (signed out, the master lost) or joins.
  void _follow() {
    if (_joined) return;

    if (!masterOnly) {
      _stopWatching();
      if (_backendAnswers) {
        _backendAnswers = false;
        notifyListeners();
      }
      return;
    }

    if (!_watching) _watchNow();
  }

  void _stopWatching() {
    _turn++;
    _watching = false;
    _watch?.cancel();
    _watch = null;
  }

  @override
  void dispose() {
    _lan.removeListener(_follow);
    _socket.removeListener(_socketChanged);
    _stopWatching();
    super.dispose();
  }
}
