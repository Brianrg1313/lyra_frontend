// SERVICES
import 'package:app/services/stock/tables/table_structure_model.dart';

import './free_column.dart';

/// A column of the spreadsheet: either a field of the table ([field]), or one
/// of the free columns at the end ([free]), which doesn't exist in the
/// backend yet.
///
/// Both are painted the same —a column is a column— and the only thing that
/// changes is that the free one has nowhere to store data until it gets a
/// title and is created.
class SheetColumn {
  const SheetColumn._(this.field, this.free);

  const SheetColumn.field(TableFieldModel field) : this._(field, null);
  const SheetColumn.free(FreeColumn free) : this._(null, free);

  final TableFieldModel? field;
  final FreeColumn? free;

  bool get isField => field != null;

  String get name => field?.name ?? free!.name;
  String get id => field?.id ?? "";

  /// Code of the field's type, or empty (which reads as text) if the column
  /// isn't a field yet.
  String get type => field?.type ?? "";

  /// The options of a list field. Empty in every other type and in a free
  /// column, which isn't yet a field they'd belong to.
  List<String> get options => field?.options ?? const [];

  /// The symbol with which the field's numbers are written (the currency of a
  /// price, the magnitude of a measure). Empty in types that don't carry one
  /// and in a free column.
  String get unit => field?.unit ?? "";

  /// `true` while the creation of this column is being sent.
  bool get creating => free?.creating ?? false;
}
