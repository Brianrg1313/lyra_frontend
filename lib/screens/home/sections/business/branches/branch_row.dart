import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';

/// One branch in the panel's list: its icon, its name and where it is. The
/// main one wears a yellow star instead of the shop.
///
/// The star is a Material icon: the app's icon font has none.
class BranchRow extends StatelessWidget {
  const BranchRow({super.key, required this.branch, required this.onTap});

  final BusinessBranchModel branch;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final place = branch.place;

    return FocusableWidget(
      action: onTap,
      message: branch.name,
      child: Container(
        padding: EdgeInsets.all(AppSize.spaceXS),
        decoration: BoxDecoration(
          color: scheme.surfaceOver,
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: Row(children: [
          Container(
            width: AppSize.button,
            height: AppSize.button,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.spaceXS))
            ),
            child: Center(child: branch.main
              ? Icon(
                  Icons.star_rounded,
                  size: AppSize.text * 1.3,
                  color: scheme.chart.warning,
                  semanticLabel: S.of(context).business_branch_main
                )
              : Icon(
                  branch.storefront ? CI.store : CI.warehouse,
                  size: AppSize.text * 1.2,
                  color: scheme.icon
                ))
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextMedium(branch.name, bold: true, ellipsis: true),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                place.isEmpty ? S.of(context).business_branch_no_address : place,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ))
        ])
      )
    );
  }
}
