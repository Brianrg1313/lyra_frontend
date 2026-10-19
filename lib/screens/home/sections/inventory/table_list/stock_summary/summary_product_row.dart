import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

// WIDGETS
import 'package:app/screens/modals/inventory/branch_prices/_branch_prices.dart';
import 'package:app/screens/modals/inventory/stock_movement/movement_shape.dart';
import 'package:app/screens/modals/supply_chain/recipe/_recipe.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';

import './summary_layout.dart';
import './summary_line.dart';
import './summary_number.dart';
import './summary_picture.dart';
import './summary_stepper.dart';
import './summary_value.dart';

/// A row of the summary: a product.
///
/// It's read left to right as one looks for a product: the photo, with what
/// it's recognized by; the columns with which the company describes it; and at
/// the end the numbers, which are the question this list answers.
///
/// **The row isn't touched; its numbers are.** Stock and reserved carry their
/// two buttons (see [SummaryStepper]) and are the only thing of the row that
/// responds: what brings someone here is looking at how much is left and
/// correcting it on the spot, not opening the product. That the whole row were
/// a button, besides, left every movement one pixel away from going to another
/// screen.
///
/// **A made product's photo opens what it consumes** ([recipes], `cocina-frontend.md` §3: it is
/// part of the record). One made to order has no shelf: its stock figure is what its supplies
/// allow, with no buttons (the backend refuses to move it), and touching it says why («3 left —
/// because of the bacon») by opening it. One made by the batch keeps its shelf and its
/// buttons. A catalog product consumes nothing: its photo opens nothing.
class SummaryProductRow extends StatelessWidget {
  const SummaryProductRow({
    super.key,
    required this.row,
    required this.layout,
    required this.currency,
    this.zebra = false,
    this.recipes = false,
    this.recipe
  });

  /// Whether the row is a made product's, whose photo opens what it consumes.
  final bool recipes;

  /// What the product's recipe makes now; `null` when it has none.
  final RecipeAvailability? recipe;

  final StockSummaryRow row;
  final SummaryLayout layout;

  /// If this row goes on the zebra's painted band.
  ///
  /// The list decides it by position, not the row by what it brings: the zebra
  /// is there to follow a long row left to right without switching lines, and
  /// for that it has to alternate evenly.
  final bool zebra;

  /// The company's currency, already resolved. It comes down from the panel so
  /// all rows read it with a single subscription.
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      // The zebra, with the two colors the scheme has for that: any row goes
      // over `table.background` —which is the same background the section rests
      // on, so it doesn't look like a box— and the one next to it over
      // `table.even`, which exists precisely to distinguish it from its
      // neighbors. It's the same zebra as the spreadsheet (see `SheetStyle`):
      // opening a product's table shouldn't change the list's look.
      height: SummaryLayout.rowHeight,
      padding: SummaryLayout.rowPadding,
      decoration: BoxDecoration(
        color: zebra ? scheme.table.even : scheme.table.background,
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: SummaryLine(
        layout: layout,
        image: recipes
          ? FocusableWidget(
              action: () => _openRecipe(context),
              message: S.of(context).made_consumes_open,
              child: SummaryPicture(row: row)
            )
          : SummaryPicture(row: row),
        field: (column) => _priced(context, column)
          ? FocusableWidget(
              action: () => _openPrices(context, column),
              message: S.of(context).branch_prices_title,
              child: SummaryValue(column: column, raw: row[column.key], currency: currency)
            )
          : SummaryValue(
              column: column,
              raw: row[column.key],
              currency: currency
            ),
        number: (column) => _number(context, column)
      )
    );
  }

  /// A price opens what each branch sells the product at, where there are branches to tell
  /// apart (`inventory.prices`, cloud only): a number of the row, so it is touched like one.
  bool _priced(BuildContext context, StockSummaryColumn column) =>
    column.type == TableFieldType.price &&
    BranchService().choosable &&
    CapabilityService().shows("inventory.prices");

  /// How the row is named: its first text column with something written.
  String get _name => layout.fields
    .where((field) => field.type == TableFieldType.text)
    .map((field) => row[field.key]?.toString().trim() ?? "")
    .firstWhere((value) => value.isNotEmpty, orElse: () => "");

  /// What the made product consumes; written or paused there rereads the rows in view, so its
  /// figure is the backend's.
  Future<void> _openRecipe(BuildContext context) async {
    final service = context.read<StockSummaryService>();

    final changed = await showRecipePanel(
      context,
      product: KitchenProduct(id: row.id, tableId: service.table, name: _name, made: true)
    );

    if (changed) await service.syncColumns(service.table);
  }

  void _openPrices(BuildContext context, StockSummaryColumn column) {
    final raw = row[column.key];

    unawaited(showBranchPrices(
      context,
      productId: row.id,
      product: _name,
      tableId: context.read<StockSummaryService>().table,
      catalogPrice: raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? ""),
      currency: currency
    ));
  }

  /// One of the numbers columns.
  ///
  /// The two inventory ones are drawn with their buttons; performance, which
  /// isn't measured yet, is a figure and nothing more.
  ///
  /// The buttons need **both** numbers —a reservation's cap is set by stock,
  /// not by what's already reserved— so a row missing either falls to the bare
  /// figure. It doesn't happen today: the summary answers both counters in any
  /// table, whether or not it has a stock column.
  Widget _number(BuildContext context, StockSummaryColumn column) {
    final stock = row.stock;
    final reserved = row.reserved;
    final made = recipe;

    // A dish made to order: what its supplies allow, never empty nor moved by hand.
    if (made != null && made.mode == RecipeMode.order && column.isStock) {
      return FocusableWidget(
        action: () => _openRecipe(context),
        message: recipeAvailabilityLine(context, made),
        child: SummaryNumber(value: stock ?? made.available, alert: true, align: TextAlign.center)
      );
    }

    if (made != null && made.mode == RecipeMode.order && column.isReserved) {
      return SummaryNumber(value: reserved, align: TextAlign.center);
    }

    final counter = switch (column.key) {
      StockSummaryColumn.stockKey => StockCounter.stock,
      StockSummaryColumn.reservedKey => StockCounter.reserved,
      _ => null
    };

    if (counter == null || stock == null || reserved == null) {
      return SummaryNumber(
        value: switch (column.key) {
          StockSummaryColumn.stockKey => stock,
          StockSummaryColumn.reservedKey => reserved,
          StockSummaryColumn.transitKey => row.transit,
          // Performance isn't measured yet: the column is there, the value
          // isn't.
          _ => null
        },
        // Only stock alerts on zero: it's what can't be sold. Zero reserved is
        // normal in almost all products.
        alert: column.isStock
      );
    }

    return SummaryStepper(
      productId: row.id,
      counter: counter,
      stock: stock,
      reserved: reserved,
      product: _name,
      currency: currency,
      unit: row.unit
    );
  }
}
