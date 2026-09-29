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
///
/// Beside whether it delivers goes the way to the delivery area: where it
/// delivers is the next question once the answer is yes. Under it, whether
/// those areas are fixed or flexible ([_MeetingField]).
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
        _FlagField(
          flag: DeliveryFlag.delivers,
          value: delivery.delivers,
          icon: CI.delivery,
          label: S.of(context).business_delivery_delivers,
          description: S.of(context).business_delivery_delivers_note,
          onChanged: onFlag,
          trailing: _AreaButton(action: onArea)
        ),
        _MeetingField(value: delivery.meeting, onChanged: onMeeting),
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
    required this.onChanged,
    this.trailing
  });

  final DeliveryFlag flag;
  final bool? value;
  final IconData icon;
  final String label;
  final String description;
  final Future<void> Function(DeliveryFlag flag, bool? value) onChanged;

  /// Drawn right of the answer, when the row has an action of its own.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ProfileFieldFrame(
      icon: icon,
      label: label,
      description: description,
      child: Wrap(
        spacing: AppSize.gap,
        runSpacing: AppSize.gap,
        children: [
          SizedBox(
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
          ),
          ?trailing
        ]
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

/// Whether the delivery areas are fixed or flexible: when a customer is
/// outside every area, the assistant either says it does not deliver there
/// or agrees with them on the nearest spot the areas reach, to meet the
/// courier (the backend picks that spot, on a street and inside an area).
///
/// Two answers and not three, unlike [_FlagField]: it is a promise to the
/// customer, so until the company turns it on it is off (see
/// [BusinessDeliveryModel.meeting]). Still a [SettingsSelect] and not a
/// toggle, because each answer needs its sentence to be chosen knowingly.
class _MeetingField extends StatelessWidget {
  const _MeetingField({required this.value, required this.onChanged});

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

/// Opens the delivery area page. Drawn like the [SettingsSelect] beside it, so
/// the two read as one row of controls.
class _AreaButton extends StatelessWidget {
  const _AreaButton({required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      color: scheme.surface.withAlpha(150),
      feedbackColor: scheme.surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.globe_shopping, size: AppSize.text * 0.9, color: scheme.icon),
          SizedBox(width: AppSize.gap * 0.75),
          TextSmall(S.of(context).deliveries_area)
        ]
      )
    );
  }
}
