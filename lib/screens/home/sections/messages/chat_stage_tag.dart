import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

/// Where a conversation stands: the backend's word for the stage, in this
/// app's colour for it.
///
/// The stage codes a conversation shares with the sales board (`sold`,
/// `verifying`, `paying`, `uncharged`, `reserving`) take the **same hue** as
/// `saleStageColor` gives them, so a customer reads the same in both screens.
/// `ended`/`abandoned` are over and go muted; an unknown stage falls back to
/// its level.
class ChatStageTag extends StatelessWidget {
  const ChatStageTag({super.key, required this.stage, this.dense = false});

  final ChatStage stage;

  /// Smaller text, for the inbox rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (stage.isEmpty) return const SizedBox.shrink();

    final color = chatStageColor(context, stage.stage, stage.level);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap, vertical: AppSize.gap * 0.4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)
          ),
          SizedBox(width: AppSize.gap),
          Flexible(child: TextMedium(
            stage.label.isNotEmpty ? stage.label : stage.stage,
            multiplier: dense ? 0.8 : 0.9,
            ellipsis: true,
            bold: stage.attention,
            color: color
          ))
        ]
      )
    );
  }
}

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
