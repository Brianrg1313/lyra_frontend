import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import 'option_card.dart';

/// Arranges a block's options in as many columns as fit in the width
/// available.
///
/// One below the other, each option stretches edge to edge to say three
/// words: 90% of the card stays empty and the whole catalog becomes a list
/// you have to scroll through. Horizontally the problem is there all the
/// time, because width is exactly what's left over.
///
/// The columns aren't fixed beforehand but come out of [minWidth]: as many
/// fit as can without going below that width, and the surplus is shared
/// between them so the row closes exactly. That way the same block gives
/// four columns at full width and two when it's in half, without anyone
/// declaring sizes per device.
///
/// All the cards measure the same height ([OptionCard.height]): in a grid, a
/// card taller than its neighbor —because its description took two lines
/// instead of one— reads as an alignment error.
class OptionGrid extends StatelessWidget {
  const OptionGrid({super.key, required this.children, this.minWidth});

  final List<Widget> children;

  /// The narrowest a card can get before dropping a column. Below this the
  /// title starts to get cut off, which is worse than having one column
  /// fewer.
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final gap = AppSize.gap;
      final available = constraints.maxWidth;

      // Without a known width (inside something that scrolls horizontally)
      // no grid is possible: they stack, which is the only thing that always
      // works.
      if (!available.isFinite) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: child
            )
          ]
        );
      }

      final minimum = minWidth ?? AppSize.action * 4.5;

      // Never fewer than one column, and never more than there are options:
      // three options in a five-column width are three cards, not five holes.
      final columns = ((available + gap) / (minimum + gap))
        .floor()
        .clamp(1, children.length);

      // The surplus is shared, but only up to that point: a single option —the
      // service, when editing and it can no longer be changed— stretched edge
      // to edge is the same problem this came to fix.
      //
      // Floored, because the sum of the cards and their separations has to
      // fit in the row: a hair over due to floating-point rounding and the
      // last one drops to the next line.
      final width = math.min(
        (available - gap * (columns - 1)) / columns,
        minimum * 2
      ).floorToDouble();

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child)
        ]
      );
    });
  }
}
