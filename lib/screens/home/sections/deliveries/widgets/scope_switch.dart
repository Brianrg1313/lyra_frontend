import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

/// Which areas are in force, as two halves of one control: one map shared by
/// every branch, or one per branch. The note under it says what the one on
/// means for an order, which is the difference between the two.
///
/// Switching deletes nothing (the other map is kept), so it asks no
/// confirmation. [onChanged] `null` shows it without letting it change (a
/// write in flight, or the areas not read yet).
class DeliveryScopeSwitch extends StatelessWidget {
  const DeliveryScopeSwitch({super.key, required this.scope, required this.onChanged});

  final DeliveryScope scope;
  final void Function(DeliveryScope scope)? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(AppSize.gap * 0.5),
          decoration: BoxDecoration(
            color: scheme.surfaceOver,
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Row(children: [
            for (final option in DeliveryScope.values)
              Expanded(child: _Half(
                scope: option,
                on: option == scope,
                onTap: onChanged == null || option == scope ? null : () => onChanged!(option)
              ))
          ])
        ),
        SizedBox(height: AppSize.gap),
        TextSmall(
          scope == DeliveryScope.global
            ? S.of(context).deliveries_scope_global_note
            : S.of(context).deliveries_scope_branch_note,
          lines: 3,
          color: scheme.text.secondary
        )
      ]
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({required this.scope, required this.on, required this.onTap});

  final DeliveryScope scope;
  final bool on;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = on ? scheme.button.text : scheme.text.primary;

    return FeedbackButton(
      action: onTap,
      mouseCursor: onTap == null ? SystemMouseCursors.basic : null,
      height: AppSize.button * 0.85,
      radius: AppSize.corner - AppSize.gap * 0.5,
      color: on ? scheme.primary : Colors.transparent,
      feedbackColor: on ? scheme.primary : scheme.surfaceFeedback,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            scope == DeliveryScope.global ? CI.globe_shopping : CI.store,
            size: AppSize.text,
            color: color
          ),
          SizedBox(width: AppSize.gap),
          Flexible(child: TextSmall(
            scope == DeliveryScope.global
              ? S.of(context).deliveries_scope_global
              : S.of(context).deliveries_scope_branch,
            bold: on,
            ellipsis: true,
            color: color
          ))
        ]
      )
    );
  }
}
