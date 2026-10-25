import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:core/kit/controller.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/database/database_service.dart';
import 'package:app/toolkit/backend/api.dart';

import 'baileys_client.dart';
import 'baileys_event.dart';
import 'baileys_launcher.dart';
import 'baileys_session_status.dart';

/// Local key under which the control API's shared secret is kept
/// (`DatabaseService.fromSecure` / `toSecure`, backed by the OS credential
/// store — Windows Credential Locker underneath `flutter_secure_storage`).
///
/// This app is the only thing that ever launches `baileys_server`
/// ([BaileysLauncher]), so it owns this secret end to end: it generates it
/// once, keeps it here, and passes it to the process as `CONTROL_API_KEY`
/// every time it spawns it. A restart of the app reuses the same key from
/// storage, so it can keep talking to a server instance a previous run of
/// the app already started and left running in the background — the whole
/// reason the sidecar survives the app closing.
const _apiKeyStorageKey = "baileys_control_api_key";

/// One business's link to `baileys_server`: which of its channels have a
/// WhatsApp Personal session, and what each one's live state is (starting,
/// waiting on a QR scan, connected, ...).
///
/// This is the piece `baileys_server/MODULE.md` called "not yet built" —
/// the app-side half of the sidecar. It owns exactly two things: getting the
/// server running when a channel is switched on, and keeping this app's view
/// of each session's status current. It knows nothing about the channel's
/// backend record (`ChannelsService` owns that) or about pairing UI (the
/// widgets decide what to show for a given status; this service only reports
/// it).
///
/// Registered app-wide ([initialBuilder]) like the other catalogs, but it
/// does nothing until a WhatsApp Personal channel actually asks for it: the
/// server is only ever launched from [activate], never eagerly, so a
/// business that does not use this feature never spawns a Node process it
/// does not need.
class BaileysService extends ChangeNotifier {
  static const _host = "127.0.0.1";
  static const _port = 4001;

  final _launcher = const BaileysLauncher(host: _host, port: _port);
  BaileysClient? _client;

  /// The one session every channel maps to in a debug build run with
  /// `--dart-define=BAILEYS_DEV_SESSION=<id>`, instead of the channel's own id.
  ///
  /// A session's auth folder is named after its id, and a channel's id dies
  /// with the database: a developer wiping it twice a day was scanning a new
  /// QR each time. Under a fixed id the folder outlives every wipe, and the
  /// backend creates the new company's channel when the number announces
  /// itself (`whatsapp_personal/session`, which in `DEV` also takes the
  /// number from whichever company had it). See [follow].
  static const _devSession =
    kDebugMode ? String.fromEnvironment("BAILEYS_DEV_SESSION") : "";

  final Map<String, BaileysSessionStatus> _statuses = {};

  StreamSubscription<BaileysEvent>? _events;
  bool _watchingEvents = false;

  BusinessService? _business;
  Listenable? _following;
  String? _followed;

  String _session(String channelId) =>
    _devSession.isEmpty ? channelId : _devSession;

  /// With a [_devSession], links the number to every company the session
  /// activates — at boot, on a switch, on a new one — with nobody opening the
  /// channels section: pushing the session to the sidecar re-announces the
  /// number, and the backend gives it to that company. A no-op otherwise.
  ///
  /// [session] too, because a sign in seeds the businesses without them
  /// notifying (`BusinessService.seed`); the session's own update does.
  void follow(BusinessService business, Listenable session) {
    if (_devSession.isEmpty) return;

    _business = business;
    _following = Listenable.merge([business, session])..addListener(_onBusiness);
    _onBusiness();
  }

  void _onBusiness() {
    final id = _business?.activeId;
    if (id == null || id == _followed) return;
    _followed = id;

    activate(_devSession).then(
      (status) => debugPrint("[baileys] $_devSession follows $id: ${status.state.name}"),
      onError: (error) => debugPrint("[baileys] $_devSession could not follow $id: $error")
    );
  }

  /// The status last read for [channelId] — a channel's own id doubles as
  /// its session id, since a channel already **is** one WhatsApp number.
  /// [BaileysSessionStatus.unknown] before anything has been read, which
  /// reads as "off" everywhere a switch consumes it.
  BaileysSessionStatus statusOf(String channelId) =>
    _statuses[_session(channelId)] ?? BaileysSessionStatus.unknown;

  /// Best-effort refresh for a batch of channel ids, called once the channel
  /// grid loads so switches show the right state without anyone having
  /// touched them yet.
  ///
  /// Silent on every failure: the server not running is the normal state for
  /// a business that has not turned a WhatsApp Personal channel on this
  /// session, not something to surface as an error, and this never launches
  /// the server on its own — see the class note.
  Future<void> refresh(Iterable<String> channelIds) async {
    final ids = channelIds.map(_session).toSet();
    if (ids.isEmpty) return;

    try {
      final client = await _ensureClient();
      if (await client.health() == null) return;

      await _identify(client);
      _watchEvents();

      final sessions = await client.listSessions();
      for (final status in sessions) {
        if (ids.contains(status.id)) _statuses[status.id] = status;
      }

      notifyListeners();
    } catch (_) {
      // Left as unknown: a switch that cannot confirm the server's state
      // reads as off, which is the safe default.
    }
  }

