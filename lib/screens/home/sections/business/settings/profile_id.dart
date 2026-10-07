import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

import './profile_action.dart';
import './profile_field_frame.dart';

/// The company identifier: hidden, with what to unhide it and what to copy
/// it with.
///
/// It's the only profile datum that isn't read, it's **used**: it's what's
/// pasted into a support ticket or an integration to name this company. It's
/// not a secret —on its own it authorizes nothing— but it also isn't for
/// having written in view while sharing the screen, so it's shown hidden.
///
/// It's copied without unhiding it, which is what's done with it almost
/// always: the button copies the whole identifier even though dots are seen on
/// screen. Unhiding it is for the other thing, comparing at a glance that it's
/// the one being looked for.
///
/// The value and its two buttons go together inside a box ([Surface.over]) and
/// not loose in the row like the rest of the data: this isn't a datum read
/// straight through, it's a value that's manipulated —unhidden, copied, pasted
/// outside—, and the box says how far it reaches. It also brings the buttons
/// together with what they operate on: unhide and copy don't hold for the row,
/// they hold for those characters, and crossed to the other end of the row
/// they looked like two more sheet actions.
///
/// The box measures what the identifier and its buttons measure, not the
/// column's width: stretched edge to edge with the buttons hanging off the
/// right edge it read as a sheet bar and not as the wrapper of a value.
class BusinessProfileId extends StatefulWidget {
  const BusinessProfileId({super.key, required this.id});

  final String id;

  @override
  State<BusinessProfileId> createState() => _BusinessProfileIdState();
}

class _BusinessProfileIdState extends State<BusinessProfileId> {
  /// It's unhidden on request and **doesn't stay unhidden**: the state is of
  /// this row, so coming back to the tab shows it hidden again.
  bool _visible = false;

  /// How many characters are left in view when hiding it. It's the first block
  /// of the uuid: enough to recognize which one it is without leaving it
  /// written in full.
  static const int _shown = 8;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: CI.key,
    label: S.of(context).business_profile_id,
    description: S.of(context).business_profile_id_note,
    child: _box(context)
  );

  /// The identifier and what's done with it, in a single box the width of its
  /// content.
  ///
  /// [Align] is what lets it measure its text: inside the sheet's column the
  /// width that arrives is the whole sheet's, and a row would take it all.
  Widget _box(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Surface.over(
      padding: EdgeInsets.only(
        left: AppSize.spaceXS,
        right: AppSize.gap,
        top: AppSize.gap,
        bottom: AppSize.gap
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The identifier is clipped before the buttons if the sheet gets
          // very narrow: `Flexible` and not `Expanded`, which would take the
          // width left over even if the text doesn't need it.
          Flexible(child: TextMedium(
            _visible ? widget.id : _masked,
            lines: 2,
            ellipsis: true,
            // Hidden there's nothing to select: what would get copied is the
            // dots.
            selectable: _visible
          )),
          SizedBox(width: AppSize.gap),
          ProfileAction(
            icon: _visible ? CI.eye_hidden : CI.eye,
            message: _visible
              ? S.of(context).business_profile_id_hide
              : S.of(context).business_profile_id_show,
            action: () => setState(() => _visible = !_visible)
          ),
          SizedBox(width: AppSize.gap),
          ProfileAction(
            icon: CI.copy,
            message: S.of(context).business_profile_id_copy,
            action: _copy
          )
        ]
      )
    )
  );

  /// The identifier with everything hidden except the first block.
  ///
  /// The dashes are kept: they preserve the uuid's shape, so what's seen still
  /// reads as an identifier and not as a row of dots.
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

    FloatFlag.of(context).message(S.of(context).business_profile_id_copied);
  }
}
