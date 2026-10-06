import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// Where the badges are read and acknowledged. The cloud's by default; tests swap it
/// ([BadgesService.transport]) so nothing reaches the network.
abstract interface class BadgesTransport {
  /// `GET /lyra/v1/badges`: the whole state for the company in the `business_id` header.
  Future<dynamic> read();

  /// `POST /lyra/v1/badges/seen`: acknowledges [keys] and answers the state that results.
  Future<dynamic> seen(List<String> keys);
}

class _CloudBadges implements BadgesTransport {
  const _CloudBadges();

  @override
  Future<dynamic> read() => api.get(path: "/badges/", version: "v1");

  @override
  Future<dynamic> seen(List<String> keys) => api.post(path: "/badges/seen/", version: "v1", data: {"KEYS": keys});
}

/// **Every dot, number and marker the app draws**, for the person signed in and the active
/// company (`model:/badges/badges.js`): chats waiting, holds open, tickets left on a till, money
/// owed, setup left to do, terms to accept, a section that is new.
///
/// Nothing here is counted by the app. The backend measures every badge from the collection that
/// owns it and says where each one shows (its anchors); this keeps the last answer and screens
/// read it by place ([at], [BadgePlace]), so the side bar and the page it opens can never
/// disagree about a number.
///
/// ## Staying current
///
/// - `/init` brings the first state when its `business_id` header named a company
///   ([ClientService] seeds it); otherwise, and on every company switch, it is read here.
/// - `badges/changed` names the keys that went stale, **never** their values (half are gated on a
///   permission and the room is the whole company), and `badges/reset` asks for everything again:
///   both are answered by reading this person's own state. A burst of them is one read.
/// - A connection that comes back reads too: what was emitted while it was down is gone.
///
/// Reads go over REST and not the socket's `badges/get`: after a switch the socket is still in
/// the previous company's room until its new handshake, and would answer for that one, while the
/// header already names the new one.
///
/// Cloud only: a master does not measure badges, so outside the cloud's reach the state is empty
/// (no dots) rather than an error. A read that fails keeps what was drawn — a source that could
/// not be read is not a zero.
///
/// A singleton registered with `ChangeNotifierProvider.value`, like [PermissionsService].
///
/// ```dart
/// final pending = context.watch<BadgesService>().at(BadgePlace.finance);
/// if (pending.isNotEmpty) …
/// ```
class BadgesService extends ChangeNotifier {
  //SINGLETON
  static final BadgesService _singleton = BadgesService._internal();

  factory BadgesService() => _singleton;

  BadgesService._internal();

  /// Server events (`lib/sockets/MODULE.md` in the backend).
  static const changedEvent = "badges/changed";
  static const resetEvent = "badges/reset";

  /// How long a burst of stale notices is gathered into one read. A sale touches the tickets,
  /// the receivables and the stock in the same second.
  static const _gather = Duration(milliseconds: 300);

  @visibleForTesting
  BadgesTransport transport = const _CloudBadges();

  BadgeState _state = BadgeState.empty;

  /// Company last seen active, to tell a switch from the rest of [BusinessService]'s notices.
  String? _watching;

  /// Bumped on every read and every reset: an answer whose number is no longer the last one
  /// describes a moment that has passed.
  int _reads = 0;

  bool _listening = false;
  Timer? _pending;

  BadgeState get state => _state;

  /// What [place] draws: its anchors read as one, each badge counted once.
  BadgeAnchor at(BadgePlace place) => _state.union(place.anchors);

  /// Every badge standing, in the backend's order.
  List<BadgeModel> get badges => _state.badges;

  static String? get _activeKey => businessService.activeId == null ? null : businessService.active.cloudKey;

  /// A master measures no badges; in hybrid they are the cloud's while it answers for the company.
  bool get _reachable => CapabilityService().cloudServices;

