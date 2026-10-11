import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A panel floating over the left side of a map that fills its sheet: the
/// side bar's fill, edge and rounding inside a translucent rim, so the map
/// still reads around it. The branches tab draws the same frame.
class MapPanel extends StatelessWidget {
  const MapPanel({super.key, required this.child});

  final Widget child;

  /// Share of the sheet's width the panel takes: more on smaller screens,
  /// where a quarter would not fit a row's text.
  static double _share(BuildContext context) {
    final device = Responsive.of(context);

    if (device.isPhone) return 0.36;
    if (device.isTablet) return 0.3;
    return 0.25;
  }

  /// Below this a share leaves the rows too narrow to read, so the panel
  /// stops shrinking there.
  static double get _minWidth => AppSize.action * 6.5;

  /// The panel's width over a sheet [sheet] wide: its share, never under
  /// [_minWidth], and never wider than the sheet minus its margins.
  static double width(BuildContext context, double sheet) {
    final room = sheet - AppSize.spaceS * 2;
    final width = sheet * _share(context);

    if (width < _minWidth) return _minWidth.clamp(0, room < 0 ? 0 : room);
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.all(AppSize.gap),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSize.spaceS)
      ),
      child: Container(
        padding: EdgeInsets.all(AppSize.padding),
        decoration: BoxDecoration(
          color: scheme.navBar,
          border: Border.all(color: scheme.line),
          borderRadius: BorderRadius.circular(AppSize.spaceS)
        ),
        child: child
      )
    );
  }
}
