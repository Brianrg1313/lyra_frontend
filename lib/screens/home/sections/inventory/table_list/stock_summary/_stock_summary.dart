import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';

import './summary_bar.dart';
import './summary_body.dart';

/// The stock summary of the open table: the section's view while the cells switch is off.
///
/// It owns the summary of [tableId] ([StockSummaryService]) and the section keys it by
/// the table, so picking another one reads another summary from the start.
///
/// **You touch here and not in the table.** Each row's two numbers carry their
/// buttons (see `SummaryStepper`): six came in, two were sold, three have to be
/// set aside. Tapping the row opens nothing, which was the old gesture and left
/// every movement one pixel away from going to another screen.
///
/// The column header stays fixed on top and the rows scroll below it: on row forty a
/// column of numbers says nothing without the title that says which is which.
///
/// **The header search box searches it** through the backend (`MATCH`): of a table with
/// hundreds of thousands of rows only a few pages are in memory. Hence the breather
/// ([_StockSummarySectionState._debounce]) between typing and reading.
class StockSummarySection extends StatefulWidget {
  const StockSummarySection({
    super.key,
    required this.tableId,
    required this.parts,
    this.supplies = false,
    this.status = const [],
    this.source
  });

  final String tableId;
  final InventoryBarParts parts;

  /// The table is one of supplies: its stock moves with decimals.
  final bool supplies;

  /// The summary's source; null reads `Sources.stock`. A seam for tests.
  final StockSource? source;

  /// What the section adds to the bar's status (an upload in flight).
  final List<Widget> status;

  @override
  State<StockSummarySection> createState() => _StockSummarySectionState();
}

class _StockSummarySectionState extends State<StockSummarySection> {
  late final _summary = StockSummaryService(
    source: widget.source,
    tableId: widget.tableId,
    supplies: widget.supplies,
    recipes: !widget.supplies && CapabilityService().shows("supply_chain.recipes")
  );

  late final ValueListenable<String> _query;

  /// Without it every letter would be a request —and the second-to-last could
  /// answer after the last—; with it, it reads once you stop typing.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery..addListener(_onSearch);

    // Loads notify their listeners; deferred to the first frame so a rebuild
    // isn't triggered while the tree is still being mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _summary.load(query: _query.value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onSearch);
    _summary.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _summary.search(_query.value)
    );
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StockSummaryService>.value(
    value: _summary,
    child: Surface(child: Column(children: [
      SummaryBar(parts: widget.parts, status: widget.status),
      Separator.horizontal(),
      const Expanded(child: SummaryBody())
    ]))
  );
}
