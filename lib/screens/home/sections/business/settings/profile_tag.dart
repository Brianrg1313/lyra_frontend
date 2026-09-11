import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Tag of a state: icon and text over a faint fill of its own color.
///
/// It's for what the sheet **says** about a datum and not for what the datum
/// is worth: the company's legal status next to its name, and whether an email
/// address was verified next to the address. Both are read at a glance and
/// neither is edited, so they aren't one more row.
///
/// The color is put by whoever uses it and not by the tag: it's semantic
/// —green arrives, amber nobody verified it— and lives next to the state it
/// signifies, not here.
class ProfileTag extends StatelessWidget {
  const ProfileTag({
    super.key,
    required this.icon,
    required this.label,
    required this.color
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.spaceXS,
      vertical: AppSize.gap / 2
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSize.text, color: color),
        SizedBox(width: AppSize.gap),
        TextSmall(label, color: color)
      ]
    )
  );
}
