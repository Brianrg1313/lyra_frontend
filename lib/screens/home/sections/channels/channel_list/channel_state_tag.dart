import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_lite_model.dart';

/// The state tag of a channel, in the list row.
///
/// A channel has **two states that are not the same** and confusing them
/// wastes time:
///
/// - `ready` — whether it has loaded everything its network asks of it. A
///   newly registered channel still without tokens is normal (it is created
///   before Meta issues them) and is simply not ready. It is not an error: it
///   just needs to be finished.
/// - `enabled` — the business's switch. A complete channel can be paused
///   without losing its configuration.
///
/// Hence the three badges: paused wins over the rest —if it is off it does not
/// matter that it is complete—, then "needs configuration", and only if it is
/// whole and on, "connected".
class ChannelStateTag extends StatelessWidget {
  const ChannelStateTag({super.key, required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, color) = switch (channel) {
      // Paused first: it is what explains that a complete channel does not
      // answer.
      ChannelLiteModel(enabled: false) => (
        S.of(context).channel_state_paused,
        scheme.text.secondary
      ),
      ChannelLiteModel(ready: false) => (
        S.of(context).channel_state_pending,
        // The brand color and not red: it needs finishing, nothing broke.
        scheme.accent
      ),
      _ => (S.of(context).channel_state_ready, scheme.primary)
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        // A barely tinted background instead of a solid one: the tag accompanies
        // the channel's name, it does not compete with it.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(label, color: color)
    );
  }
}