  /// Turns a WhatsApp Personal channel on: makes sure `baileys_server` is
  /// running (launching it if needed) and starts (or resumes) its session.
  ///
  /// Returns the resulting status so the caller can decide what to show —
  /// typically opening the QR pairing modal when it comes back
  /// `qr_pending`. Throws [BaileysClientException] on failure, exactly like
  /// the rest of this app's services report a failed write, so the widget
  /// shows it the same way (`FloatFlag.of(context).fromError`).
  Future<BaileysSessionStatus> activate(String channelId) async {
    final client = await _ensureClient();

    if (!await _launcher.ensureRunning(client)) {
      throw BaileysClientException(
        "baileys_server did not start (is Node installed and on PATH?)"
      );
    }

    // Before the session, not after: a number that reaches `connected` with no
    // credentials on the sidecar is one that holds WhatsApp and relays nothing,
    // and the QR scan that got it there is the moment nobody wants to repeat.
    await _identify(client);

    final status = await client.ensureStarted(_session(channelId));
    _statuses[_session(channelId)] = status;
    notifyListeners();

    _watchEvents();

    return status;
  }

  /// Tells the sidecar which backend session to act as.
  ///
  /// The sidecar reaches the backend on this app's credentials and has none of
  /// its own — the backend issues it nothing, precisely because there is no
  /// third party here: the relay runs on the company's own machine, on the
  /// company's own session (see `baileys_server/src/backend/credentials.js`).
  /// So everything it needs comes from the same three places the app's own
  /// requests read: the token registry, the device, and the active business.
  ///
  /// Pushed on every activation and every refresh rather than once. It is
  /// cheap, and the alternative is tracking every way a session can change —
  /// a sign-in, a business switch, a renewed token — from a service that has
  /// no reason to know about any of them.
  ///
  /// Failures are swallowed: the caller is switching a channel on, and the
  /// error it needs to hear about is that one, not this. A sidecar left with a
  /// stale session says so on its own, in `/health`.
  Future<void> _identify(BaileysClient client) async {
    final token = api.token;
    final business = api.business;
    final device = AppController().deviceID;

    if (token == null || token.isEmpty || business == null || business.isEmpty) {
      // No session, or no business chosen yet. Nothing usable to hand over —
      // and clearing is the honest answer, since whatever the sidecar is
      // holding is from a session this app no longer has.
      try {
        await client.clearBackend();
      } catch (_) {
        // Same reasoning as below.
      }
      return;
    }

    try {
      await client.setBackend(
        url: apiOrigin,
        token: token,
        device: device,
        business: business,
        language: AppController().language
      );
    } catch (error) {
      if (kDebugMode) debugPrint("[baileys] could not push credentials: $error");
    }
  }

  /// Turns a WhatsApp Personal channel off: a soft stop, keeping its auth so
  /// switching back on later resumes without a new QR (`baileys_server`'s
  /// `stop`, not `logout`) — matching "turning it off cancels it" and not
  /// "disconnects the number for good".
  Future<BaileysSessionStatus> deactivate(String channelId) async {
    final client = await _ensureClient();
    final status = await client.stop(_session(channelId));

    _statuses[_session(channelId)] = status;
    notifyListeners();

    return status;
  }

  /// Unlinks the number for good: a hard stop that tells WhatsApp to drop
  /// this device and wipes the session's auth (`baileys_server`'s `logout`,
  /// not `stop`), so turning the channel back on asks for a new QR.
  ///
  /// It is the opposite half of [deactivate] and the difference is the whole
  /// point of having both: turning a channel off is reversible with the same
  /// switch, unlinking is not. That is why nothing here asks — whoever calls
  /// it confirmed first.
  ///
  /// The channel itself is untouched: it keeps its role, its data source and
  /// its place in the list, and can be linked again to the same number or to
  /// another one. Deleting the channel is a different action.
  ///
  /// The sidecar has to be up for this, and is started if it is not: what
  /// makes a number stay linked is an auth folder on this machine, and a
  /// server that is not running is a server that cannot delete it. An unlink
  /// that quietly did nothing would be the worst of the three outcomes.
  Future<BaileysSessionStatus> unlink(String channelId) async {
    final client = await _ensureClient();

    if (!await _launcher.ensureRunning(client)) {
      throw BaileysClientException(
        "baileys_server did not start (is Node installed and on PATH?)"
      );
    }

    BaileysSessionStatus status;

    try {
      status = await client.logout(_session(channelId));
    } on BaileysClientException catch (error) {
      if (!error.message.contains("404")) rethrow;

      // The server holds no session under this id — it was restarted since,
      // or this number was never switched on in this run. The auth folder is
      // still on disk though, and that folder **is** the link: left there it
      // would bring the number back on the next activation. `remove` wipes it
      // whether or not a session is loaded, at the price of not telling
      // WhatsApp to drop the device — there is no socket left to tell it
      // through, and the phone's own linked-devices list is where that is
      // undone in that case.
      await client.remove(_session(channelId));

      status = const BaileysSessionStatus(
        id: "",
        state: BaileysSessionState.loggedOut
      );
    }

    _statuses[_session(channelId)] = status;
    notifyListeners();

    return status;
  }

