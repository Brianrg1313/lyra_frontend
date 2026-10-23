import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

/// Whether the delivery areas are fixed or flexible: when a customer is
/// outside every area, the assistant either says it does not deliver there
/// or agrees with them on the nearest spot the areas reach, to meet the
/// courier (the backend picks that spot, on a street and inside an area).
///
/// Two answers and not three, unlike `DeliveryFlagField`: it is a promise to
/// the customer, so until the company turns it on it is off (see
/// [BusinessDeliveryModel.meeting]). Both drawn at once, each with its
/// sentence, so the one picked is picked knowingly. Saved with the method,
/// not on tap.
class DeliveryMeetingField extends StatelessWidget {
  const DeliveryMeetingField({super.key, required this.value, required this.onChanged});

  final bool value;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _Choice(
        icon: CI.globe_shopping,
        label: S.of(context).business_delivery_meeting_fixed,
        note: S.of(context).business_delivery_meeting_fixed_note,
        on: !value,
        onTap: () => onChanged(false)
      )),
      SizedBox(width: AppSize.gap),
      Expanded(child: _Choice(
        icon: CI.message_ai,
        label: S.of(context).business_delivery_meeting_flexible,
        note: S.of(context).business_delivery_meeting_flexible_note,
        on: value,
        onTap: () => onChanged(true)
      ))
    ]
  );
}

/// One of the two answers; the one on is outlined in the primary colour.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.label,
    required this.note,
    required this.on,
    required this.onTap
  });

  final IconData icon;
  final String label;
  final String note;
  final bool on;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final radius = BorderRadius.circular(AppSize.corner);

    return FocusableWidget(
      action: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(AppSize.spaceS),
        decoration: BoxDecoration(
          color: on ? scheme.primary.withAlpha(24) : scheme.surfaceOver,
          borderRadius: radius,
          border: Border.all(color: on ? scheme.primary : scheme.line)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: AppSize.text, color: on ? scheme.primary : scheme.icon),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextSmall(label, bold: true, ellipsis: true))
            ]),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(note, lines: 3, color: scheme.text.secondary)
          ]
        )
      )
    );
  }
}
