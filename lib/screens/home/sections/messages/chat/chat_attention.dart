import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_detail_model.dart';
import 'package:app/services/chats/chat_model.dart';
import 'package:app/services/chats/chat_thread_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/messages/chat_format.dart';
import 'package:app/screens/home/sections/messages/tags/chat_stage_color.dart';

/// The most urgent attention mark of the open conversation: what happened, the
/// text for the team (never shown to the customer), and "mark as resolved"
/// for pending work. A `failure` has no button: it clears itself once anybody
/// answers.
class ChatAttentionBar extends StatelessWidget {
  const ChatAttentionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final thread = context.watch<ChatThreadService>();
    final detail = thread.detail;
    final attention = detail?.attention;

    if (detail == null || attention == null) return const SizedBox.shrink();

    final scheme = ThemeColor.of(context);
    final color = chatWaitingColor(context, attention.kind);
    final extra = attention.also.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSize.spaceS, 0, AppSize.spaceS, AppSize.spaceXS),
      child: Container(
        padding: EdgeInsets.all(AppSize.spaceXS),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CI.info, size: AppSize.text * 1.4, color: color),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Flexible(child: TextMedium(
                    chatAttentionTitle(context, attention),
                    bold: true,
                    ellipsis: true,
                    color: color
                  )),
                  if (attention.since != null) TextSmall(
                    "  ·  ${chatWaitLabel(context, attention.since)}",
                    color: scheme.text.secondary
                  ),
                  if (extra > 0) TextSmall(
                    "  ·  ${S.of(context).messages_attention_more(extra)}",
                    color: scheme.text.secondary
                  )
                ]),
                if (attention.detail.isNotEmpty) ...[
                  SizedBox(height: AppSize.gap * 0.6),
                  TextSmall(attention.detail, lines: 6, selectable: true)
                ]
              ]
            )),
            if (attention.kind == ChatWaiting.pending) ...[
              SizedBox(width: AppSize.spaceXS),
              FeedbackButton(
                action: thread.busy ? null : () => thread.resolve(stage: _stage(attention)),
                message: S.of(context).messages_resolve,
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
                radius: AppSize.cornerInset(AppSize.gap),
                color: color.withValues(alpha: 0.16),
                child: TextMedium(S.of(context).messages_resolve, multiplier: 0.85, bold: true, color: color)
              )
            ]
          ]
        )
      )
    );
  }

  String? _stage(ChatAttention attention) =>
    attention.stage.isEmpty ? null : attention.stage;
}

String chatAttentionTitle(BuildContext context, ChatAttention attention) {
  if (attention.kind == ChatWaiting.failure) {
    return attention.partial
      ? S.of(context).messages_attention_partial
      : S.of(context).messages_attention_failure;
  }

  return switch (attention.stage) {
    "question" => S.of(context).messages_attention_question,
    "payment" => S.of(context).messages_attention_payment,
    "confirmation" => S.of(context).messages_attention_confirmation,
    _ => S.of(context).messages_attention_pending
  };
}
