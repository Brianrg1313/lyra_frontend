import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

import '../chat_format.dart';
import '../chat_stage_tag.dart';
import '../chat_tag.dart';

/// One conversation of the inbox: who, when, where it stands and every tag
/// beside the stage, and the marks that ask for a person (unanswered,
/// attention, taken by a person).
class InboxTile extends StatelessWidget {
  const InboxTile({
    super.key,
    required this.chat,
    this.tags = const [],
    required this.selected,
    required this.onTap
  });

  final ChatModel chat;

  /// [chat]'s tag codes named from the catalog.
  final List<ChatTag> tags;
  final bool selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    // A tag that is work for a person already says what the attention icon
    // would: the icon stays only for a mark no tag names.
    final waiting = tags.any((tag) => tag.attention) ? null : chat.waiting;
    final paused = chat.bot.isPausedAt(DateTime.now());
    final beside = chatTagsBeside(chat.stage, tags);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap * 0.5),
      child: FeedbackButton(
        action: onTap,
        message: chat.title,
        padding: EdgeInsets.all(AppSize.spaceXS),
        radius: AppSize.cornerInset(AppSize.gap),
        color: selected ? scheme.surfaceOver : scheme.surface,
        feedbackColor: scheme.line,
        child: Row(children: [
          ProfilePicture(kind: ProfileKind.customer, size: AppSize.action, label: chat.title),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: TextMedium(
                  chat.title,
                  bold: !chat.answered,
                  ellipsis: true
                )),
                SizedBox(width: AppSize.gap),
                TextSmall(
                  chatTimeLabel(context, chat.activity),
                  multiplier: 0.9,
                  color: chat.answered ? scheme.text.secondary : scheme.primary
                )
              ]),
              SizedBox(height: AppSize.gap * 0.8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Wrap(
                  spacing: AppSize.gap * 0.6,
                  runSpacing: AppSize.gap * 0.6,
                  children: [
                    ChatStageTag(stage: chat.stage, dense: true),
                    for (final tag in beside) ChatTagChip(tag: tag, dense: true)
                  ]
                )),
                if (waiting != null) Padding(
                  padding: EdgeInsets.only(left: AppSize.gap),
                  child: Icon(CI.info, size: AppSize.text * 1.2, color: chatWaitingColor(context, waiting))
                ),
                if (paused) Padding(
                  padding: EdgeInsets.only(left: AppSize.gap),
                  child: Icon(CI.user, size: AppSize.text * 1.2, color: scheme.text.secondary)
                ),
                if (!chat.answered) Padding(
                  padding: EdgeInsets.only(left: AppSize.gap),
                  child: Container(
                    width: AppSize.gap * 1.8,
                    height: AppSize.gap * 1.8,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)
                  )
                )
              ])
            ]
          ))
        ])
      )
    );
  }
}
