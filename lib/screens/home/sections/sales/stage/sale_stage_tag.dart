import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_model.dart';

import './sale_stage_color.dart';
import './sale_stage_dot.dart';

/// Where a sale stands, as one thing on the screen: the name the backend gave
/// the stage, in the colour this app gives it.
///
/// **The word is never written here.** Which states exist, what each is called
/// and which section it belongs to are declared once on the backend
/// (`model:/sales/progress.js`) and travel on every row, so a stage added there
/// shows up in this tag without a new version of the app. What this file owns
/// is the translation from a stage to a colour of *this* theme, which is the
/// one half the backend cannot know.
class SaleStageTag extends StatelessWidget {
  const SaleStageTag({
    super.key,
    required this.stage,
    required this.label,
    required this.level,
    this.attention = false
  });

  /// The stage's code, which is what picks the colour.
  final String stage;

  /// The stage's name as it arrived.
  final String label;

  /// What to fall back to when [stage] is one this version has never heard of.
  final SaleLevel level;

  /// Whether the sale is waiting on somebody here rather than on the customer.
  /// It is drawn as weight and not as a second colour: the stage already owns
  /// the colour, and two colours on one tag would be two things to read where
  /// there is one fact.
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final color = saleStageColor(context, stage, level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        // The same barely tinted plate the channel and connection tags use: it
        // is the state of the row and not the row's subject, so it carries the
        // colour without competing with the customer's name beside it.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The dot repeats what the plate and the text already say, and it is
          // the only one of the three that needs no contrast ratio to be read:
          // the palette is tuned for marks, so a pale stage stays legible as a
          // colour even where its text has gone soft on a light surface.
          SaleStageDot(color: color),
          SizedBox(width: AppSize.gap),
          // [TextMedium] at the small size and not [TextSmall]: the weight is
          // half of what this tag says —whether the sale is waiting on somebody
          // here— and only the medium one can be set bold.
          Flexible(child: TextMedium(
            label,
            multiplier: 0.9,
            ellipsis: true,
            bold: attention,
            color: color
          ))
        ]
      )
    );
  }
}