  /// Takes `/init`'s `badges`, measured for [business] (the `business_id` the request carried).
  /// When they describe another company than the active one, or did not come (no header, an
  /// older backend), they are read instead. Starts following the changes, once per run.
  void seed(dynamic data, {required String? business}) {
    _listen();
    _watching = _activeKey;

    if (data is Map && business != null && business == _activeKey) {
      _reads++;
      _apply(BadgeState.fromJson(data));
      return;
    }

    unawaited(refresh());
  }

  /// Reads this person's state for the active company now.
  Future<void> refresh() async {
    _pending?.cancel();

    final business = _activeKey;
    final read = ++_reads;

    if (business == null || !_reachable) {
      _apply(BadgeState.empty);
      return;
    }

    try {
      final data = await transport.read();
      if (read != _reads || business != _activeKey) return;

      if (data is Map) _apply(BadgeState.fromJson(data));
    } catch (e) {
      if (kDebugMode) print("badges: read failed: $e");
    }
  }

  /// "Seen": the bell opened, a new section found. Only the dismissible badges standing are
  /// sent — the rest are cleared by doing the work, and the backend refuses a request with none.
  /// They leave at once; the answer then replaces the whole state. Never throws: a dot that comes
  /// back is the worst outcome.
  Future<void> seen(Iterable<String> keys) async {
    final business = _activeKey;
    final asked = [
      for (final key in keys.toSet())
        if (_state.byKey(key)?.dismissible == true) key
    ];

    if (asked.isEmpty || business == null || !_reachable) return;

    final read = ++_reads;
    _apply(_state.without(asked));

    try {
      final data = await transport.seen(asked);
      if (read != _reads || business != _activeKey) return;

      if (data is Map) _apply(BadgeState.fromJson(data));
    } catch (e) {
      if (kDebugMode) print("badges: seen failed: $e");
      if (read == _reads) unawaited(refresh());
    }
  }

  /// [place] was opened: the `news` badges it shows are acknowledged — finding the section is
  /// the whole point of them.
  void discover(BadgePlace place) {
    final news = [
      for (final key in at(place).badges)
        if (_state.byKey(key)?.kind == BadgeKind.news) key
    ];

    if (news.isNotEmpty) unawaited(seen(news));
  }

  /// Forgets the state. For sign out: the next session brings its own. The event handlers stay,
  /// as [ConnectionService]'s do, so the next session is followed without registering again.
  void clear() {
    _pending?.cancel();
    _reads++;
    _watching = null;
    _state = BadgeState.empty;

    notifyListeners();
  }

  void _apply(BadgeState state) {
    _state = state;

    notifyListeners();
  }

  void _listen() {
    if (_listening) return;
    _listening = true;

    final connection = ConnectionService();
    connection.on(changedEvent, (_) => _stale());
    connection.on(resetEvent, (_) => _stale());
    connection.onRestored(_stale);
    businessService.addListener(_businessChanged);
  }

  /// A company switch, creation or sign out: the dots of the one left describe nobody here, so
  /// they go at once, before the new company's arrive.
  void _businessChanged() {
    final key = _activeKey;
    if (key == _watching) return;

    _watching = key;
    _reads++;
    _apply(BadgeState.empty);
    _stale();
  }

  void _stale() {
    _pending?.cancel();
    _pending = Timer(_gather, () => unawaited(refresh()));
  }
}

extension on BadgeState {
  /// The state with [keys] gone, rolled up again the way the backend does it.
  BadgeState without(List<String> keys) {
    final kept = [for (final badge in badges) if (!keys.contains(badge.key)) badge];
    final anchors = <String, BadgeAnchor>{};

    for (final badge in kept) {
      for (final name in badge.anchors) {
        final slot = anchors[name] ?? BadgeAnchor.empty;

        anchors[name] = BadgeAnchor(
          count: slot.count + badge.count,
          level: slot.level.max(badge.level),
          badges: [...slot.badges, badge.key]
        );
      }
    }

    return BadgeState(
      badges: kept,
      anchors: anchors,
      total: kept.fold(0, (sum, badge) => sum + badge.count),
      level: kept.fold(BadgeLevel.none, (level, badge) => level.max(badge.level)),
      date: date
    );
  }
}
