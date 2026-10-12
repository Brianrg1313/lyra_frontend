import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One decision of a channel's form, as a ledger line: its label on the left
/// and the controls on the right, with at most one short [note] under them.
///
/// The form used to give every block a title, a two-line subtitle and cards
/// with two more lines each, which made thirty-odd lines to read before
/// saving. Here the label names the decision and the note explains only
/// **what is chosen** (a single choice) or the one thing worth knowing (a
/// multiple one); the controls name the options themselves.
///
/// Narrower than [_sideBySide] (the detail panel on a small window) the label
/// goes above. Both halves always sit in the same [Wrap] and only their
/// widths change, never the tree's shape: the credential and table inputs
/// live in [child], and an `InputController` does not survive a remount (see
/// `ChannelFormSection._body`).
///
/// Without [label] the controls take the whole width: the create modal asks
/// one decision per page, and the page's own title already names it.
class ChannelFormRow extends StatelessWidget {
  const ChannelFormRow({
    super.key,
    this.label,
    required this.child,
    this.note,
    this.alignToControl = true
  });

  final String? label;
  final Widget child;
  final String? note;

  /// Centers the label on the first line of controls, a button tall. Off for
  /// inputs, whose own title is that first line.
  final bool alignToControl;

  static double get labelWidth => AppSize.action * 2.8;
  static double get _sideBySide => AppSize.action * 9;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSize.spaceM),
    child: LayoutBuilder(builder: (context, constraints) {
      // Unmeasured, the narrow layout's widths are taken from the threshold.
      final available = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _sideBySide;

      final label = this.label;
      final side = label != null && available >= _sideBySide;

      return Wrap(
        runSpacing: AppSize.gap,
        children: [
          if (label != null) SizedBox(
            width: side ? labelWidth : available,
            child: Padding(
              padding: EdgeInsets.only(
                top: side && alignToControl
                  ? (AppSize.button - AppSize.text * 1.4) / 2
                  : 0,
                right: AppSize.spaceXS
              ),
              child: TextMedium(label, bold: true, lines: 2, ellipsis: true)
            )
          ),
          SizedBox(
            // Floored: a hair over the row and the Wrap drops it below.
            width: (side ? available - labelWidth : available).floorToDouble(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                if (note != null) ChannelFormNote(note!)
              ]
            )
          )
        ]
      );
    })
  );
}

/// The line under a row's controls.
class ChannelFormNote extends StatelessWidget {
  const ChannelFormNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSize.gap * 1.5),
    child: TextSmall(
      text,
      lines: 2,
      ellipsis: true,
      color: ThemeColor.of(context).text.secondary
    )
  );
}
