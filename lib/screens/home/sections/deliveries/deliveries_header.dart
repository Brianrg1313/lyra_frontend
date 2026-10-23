import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// The section's action, floating over the map's top right corner: "New
/// delivery" ("New delivery method" lives in the panel, over the areas).
///
/// "New delivery" has no endpoint behind it yet, so it answers coming soon.
class DeliveriesHeader extends StatelessWidget {
  const DeliveriesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Button(
      width: null,
      title: S.of(context).deliveries_create,
      leftIcon: Icon(CI.plus, color: scheme.button.text),
      action: () => FloatFlag.of(context).message(S.of(context).coming_soon)
    );
  }
}
