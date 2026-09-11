import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The identifier of the table: covered, with what to uncover it and with
/// what to copy it.
///
/// It is the only data point of the card that is not read, it is **used**: it
/// is what is pasted in a support or an integration to name this table. It is
/// not a secret —on its own it authorizes nothing, the request travels the
/// same tied to the business— but it is not to have it written in view while
/// the screen is being shared, so it is shown covered.
///
/// It is copied without uncovering it, which is what is done with it almost
/// always: the button copies the whole identifier even though dots are seen on
/// screen. Uncovering it is for the other thing, comparing at a glance that
/// it is the one that was being looked for.
///
/// The value and its two buttons go together inside a box and not loose in
/// the row like the rest of the data points: this is not a data point read in
/// a row, it is a value that is manipulated —it is uncovered, copied, pasted
/// outside—, and the box says where it ends. It also joins the buttons with
/// what they operate on: uncovering and copying are not worth for the row,
/// they are worth for those characters.
///
/// The box goes the color of the page and not of the card, like the three
/// figures above: inside a block that is already a surface, another of the
/// same color would not be seen.
///
/// It is a sibling of the business identifier (`BusinessProfileId`) and not
/// the same widget: they are two different sections and the only thing they
/// share is how to show a uuid.
class TableSettingsId extends StatefulWidget {
  const TableSettingsId({super.key, required this.id});

  final String id;

  @override
  State<TableSettingsId> createState() => _TableSettingsIdState();
}

class _TableSettingsIdState extends State<TableSettingsId> {
  /// It is uncovered on demand and **does not stay uncovered**: the state is
  /// of this row, so going back to the screen shows it covered again.
  bool _visible = false;

  /// How many characters stay in view when tapping it. It is the first block
  /// of the uuid: it is enough to recognize which one it is without leaving
  /// it written whole.
  static const int _shown = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // `Align` is what lets it measure its text: inside the block column the
    // width that arrives is that of the whole card, and a row would take it
    // all.
    return Align(
      alignment: Alignment.centerLeft,
      child: Surface(
        color: scheme.surface,
        radius: AppSize.cornerInset(AppSize.spaceS),
        padding: EdgeInsets.only(
          left: AppSize.spaceXS,
          right: AppSize.gap,
          top: AppSize.gap,
          bottom: AppSize.gap
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The identifier is clipped before the buttons if the card gets
            // very narrow: `Flexible` and not `Expanded`, which would take the
            // leftover width even though the text does not need it.
            Flexible(child: TextMedium(
              _visible ? widget.id : _masked,
              lines: 2,
              ellipsis: true,
              // Covered there is nothing to select: what would be copied are
              // the dots.
              selectable: _visible
            )),
            SizedBox(width: AppSize.gap),
            SettingsAction(
              icon: _visible ? CI.eye_hidden : CI.eye,
              message: _visible
                ? S.of(context).table_settings_id_hide
                : S.of(context).table_settings_id_show,
              action: () => setState(() => _visible = !_visible)
            ),
            SizedBox(width: AppSize.gap),
            SettingsAction(
              icon: CI.copy,
              message: S.of(context).table_settings_id_copy,
              action: _copy
            )
          ]
        )
      )
    );
  }

  /// The identifier with everything covered except the first block.
  ///
  /// The hyphens are left: they keep the shape of the uuid, so what is seen
  /// keeps being read as an identifier and not as a row of dots.
  String get _masked {
    if (widget.id.length <= _shown) return "•" * widget.id.length;

    final hidden = [
      for (final char in widget.id.substring(_shown).split(""))
        char == "-" ? "-" : "•"
    ].join();

    return "${widget.id.substring(0, _shown)}$hidden";
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.id));

    if (!mounted) return;

    FloatFlag.of(context).message(S.of(context).table_settings_id_copied);
  }
}