import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_model.dart';

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
