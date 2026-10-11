import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';

import './branch_glyph.dart';
import './branches_focus.dart';

/// The company's branches on the map, each a pin with the list's icon (the
/// star on the main one, else shop or warehouse); tapping one does what
/// tapping its row does. A branch without a point is not drawn.
///
/// The main branch is drawn here too, with its star: the tab hides the map's
/// own company mark, which stands on the same point and would not say which
/// branch it is.
class BranchMarkers extends StatelessWidget {
  const BranchMarkers({super.key, required this.onSelect});

  final void Function(BusinessBranchModel branch) onSelect;

  /// Room for a pin that shows its name; the pin itself is only as wide as
  /// it needs, the rest lets taps through to the map.
  static double get _width => AppSize.action * 5;
  static double get _height => AppSize.action * 1.4;

  @override
  Widget build(BuildContext context) {
    final branches = context.select<BusinessBranchesService, List<BusinessBranchModel>>(
      (service) => service.branches
    );
    final focus = context.watch<BranchesFocus>();

    // The pointed-at one goes last, so it is drawn over its neighbours.
    final drawn = [
      for (final branch in branches) if (!focus.lit(branch.id)) branch,
      for (final branch in branches) if (focus.lit(branch.id)) branch
    ];

    return MarkerLayer(
      markers: [
        for (final branch in drawn)
          if (branch case BusinessBranchModel(:final double latitude, :final double longitude))
            Marker(
              point: LatLng(latitude, longitude),
              width: _width,
              height: _height,
              alignment: Alignment.topCenter,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _BranchPin(
                  branch: branch,
                  lit: focus.lit(branch.id),
                  maxWidth: _width,
                  onHover: (inside) => focus.hover(branch.id, inside),
                  onTap: () => onSelect(branch)
                )
              )
            )
      ]
    );
  }
}

/// A tag over a stem that ends on the point. Pointed at, it opens to show
/// the branch's name: the map stays quiet until one is looked for.
class _BranchPin extends StatelessWidget {
  const _BranchPin({
    required this.branch,
    required this.lit,
    required this.maxWidth,
    required this.onHover,
    required this.onTap
  });

  final BusinessBranchModel branch;
  final bool lit;
  final double maxWidth;
  final void Function(bool inside) onHover;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : const Duration(milliseconds: 160);
    final edge = lit ? scheme.primary : scheme.line;
    final tile = AppSize.button * 0.8;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: FocusableWidget(
        action: onTap,
        message: branch.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: duration,
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: EdgeInsets.all(AppSize.gap * 0.5),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: edge, width: lit ? 2 : 1),
                borderRadius: BorderRadius.circular(tile),
                boxShadow: [BoxShadow(
                  color: scheme.background.withAlpha(140),
                  blurRadius: AppSize.gap
                )]
              ),
              child: AnimatedSize(
                duration: duration,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BranchGlyph(branch: branch, lit: lit, size: tile),
                    if (lit) ...[
                      SizedBox(width: AppSize.gap),
                      Flexible(child: TextSmall(branch.name, bold: true, ellipsis: true)),
                      SizedBox(width: AppSize.gap)
                    ]
                  ]
                )
              )
            ),
            Container(width: 2, height: AppSize.gap, color: edge),
            Container(
              width: AppSize.gap,
              height: AppSize.gap,
              decoration: BoxDecoration(
                color: lit ? scheme.primary : scheme.icon,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2)
              )
            )
          ]
        )
      )
    );
  }
}
