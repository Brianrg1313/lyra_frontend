import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

Color chatStageColor(BuildContext context, String stage, ChatLevel level) {
  final scheme = ThemeColor.of(context);
  final chart = scheme.chart;

  return switch (stage) {
    "inquiry" => chart.series[0],
    "reserving" => chart.series[6],
    "uncharged" => chart.series[1],
    "verifying" => chart.serious,
    "paying" => chart.series[3],
    "sold" => chart.good,
    "ended" || "abandoned" => scheme.text.secondary,
    _ => switch (level) {
      ChatLevel.warning => chart.warning,
      ChatLevel.success => chart.good,
      ChatLevel.critical => chart.critical,
      ChatLevel.muted => scheme.text.secondary,
      ChatLevel.info => chart.series[0]
    }
  };
}

/// The colour of an attention mark: a failed turn is worse than pending work.
Color chatWaitingColor(BuildContext context, ChatWaiting waiting) {
  final chart = ThemeColor.of(context).chart;

  return waiting == ChatWaiting.failure ? chart.critical : chart.serious;
}
