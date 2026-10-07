import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_lite_model.dart';

// WIDGETS


/// What the channel answers from, at the foot of its card.
///
/// The tables are **named**, each on its own surface: a channel carries no
/// name of its own any more, so the table is the only thing on the card
/// written by the company, and a count ("1 table") threw away the one word
/// that told two cards apart. The surface is what makes them read as things
/// and not as a sentence — a channel can hold more than one.
///
/// With no source it says exactly that, in words and not as an empty row:
/// that a channel reads from nothing is the single most important thing this
/// card can report, because it is what makes an agent invent prices.
class ChannelCardSources extends StatelessWidget {
  const ChannelCardSources({super.key, required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    if (channel.tables.isEmpty) {
      return Row(children: [
        Icon(CI.list, size: AppSize.text, color: scheme.text.secondary),
        SizedBox(width: AppSize.gap * 0.5),
        Expanded(child: TextSmall(
          S.of(context).channel_source_none,
          ellipsis: true,
          color: scheme.text.secondary
        ))
      ]);
    }

    // Every tag is flexible and none of them wraps: the card's height is
    // fixed so that every row of the grid measures the same, so what does not
    // fit is cut inside its own surface instead of pushing a second line the
    // card has no room for.
    return Row(children: [
      for (final (index, table) in channel.tables.indexed) ...[
        if (index > 0) SizedBox(width: AppSize.gap * 0.5),
        Flexible(child: Surface(
          color: scheme.surface,
          radius: AppSize.cornerInset(AppSize.spaceXS),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.gap,
            vertical: AppSize.gap * 0.4
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(CI.list, size: AppSize.text, color: scheme.text.secondary),
            SizedBox(width: AppSize.gap * 0.5),
            Flexible(child: TextSmall(table.name, ellipsis: true))
          ])
        ))
      ]
    ]);
  }
}
