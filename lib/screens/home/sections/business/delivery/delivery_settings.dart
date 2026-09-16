import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/profile_block.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The general answer: whether the company delivers, whether a customer can
/// collect, and its own sentence about delivery.
///
/// The two flags are picked where they are read ([SettingsSelect]) and save
/// themselves: choosing needs neither a keyboard nor a save button. They offer
/// **three** answers and not a switch, because "not set yet" is not "no" (see
/// [BusinessDeliveryModel]) and a switch can only say one of the other two.
class DeliverySettingsBlock extends StatelessWidget {
  const DeliverySettingsBlock({
    super.key,
    required this.delivery,
    required this.onFlag,
    required this.onNotes
  });

  final BusinessDeliveryModel delivery;

  /// Saves one flag; `null` is "not set".
  final Future<void> Function(DeliveryFlag flag, bool? value) onFlag;

  /// Opens the note's editor.
  final void Function() onNotes;

  @override
  Widget build(BuildContext context) {
    final notes = S.of(context).business_delivery_notes;

    return ProfileBlock(
      title: S.of(context).business_delivery_section_general,
      fields: [
        _FlagField(
          flag: DeliveryFlag.delivers,
          value: delivery.delivers,
          icon: CI.delivery,
          label: S.of(context).business_delivery_delivers,
          description: S.of(context).business_delivery_delivers_note,
          onChanged: onFlag
        ),
        _FlagField(
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

/// One of the yes/no settings, with its current answer as the dropdown that
/// changes it.
class _FlagField extends StatelessWidget {
  const _FlagField({
    required this.flag,
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
    required this.onChanged
  });

  final DeliveryFlag flag;
  final bool? value;
  final IconData icon;
  final String label;
  final String description;
  final Future<void> Function(DeliveryFlag flag, bool? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ProfileFieldFrame(
      icon: icon,
      label: label,
      description: description,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: AppSize.action * 5,
          child: SettingsSelect(
            label: _answer(context, value),
            // Coloured by what it means and grey while unset, so the one
            // answer a customer can be turned away with reads at a glance.
            color: switch (value) {
              true => scheme.snackBar.success,
              false => scheme.snackBar.error,
              null => scheme.text.secondary
            },
            message: S.of(context).business_delivery_choose,
            open: _open
          )
        )
      )
    );
  }

  /// Unfolds the three answers under the button and saves the one picked, if
  /// it is not the one there already.
  Future<void> _open(BuildContext anchor) async {
    final options = [
      SelectOption(value: "yes", placeholder: _answer(anchor, true)),
      SelectOption(value: "no", placeholder: _answer(anchor, false)),
      SelectOption(
        value: "unset",
        placeholder: _answer(anchor, null),
        // Only whether it delivers is measured: a company with options that
        // never said reads yes, and picking "not set" there changes nothing
        // on screen. It is said before it surprises anyone.
        subtitle: flag == DeliveryFlag.delivers
          ? S.of(anchor).business_delivery_unset_note
          : null
      )
    ];

    final picked = await showSelectMenu(
      context: anchor,
      options: options,
      selected: switch (value) { true => "yes", false => "no", null => "unset" },
      emptyText: S.of(anchor).business_delivery_select_empty
    );

    if (picked == null) return;

    final next = switch (picked.value) { "yes" => true, "no" => false, _ => null };

    if (next == value) return;

    await onChanged(flag, next);
  }

  String _answer(BuildContext context, bool? value) => switch (value) {
    true => S.of(context).business_delivery_yes,
    false => S.of(context).business_delivery_no,
    null => S.of(context).business_delivery_unset
  };
}
