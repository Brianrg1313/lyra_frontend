import 'package:flutter/material.dart';

import './sheet_style.dart';

/// Passes the [SheetStyle] down to all the cells.
///
/// It is an [InheritedWidget] and not a provider because it never changes while
/// the sheet is open: it is only redone if the theme changes, and then
/// `SchemeColor` is another instance. Comparing by identity is enough and is the
/// cheapest there is.
class SheetTheme extends InheritedWidget {
  const SheetTheme({super.key, required this.style, required super.child});

  final SheetStyle style;

  static SheetStyle of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SheetTheme>()!.style;

  @override
  bool updateShouldNotify(SheetTheme old) =>
    !identical(old.style.scheme, style.scheme) ||
    old.style.rowHeight != style.rowHeight;
}
