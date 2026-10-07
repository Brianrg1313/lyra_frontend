import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/messages/chat_format.dart';

import './chat_tag_color.dart';

/// One tag. Unlike the stage plate it has no dot: the stage is the one place
/// on the path of a sale, tags are what else is true beside it. A tag that is
/// work for a person is written bold.
///
/// Hovering tells since when it is true and which tickets it was read from,
/// when the tag carries them (the detail and the `chat/tags` event do; an
/// inbox row carries codes only).
class ChatTagChip extends StatelessWidget {
  const ChatTagChip({super.key, required this.tag, this.dense = false});

  final ChatTag tag;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = chatTagColor(context, tag);

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap, vertical: AppSize.gap * 0.3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextMedium(
        tag.label,
        multiplier: dense ? 0.75 : 0.85,
        ellipsis: true,
        bold: tag.attention,
        color: color
      )
    );

    final hint = [
      if (tag.since != null) S.of(context).messages_tag_since(chatDateLabel(context, tag.since)),
      if (tag.tickets.isNotEmpty) S.of(context).messages_tag_tickets(tag.tickets.join(", "))
    ].join("\n");

    if (hint.isEmpty) return chip;

    return Tooltip(message: hint, child: chip);
  }
}
