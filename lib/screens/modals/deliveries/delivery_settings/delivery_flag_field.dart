import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_request.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/profile_field_frame.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// One of the yes/no settings, with its current answer as the dropdown that
/// changes it.
class DeliveryFlagField extends StatelessWidget {
  const DeliveryFlagField({
    super.key,
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
