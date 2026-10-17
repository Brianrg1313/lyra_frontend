import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';

/// What the stock movement form (`showStockMovement`) writes through: the stock summary's
/// rows and the sheet's stock cells move a product the same way, each correcting its own
/// view with the balance the backend answers.
abstract interface class StockMover {
  /// Whether the product is a supply: moved with up to six decimals of its unit
  /// (`cocina-frontend.md` §1), a catalog's in whole units.
  bool get supplies;

  /// Writes [movement] on [productId]. `false` when it did not go in; the reason was
  /// already shown in the floating flag.
  Future<bool> move(BuildContext context, {required String productId, required StockMovement movement});

  /// How [productId] is bought, for a movement to count presentations; none on failure.
  Future<List<Presentation>> presentations(String productId);
}
