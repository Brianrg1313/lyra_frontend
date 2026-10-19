import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';

import './sheet_controller.dart';
import './sheet_selection.dart';

/// What the cells' menu acts on: the range right-clicked (or the one cell) and the type of
/// each of its columns, left to right.
class SheetTarget {
  const SheetTarget({required this.range, required this.types});

  final SheetRange range;
  final List<TableFieldType> types;

  /// Whether every column of the range is one of [types].
  bool only(Set<TableFieldType> types) => this.types.every(types.contains);
}

/// One entry of the cells' menu (right click on a cell or a range).
///
/// A general action has no [types] and is offered on any cell; a type's one names the types
/// it is for, and is offered only when every column of the target is one of them (a range
/// across a price and a date gets the general ones only). [shown] narrows it further, from
/// the sheet's state (undo only with something to undo).
///
/// An action that writes several cells writes them inside `history.group`, so one Ctrl+Z
/// takes it all back (see [SheetHistory.group]).
class SheetAction {
  const SheetAction({
    required this.id,
    required this.label,
    required this.run,
    this.icon,
    this.types,
    this.shown
  });

  /// The menu's value for it; never stored nor sent.
  final String id;

  final String Function(BuildContext context) label;
  final IconData? icon;

  /// The column types it is for; `null`: every one.
  final Set<TableFieldType>? types;

  final bool Function(SheetController sheet, SheetTarget target)? shown;
  final void Function(SheetController sheet, SheetTarget target) run;

  bool offers(SheetController sheet, SheetTarget target) {
    final types = this.types;
    if (types != null && !target.only(types)) return false;

    return shown?.call(sheet, target) ?? true;
  }
}

/// The cells' menu, in the order it shows: the general actions, then the types' ones.
final List<SheetAction> sheetActions = [
  SheetAction(
    id: "undo",
    label: (context) => S.of(context).sheet_action_undo,
    icon: Icons.undo,
    shown: (sheet, _) => sheet.history.canUndo,
    run: (sheet, _) => sheet.undo()
  ),
  SheetAction(
    id: "redo",
    label: (context) => S.of(context).sheet_action_redo,
    icon: Icons.redo,
    shown: (sheet, _) => sheet.history.canRedo,
    run: (sheet, _) => sheet.redo()
  )
];
