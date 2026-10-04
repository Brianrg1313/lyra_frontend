import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/business/sources/business_cloud_source.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/client/sources/session_cloud_source.dart';
import 'package:app/services/connection/cloud_presence.dart';
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
/// [CapabilityService.internet] holds, which follows the backend's [CloudPresence] (its
/// `/presence` socket) while a session lasts: connected, the areas open; dropped, they lock at
/// once. Nothing asks the backend on a timer. "Work offline" ([workOffline]) is the same session
/// without the cloud.
///
/// It also links the master's company to its cloud company ([link], `business.md` B-30), which
/// the cloud-only areas need to know which company they serve; a master company the account has
/// no company online for gets one made ([createOnline]).
///
/// A session opened on the master alone (signed in while the backend didn't answer) has no
/// cloud session to go back to, so nothing would ever bring it online: while it lasts the
/// presence is followed too, and [canGoOnline] says when an online sign in would join it.
///
/// App-wide (`initial_builder.dart`), like the [LanService] it works over.
class HybridService extends ChangeNotifier {
  HybridService({
    required LanService lan,
    required CloudPresence presence,
    this.wait = const Duration(seconds: 6)
  }) : _lan = lan, _presence = presence {
    _lan.addListener(_follow);
    _presence.live.addListener(_presenceChanged);
  }

  final LanService _lan;

  /// The backend's `/presence` socket, open while a session is followed.
  final CloudPresence _presence;

  /// How long the master gets to answer before the app goes on with the cloud alone.
  final Duration wait;

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

    _unwatch();
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
    _unwatch();
    _joined = false;
    _backendAnswers = false;
    _offeredOnline = false;
    _linkAsked = false;
    if (Deployment.mode == DeploymentMode.hybrid) Deployment.online();
    CapabilityService().internet = true;
    notifyListeners();
  }

  bool _linkAsked = false;

  /// Whether to ask, once a session, to join the master's company with its cloud company: the
  /// master's owner, online, the company not linked and no "not now" given.
  bool get shouldAskLink {
    if (_linkAsked || Deployment.mode != DeploymentMode.hybrid || !CapabilityService().internet) return false;

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

  /// [shouldAskLink] was acted on: not again this session, whatever came of it.
  void askedLink() => _linkAsked = true;

  /// The master's company made online and joined with it (`business.md` B-30), when this account
  /// manages no company online to join it to ([linkCandidates] empty): going online asks nothing.
  /// The account creating it owns it, which is what B-32 asks of a link.
  Future<BusinessModel> createOnline() async {
    final profile = await Sources.business.profile();
    final id = await const BusinessCloudSource().create(cloudCompanyFrom(profile));
    final cloud = BusinessModel(id: id, name: profile.name.trim());

    await link(cloud);
    return cloud;
  }

  /// `business/create`'s body from the master's profile: the reverse of [companyFrom]. The
  /// activity is required online, so a master without one says "other"; the currency has no
  /// place there.
  static Map<String, Object?> cloudCompanyFrom(BusinessProfileModel profile) {
    final name = profile.name.trim();
    final legalName = profile.legalName.trim();
    final country = profile.country.trim().toUpperCase();
    final language = profile.language.trim().toLowerCase();

    return {
      "LEGAL_NAME": legalName.length >= 2 ? legalName : name,
      "NAME": name.length > 64 ? name.substring(0, 64) : name,
      "ACTIVITY_TYPE": profile.activity == BusinessActivity.unknown ? BusinessActivity.other.value : profile.activity.value,
      if (country.length == 2) "COUNTRY": country,
      if (language.isNotEmpty) "LANGUAGE": language
    };
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
    _watch();
    notifyListeners();
  }

  /// Whether a session follows the presence.
  bool _watching = false;

  void _watch() {
    _watching = true;
    _presence.start();
    _apply();
  }

  /// Before [CloudPresence.stop], whose `live` going null then finds nothing watched.
  void _unwatch() {
    _watching = false;
    _presence.stop();
  }

  void _presenceChanged() {
    if (_watching) _apply();
  }

  /// What the presence says, for whichever session is followed: `hybrid` (the cloud-only areas
  /// lock and open with it) or one on the master alone ([canGoOnline]). No answer yet changes
  /// nothing.
  void _apply() {
    final live = _presence.live.value;
    if (live == null) return;

    if (_joined && Deployment.mode == DeploymentMode.hybrid) {
      final returned = live && !CapabilityService().internet;
      CapabilityService().internet = live;

      if (returned) unawaited(ConnectionService().open());
    } else if (masterOnly) {
      if (live != _backendAnswers) {
        _backendAnswers = live;
        notifyListeners();
      }
    } else {
      _unwatch();
    }
  }

  /// The master's connection changed: a session on it alone starts following the presence, and
  /// stops when it ends (signed out, the master lost) or joins.
  void _follow() {
    if (_joined) return;

    if (!masterOnly) {
      if (_watching) _unwatch();
      if (_backendAnswers) {
        _backendAnswers = false;
        notifyListeners();
      }
      return;
    }

    if (!_watching) _watch();
  }

  @override
  void dispose() {
    _lan.removeListener(_follow);
    _presence.live.removeListener(_presenceChanged);
    _unwatch();
    super.dispose();
  }
}
