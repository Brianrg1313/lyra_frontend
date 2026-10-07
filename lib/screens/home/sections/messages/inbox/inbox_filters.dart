import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chats_service.dart';

import './inbox_filter_chip.dart';

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
          child: InboxFilterChip(
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
