import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chats_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './inbox_filters.dart';
import './inbox_list.dart';

/// The left panel: title and count, the tab chips, and the conversation list.
///
/// The list pages on its own when scrolled near the end. Rows are drawn from
/// [ChatsService] and move to the top as messages arrive.
class InboxPanel extends StatelessWidget {
  const InboxPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ChatsService>();
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSize.spaceM, AppSize.spaceM, AppSize.spaceM, AppSize.spaceXS),
          child: Row(children: [
            Expanded(child: TextLarge(S.of(context).messages, ellipsis: true)),
            if (service.status == ChatsStatus.ready)
              TextSmall(
                S.of(context).messages_count(service.total),
                color: scheme.text.secondary
              )
          ])
        ),
        const InboxFilters(),
        if (service.pending > 0) _Pending(count: service.pending, action: service.refresh),
        SizedBox(height: AppSize.gap),
        Separator.horizontal(),
        Expanded(child: _body(context, service))
      ]
    );
  }

  Widget _body(BuildContext context, ChatsService service) => switch (service.status) {
    ChatsStatus.error => SectionMessage(
      icon: CI.info,
      title: S.of(context).messages_error_title,
      subtitle: S.of(context).messages_error_subtitle,
      action: service.retry,
      actionLabel: S.of(context).messages_retry
    ),
    ChatsStatus.empty => service.filter == ChatsFilter.all && service.search.isEmpty
      ? SectionMessage(
          icon: CI.chat,
          title: S.of(context).messages_empty_title,
          subtitle: S.of(context).messages_empty_subtitle
        )
      : SectionMessage(
          icon: CI.search,
          title: S.of(context).messages_empty_filter_title,
          subtitle: S.of(context).messages_empty_filter_subtitle
        ),
    ChatsStatus.ready => InboxList(service: service),
    _ => const Center(child: Loading())
  };
}

/// Movements the list could not pick up on its own (the user is scrolled past
/// page one, or a silent reread failed).
class _Pending extends StatelessWidget {
  const _Pending({required this.count, required this.action});

  final int count;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSize.spaceM, AppSize.gap, AppSize.spaceM, 0),
      child: FeedbackButton(
        action: action,
        padding: EdgeInsets.all(AppSize.gap),
        radius: AppSize.cornerInset(AppSize.gap),
        color: scheme.primary.withValues(alpha: 0.12),
        child: TextSmall(
          S.of(context).messages_pending(count),
          textAlign: TextAlign.center,
          color: scheme.primary
        )
      )
    );
  }
}
