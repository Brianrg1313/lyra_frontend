import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';

/// A branch's mark, shared by its row and its pin so both read as the same
/// thing: the yellow star on the main one, else shop or warehouse. Pointed
/// at, it takes the primary color.
///
/// The star is a Material icon: the app's icon font has none.
class BranchGlyph extends StatelessWidget {
  const BranchGlyph({super.key, required this.branch, required this.lit, required this.size});

  final BusinessBranchModel branch;
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: lit ? scheme.primary : scheme.surfaceOver,
        shape: BoxShape.circle
      ),
      child: Center(child: branch.main
        ? Icon(
            Icons.star_rounded,
            size: size * 0.6,
            color: lit ? scheme.button.text : scheme.chart.warning,
            semanticLabel: S.of(context).business_branch_main
          )
        : Icon(
            branch.storefront ? CI.store : CI.warehouse,
            size: size * 0.5,
            color: lit ? scheme.button.text : scheme.icon
          ))
    );
  }
}
