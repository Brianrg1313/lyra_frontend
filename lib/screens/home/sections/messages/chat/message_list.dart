import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_thread_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './message_bubble.dart';

/// The history, newest at the bottom.
///
/// The list is built **reversed** so it opens at the latest message and stays
/// pinned there as new ones arrive; scrolling up to the top asks for the next
/// older page (`BEFORE`), which is prepended without moving what is on screen.
class MessageList extends StatelessWidget {
  const MessageList({super.key});

  /// How close to the oldest loaded message the next page is asked for.
  static const double _threshold = 200;

  @override
  Widget build(BuildContext context) {
    final thread = context.watch<ChatThreadService>();
    final messages = thread.messages;

    if (thread.status == ChatThreadStatus.loading && messages.isEmpty) {
      return const Center(child: Loading());
    }

    if (messages.isEmpty) {
      return SectionMessage(icon: CI.chat, title: S.of(context).messages_thread_empty);
    }

    final header = thread.hasOlder ? 1 : 0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Reversed: "after" is towards the oldest message.
        if (thread.hasOlder && notification.metrics.extentAfter < _threshold) {
          thread.older();
        }
        return false;
      },
      child: ListView.builder(
        reverse: true,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
        itemCount: messages.length + header,
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return Padding(
              padding: EdgeInsets.all(AppSize.spaceXS),
              child: Center(child: thread.loadingOlder
                ? SizedBox.square(dimension: AppSize.button * 0.6, child: const Loading())
                : FeedbackButton(
                    action: thread.older,
                    padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
                    radius: AppSize.cornerInset(AppSize.gap),
                    child: TextSmall(
                      S.of(context).messages_older,
                      color: ThemeColor.of(context).text.secondary
                    )
                  ))
            );
          }

          final position = messages.length - 1 - index;
          final message = messages[position];
          final previous = position > 0 ? messages[position - 1] : null;

          // Consecutive messages from the same side and author are grouped:
          // only the first of a run is spaced and labelled.
          final grouped = previous != null
            && previous.incoming == message.incoming
            && previous.author == message.author
            && previous.authorName == message.authorName;

          return MessageBubble(
            key: ValueKey(message.id),
            message: message,
            grouped: grouped
          );
        }
      )
    );
  }
}
