import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/settings/profile_action.dart';
import 'package:app/screens/home/sections/business/settings/profile_block.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './delivery_area_button.dart';
import './delivery_flag_field.dart';
import './delivery_meeting_field.dart';

/// The general answer: whether the company delivers, whether a customer can
/// collect, and its own sentence about delivery.
///
/// The two flags are picked where they are read ([SettingsSelect]) and save
/// themselves: choosing needs neither a keyboard nor a save button. They offer
/// **three** answers and not a switch, because "not set yet" is not "no" (see
/// [BusinessDeliveryModel]) and a switch can only say one of the other two.
///
/// Beside whether it delivers goes the way to the delivery area: where it
/// delivers is the next question once the answer is yes. Under it, whether
/// those areas are fixed or flexible ([DeliveryMeetingField]).
class DeliverySettingsBlock extends StatelessWidget {
  const DeliverySettingsBlock({
    super.key,
    required this.delivery,
    required this.onFlag,
    required this.onNotes,
    required this.onArea,
    required this.onMeeting
  });

  final BusinessDeliveryModel delivery;

  /// Saves one flag; `null` is "not set".
  final Future<void> Function(DeliveryFlag flag, bool? value) onFlag;

  /// Opens the note's editor.
  final void Function() onNotes;

  /// Opens the delivery area page.
  final void Function() onArea;

  /// Saves whether the areas are flexible (`true`) or fixed.
  final Future<void> Function(bool value) onMeeting;

  @override
  Widget build(BuildContext context) {
    final notes = S.of(context).business_delivery_notes;

    return ProfileBlock(
      title: S.of(context).business_delivery_section_general,
      fields: [
        DeliveryFlagField(
          flag: DeliveryFlag.delivers,
          value: delivery.delivers,
          icon: CI.delivery,
          label: S.of(context).business_delivery_delivers,
          description: S.of(context).business_delivery_delivers_note,
          onChanged: onFlag,
          trailing: DeliveryAreaButton(action: onArea)
        ),
        DeliveryMeetingField(value: delivery.meeting, onChanged: onMeeting),
        DeliveryFlagField(
          flag: DeliveryFlag.pickup,
          value: delivery.pickup,
          icon: CI.store,
          label: S.of(context).business_delivery_pickup,
          description: S.of(context).business_delivery_pickup_note,
          onChanged: onFlag
        ),
        ProfileField(
          icon: CI.chat,
          label: notes,
          description: S.of(context).business_delivery_notes_note,
          value: delivery.notes,
          trailing: ProfileAction(
            icon: delivery.notes.isEmpty ? CI.plus : CI.edit,
            message: delivery.notes.isEmpty
              ? S.of(context).business_profile_add(notes)
              : S.of(context).business_profile_edit(notes),
            action: onNotes
          )
        )
      ]
    );
  }
}
