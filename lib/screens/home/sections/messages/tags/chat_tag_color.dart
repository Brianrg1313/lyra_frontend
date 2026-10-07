import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

import './chat_stage_color.dart';

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
