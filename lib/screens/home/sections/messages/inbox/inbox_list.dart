import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chats_service.dart';

import './inbox_tile.dart';

class InboxList extends StatelessWidget {
  const InboxList({super.key, required this.service});

  final ChatsService service;

  /// How close to the end (in pixels) the next page is asked for.
  static const double _threshold = 240;

  @override
  Widget build(BuildContext context) {
    final chats = service.chats;
    final footer = service.hasMore ? 1 : 0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _threshold) service.more();
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.all(AppSize.gap),
        itemCount: chats.length + footer,
        itemBuilder: (context, index) {
          if (index < chats.length) {
            final chat = chats[index];

            return InboxTile(
              key: ValueKey(chat.id),
              chat: chat,
              tags: [for (final code in chat.tags) service.tagOf(code)],
              selected: chat.id == service.selected,
              onTap: () => service.select(chat.id)
            );
          }

          return Padding(
            padding: EdgeInsets.all(AppSize.spaceS),
            child: service.moreFailed
              ? FeedbackButton(
                  action: service.retryMore,
                  padding: EdgeInsets.all(AppSize.gap),
                  radius: AppSize.cornerInset(AppSize.gap),
                  child: TextSmall(
                    S.of(context).messages_more_failed,
                    textAlign: TextAlign.center,
                    color: ThemeColor.of(context).text.secondary
                  )
                )
              : Center(child: SizedBox.square(
                  dimension: AppSize.button * 0.6,
                  child: const Loading()
                ))
          );
        }
      )
    );
  }
}
