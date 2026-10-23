import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';

/// "Add area", first in the desk's panel over the areas. It unfolds the three ways an area is
/// made, each with what it is for, since the right one depends on how the
/// company thinks of where it delivers: "5 km around us", "this part of the
/// city", "as far as a rider gets in 20 minutes".
///
/// While the panel only looks at the areas, the same place reads "New delivery
/// method" ([AddAreaButton.method]): a method's last step is where its areas
/// are added.
class AddAreaButton extends StatelessWidget {
  const AddAreaButton({super.key, required void Function(AreaMethod method) this.onPick}) : onMethod = null;

  const AddAreaButton.method({super.key, required void Function() this.onMethod}) : onPick = null;

  /// Starts an area made by the method picked.
  final void Function(AreaMethod method)? onPick;

  /// Starts a new delivery method.
  final void Function()? onMethod;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      height: AppSize.button,
      radius: AppSize.corner,
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      action: onMethod ?? () => _open(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CI.plus, size: AppSize.text, color: scheme.primary),
          SizedBox(width: AppSize.gap),
          TextSmall(
            onMethod == null ? S.of(context).deliveries_area_add : S.of(context).deliveries_method_new,
            bold: true,
            color: scheme.primary
          )
        ]
      )
    );
  }

  Future<void> _open(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      width: AppSize.action * 8,
      options: [
        SelectOption(
          value: AreaMethod.radius.name,
          placeholder: S.of(anchor).deliveries_area_method_radius,
          subtitle: S.of(anchor).deliveries_area_method_radius_note,
          icon: CI.circle
        ),
        SelectOption(
          value: AreaMethod.draw.name,
          placeholder: S.of(anchor).deliveries_area_method_draw,
          subtitle: S.of(anchor).deliveries_area_method_draw_note,
          icon: CI.pen
        ),
        SelectOption(
          value: AreaMethod.travel.name,
          placeholder: S.of(anchor).deliveries_area_method_travel,
          subtitle: S.of(anchor).deliveries_area_method_travel_note,
          icon: CI.delivery
        )
      ],
      emptyText: S.of(anchor).business_delivery_select_empty
    );

    if (picked == null) return;

    for (final method in const [AreaMethod.radius, AreaMethod.draw, AreaMethod.travel]) {
      if (method.name == picked.value) return onPick?.call(method);
    }
  }
}
