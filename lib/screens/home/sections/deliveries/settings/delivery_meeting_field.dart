import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/profile_field_frame.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './delivery_flag_field.dart';

/// Whether the delivery areas are fixed or flexible: when a customer is
/// outside every area, the assistant either says it does not deliver there
/// or agrees with them on the nearest spot the areas reach, to meet the
/// courier (the backend picks that spot, on a street and inside an area).
///
/// Two answers and not three, unlike [DeliveryFlagField]: it is a promise to the
/// customer, so until the company turns it on it is off (see
/// [BusinessDeliveryModel.meeting]). Still a [SettingsSelect] and not a
/// toggle, because each answer needs its sentence to be chosen knowingly.
class DeliveryMeetingField extends StatelessWidget {
  const DeliveryMeetingField({super.key, required this.value, required this.onChanged});

  final bool value;
  final Future<void> Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ProfileFieldFrame(
      icon: CI.message_ai,
      label: S.of(context).business_delivery_meeting,
      description: S.of(context).business_delivery_meeting_note,
      // Sized like the flags' answers above, so the column lines up.
      child: Wrap(
        children: [
          SizedBox(
            width: AppSize.action * 5,
            child: SettingsSelect(
              label: _answer(context, value),
              color: value ? scheme.snackBar.success : scheme.text.secondary,
              message: S.of(context).business_delivery_choose,
              open: _open
            )
          )
        ]
      )
    );
  }

  Future<void> _open(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: [
        SelectOption(
          value: "fixed",
          placeholder: _answer(anchor, false),
          subtitle: S.of(anchor).business_delivery_meeting_fixed_note
        ),
        SelectOption(
          value: "flexible",
          placeholder: _answer(anchor, true),
          subtitle: S.of(anchor).business_delivery_meeting_flexible_note
        )
      ],
      selected: value ? "flexible" : "fixed",
      emptyText: S.of(anchor).business_delivery_select_empty
    );

    if (picked == null) return;

    final next = picked.value == "flexible";

    if (next == value) return;

    await onChanged(next);
  }

  String _answer(BuildContext context, bool value) => value
    ? S.of(context).business_delivery_meeting_flexible
    : S.of(context).business_delivery_meeting_fixed;
}
