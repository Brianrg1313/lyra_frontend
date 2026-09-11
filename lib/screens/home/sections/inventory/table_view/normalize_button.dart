import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_normalize_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

/// The normalize-table button, next to the settings one.
///
/// Normalizing is what gives each column the type that matches what it holds —a
/// price that compares as a number, a date that sorts, a description the model
/// can search by meaning— and seeds how much of it the agent sees. It is what
/// runs automatically when importing a sheet, and it is here for the tables that
/// did not get it: the ones built by hand column by column, the ones imported
/// with normalization off, and the ones that since then filled up with data that
/// does not resemble the sample they were typed with.
///
/// It goes **before** the settings and not inside them even though it touches
/// the same thing: the settings are where a column is fixed, one at a time and
/// knowing which one; this is what is pressed when you do not know which, which
/// is the normal state of a table just brought in from an Excel. Hidden inside,
/// only someone who already went looking for the column they were going to fix
/// by hand would find it.
///
/// It asks first, even though normalization does not overwrite anything chosen
/// by hand: what it does takes a while —on the other side a model reads the
/// whole table— and rewrites the values of the columns it re-types. That it
/// starts from an absent-minded click on the bar would be a wait no one asked
/// for.
///
/// While it runs it gives its place to the spinner instead of staying
/// pressable: it is the only request of this screen measured in tens of seconds,
/// and without this the bar would say nothing about something being in
/// progress.
class NormalizeButton extends StatefulWidget {
  const NormalizeButton({super.key});

  @override
  State<NormalizeButton> createState() => _NormalizeButtonState();
}

class _NormalizeButtonState extends State<NormalizeButton> {
  /// `true` while the normalization travels. It belongs to the button and not
  /// to the service: it is how long **this** button is pressed, and the re-read
  /// that follows it is already announced on its own in the [HeaderActions]
  /// spinner.
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // While it runs it stays the same button and not a hole with a spinner: it
    // keeps its place in the bar —which otherwise would shift entirely— and,
    // above all, its label, which is where it says the wait is this one and not
    // the sheet's. Without action and without the hand, which would promise a
    // second click that does nothing.
    return FeedbackButton(
      action: _running ? null : () => _normalize(context),
      mouseCursor: _running ? SystemMouseCursors.basic : null,
      width: AppSize.action,
      height: AppSize.action,
      feedbackColor: scheme.surfaceFeedback,
      message: _running
        ? S.of(context).table_normalize_running
        : S.of(context).table_normalize,
      child: Center(child: _running
        ? SizedBox(
            width: AppSize.text,
            height: AppSize.text,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          )
        : Icon(CI.ia, color: scheme.text.primary)
      )
    );
  }

  /// Asks, normalizes, and counts what changed.
  ///
  /// The table is re-read inside the service, so when returning from here the
  /// sheet already shows the new columns: the only thing left is saying how many
  /// there were, because a changed type is not seen —a price column keeps
  /// showing the same numbers— and without the notice the normalization would
  /// seem to have done nothing.
  Future<void> _normalize(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).table_normalize_title,
      message: S.of(context).table_normalize_message,
      confirmText: S.of(context).table_normalize_confirm,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted || !context.mounted) return;

    setState(() => _running = true);

    final report = await context.read<TableViewService>().normalize(context);

    if (!mounted) return;
    setState(() => _running = false);

    // Without a report there is nothing to tell: the normalization did not go
    // through and the error was already shown in the floating flag.
    if (report == null || report.isEmpty) return;
    if (!context.mounted) return;

    FloatFlag.of(context).message(_summary(context, report));
  }

  /// What the normalization did, in one line.
  ///
  /// The four counters are told separately and not summed because they are not
  /// the same thing: re-typing a column changes how what it holds is stored and
  /// compared, changing its visibility changes what a bot sees, giving it a
  /// name changes what is read above it, and putting it in the summary changes
  /// what a person is shown of the stock at a glance. "Four columns changed"
  /// would not let you know which of the four things happened.
  ///
  /// A table that was already fine has its own notice: nothing changed, and
  /// without saying it the click would go unanswered.
  static String _summary(BuildContext context, TableNormalizeModel report) {
    if (report.changed == 0) return S.of(context).table_normalize_none;

    return [
      if (report.retyped > 0) S.of(context).table_normalize_retyped(report.retyped),
      if (report.narrowed > 0) S.of(context).table_normalize_narrowed(report.narrowed),
      if (report.renamed > 0) S.of(context).table_normalize_renamed(report.renamed),
      if (report.summarized > 0)
        S.of(context).table_normalize_summarized(report.summarized)
    ].join(" · ");
  }
}
