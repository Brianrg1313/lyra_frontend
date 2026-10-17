// SERVICES
import 'package:app/services/stock/tables/table_view_model.dart';

// WIDGETS
import 'package:app/screens/modals/supply_chain/recipe/recipe_editor.dart';

/// What a sheet of a `made` table does apart (`cocina-frontend.md` §3): a record is written with
/// what it consumes, and a record's stock is what those allow, never moved by hand.
///
/// The section gives it (it owns the panels), the controller only calls it.
class SheetMade {
  const SheetMade({required this.consumesFor, required this.open});

  /// Asks what a row being created consumes ([name] is what it is called, or empty); `null`
  /// leaves the row written and unsaved.
  final Future<RecipeDraft?> Function(String name) consumesFor;

  /// Opens what [record] consumes: its lines, what it makes now, its 86.
  final Future<void> Function(TableRowModel record, String name) open;
}
