import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './option_card.dart';

/// Arranges the options of a block in the columns that fit in the available
/// width.
///
/// One below the other, each option stretches edge to edge to say three
/// words: 90% of the card is left empty and the form's four decisions become
/// a list that has to be gone through scrolling. Horizontally the problem is
/// all the time, because width is precisely what is left over.
///
/// The columns are not fixed in advance but come out of [minWidth]: as many
/// fit as can without going below that width, and the surplus is distributed
/// among them so the row closes just right. That way the same block gives
/// four columns on a full screen and two when it is at half, without anyone
/// declaring sizes per device.
///
/// All the cards measure the same height ([OptionCard.height]): in a grid, a
/// card taller than its neighbour —because its description took two lines
/// instead of one— reads like an alignment error.
class OptionGrid extends StatelessWidget {
  const OptionGrid({super.key, required this.children, this.minWidth});

  final List<Widget> children;

  /// The narrowest a card can get before taking out a column. Below this the
  /// title starts getting cut, which is worse than having one column less.
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final gap = AppSize.gap;
      final available = constraints.maxWidth;

      // Without a known width (inside something that scrolls horizontally) there
      // is no possible grid: they stack, which is the only thing that always
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

      // Never less than one column, and never more than options there are: three
      // options in a width of five columns is three cards, not five slots.
      final columns = ((available + gap) / (minimum + gap))
        .floor()
        .clamp(1, children.length);

      // The surplus is shared, but up to a point: a single option —the network,
      // when editing and it can no longer be changed— stretched edge to edge
      // is the same problem this came to fix.
      //
      // Floored, because the sum of the cards and their separations has to
      // fit in the row: a hair over due to floating-point rounding and the
      // last one falls to the next line.
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
