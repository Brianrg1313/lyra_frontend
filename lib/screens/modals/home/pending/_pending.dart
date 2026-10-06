import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/badges/badges_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/section_message.dart';

import './pending_title.dart';

/// Opens the list of everything pending in the active company and answers the badge the person
/// chose to open, or `null`. [opens] says which ones lead somewhere: the caller navigates.
Future<BadgeModel?> showPendingPanel(
  BuildContext context, {
  required bool Function(BadgeModel badge) opens
}) async {
  final width = math.min(AppSize.action * 10, MediaQuery.of(context).size.width * .45);

  final chosen = await showSideModal(
    context: context,
    title: S.of(context).badges_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => PendingModal(opens: opens)
  );

  return chosen is BadgeModel ? chosen : null;
}

/// Every badge standing, loudest first, one row each. It watches [BadgesService], so a chat
/// attended elsewhere or a dot dismissed here leaves the list while it is open.
class PendingModal extends StatelessWidget {
  const PendingModal({super.key, required this.opens});

  final bool Function(BadgeModel badge) opens;

  @override
  Widget build(BuildContext context) {
    final badges = [...context.watch<BadgesService>().badges]
      ..sort((a, b) => b.level.index.compareTo(a.level.index));

    if (badges.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: SectionMessage(icon: CI.notification, title: S.of(context).badges_empty)
      );
    }

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      children: [
        for (final badge in badges) _PendingRow(
          badge: badge,
          action: opens(badge) ? () => Navigator.pop(context, badge) : null
        )
      ]
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
          Expanded(child: TextMedium(pendingTitle(context, badge))),
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
