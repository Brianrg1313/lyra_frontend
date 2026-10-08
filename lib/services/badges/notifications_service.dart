import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/badges/notification_model.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// **The feed behind the bell, and the moment something lands in it.**
///
/// The badges say how much work is standing; a notification says that something just happened:
/// a customer opened a conversation, a channel sale got its ticket, the assistant left a question
/// for the company (backend `lib/models/badges/MODULE.md`, "What rings the bell").
/// `notification/new` arrives over the company's socket room and is shown at once as a
/// [FloatFlag], wherever the person is in the app. The bell's number is a badge
/// (`notifications.unseen`) and moves through `BadgesService`, whose `badges/changed` arrives
/// beside it.
///
/// The room is the whole company, so each one is gated here by the section it is about
/// ([NotificationModel.area]); the backend leaves the same types out of the feed it answers.
///
/// [recent] is the feed's first page, read when the bell is opened ([load]), with what arrives
/// live while the app is open put on top. Cloud only, like the badges.
///
/// A singleton registered with `ChangeNotifierProvider.value`. `BadgesService` starts it.
class NotificationsService extends ChangeNotifier {
  //SINGLETON
  static final NotificationsService _singleton = NotificationsService._internal();

  factory NotificationsService() => _singleton;

  NotificationsService._internal();

  /// Server event (`Notifications.push`).
  static const newEvent = "notification/new";

  /// How many are kept: one page of the feed.
  static const _keep = 30;

  List<NotificationModel> _recent = const [];
  bool _listening = false;
  bool _loading = false;
  String? _watching;

  /// Bumped by every read and every company switch: an answer for a company left behind is
  /// dropped.
  int _reads = 0;

  List<NotificationModel> get recent => _recent;
  bool get isLoading => _loading;

  bool get _reachable => CapabilityService().cloudServices;

  /// Starts following `notification/new`, once per run.
  void listen() {
    if (_listening) return;
    _listening = true;

    ConnectionService().on(newEvent, _arrived);
    _watching = businessService.activeId;
    businessService.addListener(_businessChanged);
  }

  /// Reads the feed's first page for the active company.
  Future<void> load() async {
    if (businessService.activeId == null || !_reachable) return;

    final read = ++_reads;
    _loading = true;
    notifyListeners();

    try {
      final data = await api.get(path: "/notifications/", version: "v1", query: {"SIZE": "$_keep"});
      if (read != _reads) return;

      if (data is Map) {
        _recent = [
          for (final row in catalogRows(data["notifications"]))
            if (NotificationModel.fromJson(row) case final notification? when _visible(notification))
              notification
        ];
      }
    } catch (e) {
      if (kDebugMode) print("notifications: read failed: $e");
    } finally {
      if (read == _reads) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Everything kept is now older than the bell's cursor: the panel was opened.
  void markSeen() {
    if (_recent.every((notification) => notification.seen)) return;

    _recent = [for (final notification in _recent) notification.asSeen];
    notifyListeners();
  }

  /// Forgets the feed. For sign out and a company switch; the event handler stays, like
  /// `BadgesService`'s.
  void clear() {
    _reads++;
    _recent = const [];
    _loading = false;
    notifyListeners();
  }

  void _arrived(dynamic data) {
    if (data is! Map || !_reachable) return;

    final notification = NotificationModel.fromJson(data);
    if (notification == null || !_visible(notification)) return;
    if (_recent.any((kept) => kept.id == notification.id)) return;

    _recent = [notification, ..._recent.take(_keep - 1)];
    notifyListeners();

    // Before the first screen there is nothing to draw a flag on; the row is kept either way.
    try {
      FloatFlag.of().notification(title: notification.title, message: notification.body);
    } catch (e) {
      if (kDebugMode) print("notifications: not shown: $e");
    }
  }

  /// A notification about a section the person cannot open is not theirs to read.
  bool _visible(NotificationModel notification) {
    final area = notification.area;

    return area == null || PermissionsService().canOpen(area);
  }

  /// A company switch, creation or sign out: the feed of the one left describes nobody here.
  void _businessChanged() {
    final active = businessService.activeId;
    if (active == _watching) return;

    _watching = active;
    clear();
  }
}
