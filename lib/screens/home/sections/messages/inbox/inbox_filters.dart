import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chats_service.dart';

/// The inbox tabs as chips, each with its counter from the summary. They
/// scroll instead of shrinking: the panel is a third of the page.
class InboxFilters extends StatelessWidget {
  const InboxFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ChatsService>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      child: Row(children: [
        for (final filter in ChatsFilter.values) Padding(
          padding: EdgeInsets.only(right: AppSize.gap),
          child: _Chip(
            label: inboxFilterTitle(context, filter),
            count: filter.countIn(service.summary),
            active: filter == service.filter,
            alert: filter == ChatsFilter.attention,
            action: () => service.applyFilter(filter)
          )
        )
      ])
    );
  }
}

String inboxFilterTitle(BuildContext context, ChatsFilter filter) => switch (filter) {
  ChatsFilter.all => S.of(context).messages_filter_all,
  ChatsFilter.unanswered => S.of(context).messages_filter_unanswered,
  ChatsFilter.attention => S.of(context).messages_filter_attention,
  ChatsFilter.mine => S.of(context).messages_filter_mine,
  ChatsFilter.paused => S.of(context).messages_filter_paused
};

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.alert,
    required this.action
  });

  final String label;
  final int? count;
  final bool active;

  /// The counter is drawn as a warning while above zero.
  final bool alert;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final shown = count != null && count! > 0;
    final badge = alert ? scheme.chart.serious : scheme.primary;

    return FeedbackButton(
      action: action,
      message: label,
      height: AppSize.button * 0.9,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.corner,
      color: active ? scheme.primary.withValues(alpha: 0.14) : scheme.surfaceOver,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(
            label,
            multiplier: 0.9,
            bold: active,
            color: active ? scheme.primary : scheme.text.secondary
          ),
          if (shown) ...[
            SizedBox(width: AppSize.gap),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSize.gap, vertical: 1),
              decoration: BoxDecoration(
                color: badge,
                borderRadius: BorderRadius.circular(AppSize.corner)
              ),
              child: TextSmall("$count", multiplier: 0.85, color: scheme.surface)
            )
          ]
        ]
      )
    );
  }
}
