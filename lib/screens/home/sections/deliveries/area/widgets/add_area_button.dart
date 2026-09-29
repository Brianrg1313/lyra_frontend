import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';

import '../state/area_editor.dart';

/// "Add area", in the page's header. It unfolds the three ways an area is
/// made, each with what it is for, since the right one depends on how the
/// company thinks of where it delivers: "5 km around us", "this part of the
/// city", "as far as a rider gets in 20 minutes".
class AddAreaButton extends StatelessWidget {
  const AddAreaButton({super.key, required this.onPick});

  /// Starts an area made by the method picked.
  final void Function(AreaMethod method) onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      height: AppSize.button,
      feedbackColor: scheme.surfaceFeedback,
      padding: EdgeInsets.symmetric(horizontal: AppSize.padding),
      action: () => _open(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.plus, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          TextMedium(S.of(context).deliveries_area_add)
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

    for (final method in AreaMethod.values) {
      if (method.name == picked.value) return onPick(method);
    }
  }
}
