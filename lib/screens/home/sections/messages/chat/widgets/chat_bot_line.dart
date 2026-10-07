import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/messages/chat_format.dart';

/// Who answers right now, and who the conversation is assigned to.
class ChatBotLine extends StatelessWidget {
  const ChatBotLine({super.key, required this.detail});

  final ChatDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final bot = detail.bot;
    final paused = bot.isPausedAt(DateTime.now());

    final String state;
    Color color = scheme.text.secondary;

    if (!bot.enabled) {
      state = S.of(context).messages_bot_disabled;
      color = scheme.chart.warning;
    } else if (paused) {
      final by = bot.by == null
        ? S.of(context).messages_bot_paused
        : S.of(context).messages_bot_paused_by(bot.by!.label);
      final until = bot.until == null
        ? ""
        : " ${S.of(context).messages_bot_until(chatDateLabel(context, bot.until))}";
      final reason = bot.reason.isEmpty ? "" : " · ${bot.reason}";

      state = "$by$until$reason";
      color = scheme.primary;
    } else {
      state = S.of(context).messages_bot_active;
    }

    final assignee = detail.assignee == null
      ? S.of(context).messages_unassigned
      : S.of(context).messages_assigned_to(detail.assignee!.label);

    return Row(children: [
      Icon(paused ? CI.user : CI.message_ai, size: AppSize.text, color: color),
      SizedBox(width: AppSize.gap),
      Flexible(child: TextSmall(state, ellipsis: true, color: color)),
      TextSmall("  ·  ", color: scheme.text.secondary),
      Flexible(child: TextSmall(assignee, ellipsis: true, color: scheme.text.secondary))
    ]);
  }
}
