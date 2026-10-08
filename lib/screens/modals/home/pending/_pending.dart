import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/badges/notification_model.dart';
import 'package:app/services/badges/notifications_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

import 'package:app/screens/home/badges/badge_title.dart';
import 'package:app/screens/home/sections/messages/chat_format.dart';

/// Opens the list of everything pending in the active company, and the notifications under it,
/// and answers what the person chose to open (a [BadgeModel] or a [NotificationModel]) or
/// `null`. [opens] and [leads] say which ones lead somewhere: the caller navigates.
Future<Object?> showPendingPanel(
  BuildContext context, {
  required bool Function(BadgeModel badge) opens,
  required bool Function(NotificationModel notification) leads
}) async {
  final width = math.min(AppSize.action * 10, MediaQuery.of(context).size.width * .45);

  final chosen = await showSideModal(
    context: context,
    title: S.of(context).badges_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => PendingModal(opens: opens, leads: leads)
  );

  return chosen is BadgeModel || chosen is NotificationModel ? chosen : null;
}

/// Every badge standing, loudest first, one row each, then the latest notifications. It watches
/// [BadgesService] and [NotificationsService], so a chat attended elsewhere, a dot dismissed here
/// or a notification that just arrived changes the list while it is open.
///
/// Opening it is opening the bell: the feed is read and then acknowledged, so the bell's number
/// goes to zero while the rows that were new still say so until the panel closes.
class PendingModal extends StatefulWidget {
  const PendingModal({super.key, required this.opens, required this.leads});

  final bool Function(BadgeModel badge) opens;
  final bool Function(NotificationModel notification) leads;

  @override
  State<PendingModal> createState() => _PendingModalState();
}

class _PendingModalState extends State<PendingModal> {
  final _notifications = NotificationsService();

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void dispose() {
    _notifications.markSeen();
    super.dispose();
  }

  /// The feed first and the acknowledgement after: acknowledged first, the read would answer
  /// every row as already seen.
  Future<void> _open() async {
    await _notifications.load();
    await BadgesService().seen(const ["notifications.unseen"]);
  }

  @override
  Widget build(BuildContext context) {
    final badges = [
      for (final badge in context.watch<BadgesService>().badges)
        // The bell's own count is the list below, not a row of its own.
        if (badge.key != "notifications.unseen") badge
    ]..sort((a, b) => b.level.index.compareTo(a.level.index));

    final feed = context.watch<NotificationsService>();
    final notifications = feed.recent;

    if (badges.isEmpty && notifications.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: feed.isLoading
          ? const Center(child: Loading())
          : SectionMessage(icon: CI.notification, title: S.of(context).badges_empty)
      );
    }

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      children: [
        for (final badge in badges) _PendingRow(
          badge: badge,
          action: widget.opens(badge) ? () => Navigator.pop(context, badge) : null
        ),
        if (notifications.isNotEmpty) Padding(
          padding: EdgeInsets.only(
            top: badges.isEmpty ? 0 : AppSize.spaceS,
            bottom: AppSize.gap,
            left: AppSize.gap
          ),
          child: TextSmall(S.of(context).notifications_recent)
        ),
        for (final notification in notifications) _NotificationRow(
          notification: notification,
          action: widget.leads(notification) ? () => Navigator.pop(context, notification) : null
        )
      ]
    );
  }
}

/// One notification: a dot in its level's colour (hollow once seen), what happened, the line
/// under it and when.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.action});

  final NotificationModel notification;
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = badgeColor(context, notification.level);
    final body = notification.body;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: FeedbackButton(
        action: action,
        mouseCursor: action == null ? SystemMouseCursors.basic : null,
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.all(AppSize.spaceS),
        color: scheme.surfaceOver,
        feedbackColor: action == null ? Colors.transparent : scheme.surfaceFeedback,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * .4),
            child: Container(
              width: AppSize.gap * 1.6,
              height: AppSize.gap * 1.6,
              decoration: BoxDecoration(
                color: notification.seen ? Colors.transparent : color,
                border: Border.all(color: color, width: 1.5),
                shape: BoxShape.circle
              )
            )
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextMedium(notification.title, bold: !notification.seen),
            if (body != null) TextSmall(body, lines: 2, ellipsis: true)
          ])),
          Padding(
            padding: EdgeInsets.only(left: AppSize.gap),
            child: TextSmall(chatTimeLabel(context, notification.date))
          )
        ])
      )
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.badge, required this.action});

  final BadgeModel badge;
  final void Function()? action;

  /// The terms are dismissible on the backend, but accepting them is not a dot to clear: it
  /// needs the terms in front of the person, and the app has no page for them yet.
  bool get _canDismiss => badge.dismissible && badge.key != "legal.terms";

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: FeedbackButton(
        action: action,
        mouseCursor: action == null ? SystemMouseCursors.basic : null,
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.all(AppSize.spaceS),
        color: scheme.surfaceOver,
        feedbackColor: action == null ? Colors.transparent : scheme.surfaceFeedback,
        child: Row(children: [
          Container(
            width: AppSize.gap * 1.6,
            height: AppSize.gap * 1.6,
            decoration: BoxDecoration(color: badgeColor(context, badge.level), shape: BoxShape.circle)
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextMedium(badgeTitle(context, badge))),
          if (badge.kind == BadgeKind.count) Padding(
            padding: EdgeInsets.only(left: AppSize.gap),
            child: TextMedium("${badge.count}", bold: true)
          ),
          if (_canDismiss) Padding(
            padding: EdgeInsets.only(left: AppSize.spaceS),
            child: Button(
              title: badge.kind == BadgeKind.count
                ? S.of(context).badges_mark_read
                : S.of(context).badges_dismiss,
              width: null,
              action: () => BadgesService().seen([badge.key])
            )
          )
        ])
      )
    );
  }
}
