import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// The section's action, floating over the map's top right corner: "New
/// delivery", a sale of the branch sent as a delivery ("New delivery method"
/// lives in the panel, over the areas). The desk mounts it only with the board
/// and the permission to send sales.
class DeliveriesHeader extends StatelessWidget {
  const DeliveriesHeader({super.key, required this.onAdd});

  final void Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Button(
      width: null,
      title: S.of(context).deliveries_create,
      leftIcon: Icon(CI.plus, color: scheme.button.text),
      action: onAdd
    );
  }
}
