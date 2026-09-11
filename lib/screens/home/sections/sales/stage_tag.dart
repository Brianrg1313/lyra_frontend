import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_model.dart';

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

/// The dot on its own.
///
/// It is public because the state filter draws the same one beside each option
/// of its list, and on the chip once one is chosen: the dropdown and the row
/// have to agree about what colour a state is, and two `Container`s with the
/// same numbers in them is exactly how they stop agreeing.
class SaleStageDot extends StatelessWidget {
  const SaleStageDot({super.key, required this.color});

  final Color color;

  /// Small enough to read as punctuation next to the label and not as a
  /// swatch: the colour is a hint about the row, not the row's subject.
  static const double _size = 8;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle)
  );
}

/// The colour a stage draws in **this** theme.
///
/// The colours come off `ChartScheme`, which is the design system's one
/// multi-hue palette and the only one with a light and a dark set that are
/// tuned per surface — the flag colours are not a palette at all, and reading
/// a stage off them is what left ten of the twelve states drawing a black dot
/// (`snackBar.alert` and `snackBar.notification` are both `0xFF000000`).
///
/// **A hue is a phase of the sale, not a stage**, and stages that share one
/// share it because they are the same question:
///
/// | | |
/// |---|---|
/// | blue | the sale is still being formed — nothing about the money is settled |
/// | violet | stock is held for somebody and nothing has been agreed |
/// | orange | the money is missing and it is **ours** to move |
/// | yellow | the money is missing and it is the **customer's** to move |
/// | aqua | paid, and the goods are still here for us to move |
/// | magenta | paid, and the goods are on their way to the customer |
/// | red | delivered on the company's tab and still unpaid |
/// | green | finished |
///
/// Twelve unrelated hues would be a legend to memorise; eight phases are what a
/// person actually reads a board by, and *which* of a phase's two stages a row
/// is at is the word next to the dot. Whether it is waiting on somebody here is
/// the weight, never a second colour.
///
/// An unknown stage falls back to its [level], so a state added on the backend
/// draws a sane colour instead of nothing — the same promise the label makes.
Color saleStageColor(BuildContext context, String stage, SaleLevel level) {
  final chart = ThemeColor.of(context).chart;

  return switch (stage) {
    // A till has a cart open, or the assistant is holding units: two ways of
    // having a sale that nobody has priced or charged.
    "open" => chart.series[0],
    "reserving" => chart.series[6],

    // Ours: nobody could tell them how to pay, or nobody has looked at what
    // they say they sent.
    "uncharged" => chart.series[1],
    "verifying" => chart.serious,

    // Theirs: they have the account and the money has not arrived.
    "paying" => chart.series[3],

    // Paid and still here — the box is on a shelf and somebody here moves next.
    "shipping" || "handover" => chart.series[2],

    // Paid and on its way, by road or by the customer coming for it. Nothing
    // for anybody here to do.
    "transit" || "pickup" => chart.series[4],

    // Delivered and unpaid, which is the one state on this board that is a debt
    // rather than a step.
    "owed" => chart.critical,

    "completed" || "sold" => chart.good,

    _ => saleLevelColor(context, level)
  };
}

/// The colour a *level* draws, for a stage this version does not know.
///
/// The three levels are the same vocabulary the badges and the conversation
/// stages already use, mapped onto the status slots of the chart palette so
/// that "algo va mal" looks the same wherever the app says it.
Color saleLevelColor(BuildContext context, SaleLevel level) {
  final chart = ThemeColor.of(context).chart;

  return switch (level) {
    SaleLevel.warning => chart.warning,
    SaleLevel.success => chart.good,
    SaleLevel.info => chart.series[0]
  };
}
