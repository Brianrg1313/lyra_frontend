import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';

import './branch_glyph.dart';
import './branches_focus.dart';

/// One branch in the panel's list: its mark (the same as its pin's), its name
/// and where it is. Flat until pointed at — here or on its pin —, then filled,
/// so the row and the pin say they are the same branch.
///
/// A branch without a point says so at the end: tapping it opens its form but
/// cannot move the map.
class BranchRow extends StatelessWidget {
  const BranchRow({super.key, required this.branch, required this.onTap});

  final BusinessBranchModel branch;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final focus = context.watch<BranchesFocus>();
    final lit = focus.lit(branch.id);
    final place = branch.place;

    return MouseRegion(
      onEnter: (_) => focus.hover(branch.id, true),
      onExit: (_) => focus.hover(branch.id, false),
      child: FocusableWidget(
        action: onTap,
        message: branch.name,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
          padding: EdgeInsets.all(AppSize.spaceXS),
          decoration: BoxDecoration(
            color: lit ? scheme.surfaceOver : scheme.surface,
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
          ),
          child: Row(children: [
            BranchGlyph(branch: branch, lit: lit, size: AppSize.button),
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
            )),
            if (branch.latitude == null) ...[
              SizedBox(width: AppSize.gap),
              Icon(
                Icons.location_off_outlined,
                size: AppSize.text,
                color: scheme.text.secondary,
                semanticLabel: S.of(context).business_branch_no_point
              )
            ]
          ])
        )
      )
    );
  }
}
