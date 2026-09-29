import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

import './chat_format.dart';
import './chat_stage_tag.dart';

/// Every tag of a conversation, as chips that wrap. Nothing when there are none.
class ChatTags extends StatelessWidget {
  const ChatTags({super.key, required this.tags, this.dense = false});

  /// In drawing order, as the backend sends them.
  final List<ChatTag> tags;

  /// Smaller text, for the inbox rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSize.gap * 0.6,
      runSpacing: AppSize.gap * 0.6,
      children: [
        for (final tag in tags) ChatTagChip(tag: tag, dense: dense)
      ]
    );
  }
}

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

/// Tags that state **the same fact as a stage**, by tag code. The stage picks
/// one of the facts the tags list, so beside that stage the tag only repeats
/// it («Reservando» and «Reserva»).
const Map<String, String> _stageOfTag = {
  "reserved": "reserving",
  "unpaid": "paying",
  "proof": "verifying",
  "uncharged": "uncharged",
  "silent": "abandoned"
};

/// The tags worth drawing beside [stage]: all of them but the one that repeats
/// it. The stage stays because it is what the list sorts and filters by.
List<ChatTag> chatTagsBeside(ChatStage stage, List<ChatTag> tags) => [
  for (final tag in tags)
    if (_stageOfTag[tag.tag] != stage.stage) tag
];

/// A tag that states a stage's fact takes **that stage's hue**, so under
/// another stage it still reads as the same fact. Any other code follows its
/// level.
Color chatTagColor(BuildContext context, ChatTag tag) {
  final scheme = ThemeColor.of(context);
  final chart = scheme.chart;

  if (_stageOfTag[tag.tag] case final stage?) {
    return chatStageColor(context, stage, tag.level);
  }

  return switch (tag.tag) {
    "paid" || "delivered" => chart.good,
    _ => switch (tag.level) {
      ChatLevel.critical => chart.critical,
      ChatLevel.warning => chart.warning,
      ChatLevel.success => chart.good,
      ChatLevel.muted => scheme.text.secondary,
      ChatLevel.info => chart.series[0]
    }
  };
}