  /// Polls one session until [stop] says to (typically "connected, or the
  /// caller gave up"), updating [statusOf] as it goes. Used by the pairing
  /// modal to watch a QR through to a scan without the rest of the app
  /// polling anything.
  Stream<BaileysSessionStatus> watch(
    String channelId, {
    required bool Function(BaileysSessionStatus status) until,
    Duration interval = const Duration(seconds: 2)
  }) async* {
    final client = await _ensureClient();

    while (true) {
      await Future.delayed(interval);

      BaileysSessionStatus? status;
      try {
        status = await client.getStatus(_session(channelId));
      } catch (_) {
        // A single failed poll (a blip on localhost) is not worth ending the
        // watch over — the next tick tries again.
        continue;
      }
      if (status == null) continue;

      _statuses[_session(channelId)] = status;
      notifyListeners();

      yield status;

      if (until(status)) return;
    }
  }

  /// Subscribes to the sidecar's live event feed and keeps it subscribed.
  ///
  /// Two things come out of it. Status changes stop depending on someone
  /// polling — a session that drops or finishes pairing updates [statusOf] on
  /// its own. And every inbound WhatsApp message prints in this app's console,
  /// which is the only place a developer running `flutter run` is actually
  /// looking: the server's own log is a detached process's file nobody has in
  /// front of them (`baileys_server/data/server.log`).
  ///
  /// Called after the server is known to be reachable, never before — this
  /// must not be what starts it.
  void _watchEvents() {
    if (_watchingEvents) return;
    _watchingEvents = true;
    _openEvents();
  }

  void _openEvents() {
    final client = _client;
    if (!_watchingEvents || client == null) return;

    _events = client.events().listen(
      _onEvent,
      onError: (_) => _reopenEvents(),
      onDone: _reopenEvents,
      cancelOnError: true
    );
  }

  /// The feed dying is normal — the sidecar restarting, or it not being up
  /// yet — so it is retried rather than given up on. A flat delay is enough:
  /// this is a localhost socket, and nothing in the app is blocked while it
  /// is down.
  void _reopenEvents() {
    _events?.cancel();
    _events = null;

    if (!_watchingEvents) return;
    Future.delayed(const Duration(seconds: 3), _openEvents);
  }

  void _onEvent(BaileysEvent event) {
    switch (event.type) {
      case BaileysEventType.messageReceived:
        final message = event.message;
        if (message != null && kDebugMode) {
          debugPrint("[baileys] ${message.summary}");
        }

      case BaileysEventType.sessionStatus:
        final status = event.status;
        if (status == null || status.id.isEmpty) return;

        _statuses[status.id] = status;
        notifyListeners();

        if (kDebugMode) {
          debugPrint("[baileys] ${status.id} is ${status.state.name}");
        }

      case BaileysEventType.other:
        break;
    }
  }

  /// Forgets this session's view of the sidecar and takes its credentials
  /// back.
  ///
  /// The WhatsApp sessions themselves are left running: they belong to the
  /// company's number, not to whoever signed in, and stopping them would mean
  /// a new QR the next time. What must not survive is the relay acting on a
  /// token the backend just closed, so the sidecar is told to forget it — the
  /// next sign in hands a fresh one over on its first [refresh]/[activate].
  ///
  /// Only when a client was ever built: a session that never touched a
  /// WhatsApp Personal channel has nothing on the sidecar to take back, and
  /// building one here would read secure storage for nothing.
  Future<void> signOut() async {
    _watchingEvents = false;
    _events?.cancel();
    _events = null;

    _statuses.clear();
    // The next sign in may come back to the same company, and it has to be
    // announced again on that session.
    _followed = null;
    notifyListeners();

    final client = _client;
    if (client == null) return;

    try {
      await client.clearBackend();
    } catch (_) {
      // The server not running is the usual case, and then it holds nothing.
    }
  }

  @override
  void dispose() {
    _following?.removeListener(_onBusiness);
    _watchingEvents = false;
    _events?.cancel();
    _events = null;
    super.dispose();
  }

  Future<BaileysClient> _ensureClient() async {
    final existing = _client;
    if (existing != null) return existing;

    var apiKey = await DatabaseService().fromSecure<String>(_apiKeyStorageKey);

    if (apiKey == null || apiKey.isEmpty) {
      apiKey = _generateKey();
      await DatabaseService().toSecure(_apiKeyStorageKey, apiKey);
    }

    final client = BaileysClient(host: _host, port: _port, apiKey: apiKey);
    _client = client;

    return client;
  }

  /// 256 bits from a cryptographically secure source, hex-encoded — plenty
  /// for a key that only ever has to resist another local process guessing
  /// it, not a network attacker.
  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
  }
}
