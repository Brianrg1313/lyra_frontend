import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// Sizes of a sheet. Every row puts its switch in the same slot, so the switches read as one
/// column down the panel.
abstract final class PermissionGrid {
  static double get cell => AppSize.text * 2.3;
  static double get inset => AppSize.spaceXS;

  /// Room left of an action for the thread that ties it to its section.
  static double get indent => inset + cell + AppSize.spaceS;
}
