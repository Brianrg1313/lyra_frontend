import 'package:flutter/material.dart';

// SERVICES
import 'package:app/services/stock/summary/stock_summary_model.dart';

import './summary_layout.dart';

/// The skeleton of a summary row, which is the same for the header and for the
/// products: if both weren't drawn with the same distribution, each title would
/// land over the wrong column.
///
/// The text columns share the leftover width in proportion to how wide they
/// were left in the spreadsheet ([SummaryLayout.flexOf]); the photo, the numbers
/// and the short columns ([SummaryLayout.widthOf]) measure their own.
class SummaryLine extends StatelessWidget {
  const SummaryLine({
    super.key,
    required this.layout,
    required this.field,
    required this.number,
    this.image,
    this.padding
  });

  final SummaryLayout layout;

  /// What goes in the photo column, or null if nothing goes. The header leaves
  /// it empty: a photos column doesn't need to be told what it is.
  final Widget? image;

  final Widget Function(StockSummaryColumn column) field;
  final Widget Function(StockSummaryColumn column) number;

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(width: SummaryLayout.gap);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(children: [
        if (layout.image != null) ...[
          SizedBox(
            width: SummaryLayout.imageSize,
            // Square only when there's a photo to put. In the header this
            // column is nothing but a reserved place so the titles land on the
            // column they name, and giving it a photo's height there would
            // stretch the header to the height of a whole row —or, with a
            // smaller declared height, squash it to half.
            height: image == null ? null : SummaryLayout.imageSize,
            child: image
          ),
          gap
        ],
        for (final column in layout.fields) ...[
          if (SummaryLayout.widthOf(column) case final width?)
            SizedBox(width: width, child: field(column))
          else
            Expanded(flex: SummaryLayout.flexOf(column), child: field(column)),
          gap
        ],
        // A table can have no text column in the summary (none chosen yet, or
        // only short ones like a price and a code): the leftover is filled by the
        // air, so the numbers don't shift to the middle.
        if (!layout.hasFlexible) const Spacer(),
        for (final column in layout.numbers) ...[
          SizedBox(width: SummaryLayout.numberWidth, child: number(column)),
          if (column != layout.numbers.last) gap
        ]
      ])
    );
  }
}
