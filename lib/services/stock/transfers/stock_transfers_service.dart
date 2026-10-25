import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show Grant;

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_request.dart';
import 'package:app/toolkit/backend/deployment.dart';

enum StockTransfersStatus { idle, loading, ready, empty, error }

/// A product a transfer can carry: [available] is null when nobody counts its stock.
typedef TransferProduct = ({String id, String name, int? available, String table});

/// Which side of the transfers the page shows: what comes to the branch worked in, or what it
/// sent.
enum StockTransferSide {
  incoming,
  outgoing;

  /// `DIRECTION` of the search.
  String get direction => this == incoming ? "in" : "out";
}

/// The transfers of the branch worked in (`sedes-frontend.md` §6), owned by the transfers page.
///
/// One side at a time ([side]), narrowed to one [status] or not; the receiver's "on its way" is
/// incoming and `sent`, which is where the page opens. Every write answers the transfer, which
/// replaces its row; `transfer/changed` (to both branches) does the same, or rereads when the
/// row is new to this list.
///
/// What the person may do is the catalog's (`inventory.transfer`: draft, send, cancel;
/// `inventory.receive`), read once from their own grant in this branch: the app's areas have no
/// door for these, and hiding a button spares a refusal the backend would give anyway.
///
/// The lines carry product ids and SKUs, not names: [nameOf] reads them from the table's stock
/// summary (its first text column), once per table, at most [_namesPage] products.
class StockTransfersService extends ChangeNotifier {
  StockTransfersService({StockSource? source, PermissionsSource? permissions})
    : _injected = source, _injectedPermissions = permissions;

  final StockSource? _injected;
  final PermissionsSource? _injectedPermissions;

  StockSource get _source => _injected ?? Sources.stock;
  PermissionsSource get _permissions => _injectedPermissions ?? Sources.permissions;

  static const int _pageSize = 30;
  static const int _namesPage = 200;
  static const String changedEvent = "transfer/changed";

  StockTransfersStatus _status = StockTransfersStatus.idle;
  StockTransfersStatus get status => _status;

  StockTransferSide _side = StockTransferSide.incoming;
  StockTransferSide get side => _side;

  StockTransferStatus? _filter = StockTransferStatus.sent;
  StockTransferStatus? get filter => _filter;

  List<StockTransfer> _transfers = const [];
  List<StockTransfer> get transfers => _transfers;

  int _total = 0;
  int _page = 1;
  bool _loadingMore = false;

  bool get hasMore => _transfers.length < _total;
  bool get loadingMore => _loadingMore;

  Grant _grant = Grant.none();
  bool get canSend => _grant.can("inventory.transfer");
  bool get canReceive => _grant.can("inventory.receive");

  /// The id of the transfer a write is on, so its buttons wait.
  String? _busy;
  String? get busy => _busy;

  final Map<String, String> _names = {};
  final Set<String> _tablesRead = {};

  /// A read is answered for the filter it was asked with; one asked later wins.
  int _reads = 0;

  void Function()? _off;
  void Function()? _offRestored;
  bool _disposed = false;

  /// The branch worked in.
  String? get branch => BranchService().activeId;

  /// The other branches, where a transfer can go.
  List<String> get destinations =>
    [for (final row in BranchService().branches) if (row.id != branch) row.id];

  /// A product's name as its table's summary shows it, or empty.
  String nameOf(String productId) => _names[productId] ?? "";

  /// Remembers names a picker already read.
  void remember(Map<String, String> names) => _names.addAll(names);

  Future<void> load() async {
    _off ??= ConnectionService().on(changedEvent, _onChanged);
    _offRestored ??= ConnectionService().onRestored(() => unawaited(_read()));

    unawaited(_readGrant());
    await _read();
  }

  /// Shows [side], narrowed to [status] (null: every status).
  Future<void> show(StockTransferSide side, StockTransferStatus? status) async {
    if (side == _side && status == _filter && _status != StockTransfersStatus.error) return;

    _side = side;
    _filter = status;
    await _read();
  }

  Future<void> more() async {
    if (!hasMore || _loadingMore) return;

    _loadingMore = true;
    _notify();

    final read = _reads;

    try {
      final page = await _source.transfers(searchTransfersRequest(
        direction: _side.direction, status: _filter, page: _page + 1, size: _pageSize
      ));

      if (read != _reads) return;

      _page = page.page;
      _total = page.total;
      _transfers = [..._transfers, ...page.transfers];
      unawaited(_resolve(page.transfers));
    } catch (error) {
      if (kDebugMode) print("loadTransfers more failed: $error");
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  /// Drafts a transfer, or drafts and sends it. Answers it, or throws the backend's refusal (a
  /// send one line can't cover names that product, and the draft is kept).
  Future<StockTransfer> create(Map<String, dynamic> request) async {
    final transfer = await _source.createTransfer(request);
    await _read();

    return transfer;
  }

  /// Edits a draft (`editTransferRequest`). Throws the refusal.
  Future<void> edit(Map<String, dynamic> request) =>
    _write(request["ID"].toString(), () => _source.updateTransfer(request));

  /// Sends a draft: every line leaves the shelf, or none. Throws the refusal.
  Future<void> send(StockTransfer transfer) =>
    _write(transfer.id, () => _source.updateTransfer(transferActionRequest(transfer.id, send: true)));

  /// Drops a draft, or calls a sent one back to the shelf it left. Throws the refusal.
  Future<void> cancel(StockTransfer transfer) =>
    _write(transfer.id, () => _source.updateTransfer(transferActionRequest(transfer.id, send: false)));

  /// Counts a transfer in: [counted] are the lines that arrived short. Throws the refusal.
  Future<void> receive(StockTransfer transfer, Map<String, ({int received, StockShortage reason})> counted) =>
    _write(transfer.id, () => _source.receiveTransfer(receiveTransferRequest(transfer, counted)));

  Future<void> _write(String id, Future<StockTransfer> Function() call) async {
    if (_busy != null) return;

    _busy = id;
    _notify();

    try {
      _place(await call());
    } finally {
      _busy = null;
      _notify();
    }
  }

  Future<void> _read() async {
    final read = ++_reads;

    _status = StockTransfersStatus.loading;
    _notify();

    try {
      final page = await _source.transfers(searchTransfersRequest(
        direction: _side.direction, status: _filter, page: 1, size: _pageSize
      ));

      if (read != _reads) return;

      _page = page.page;
      _total = page.total;
      _transfers = page.transfers;
      _status = _transfers.isEmpty ? StockTransfersStatus.empty : StockTransfersStatus.ready;
      unawaited(_resolve(page.transfers));
    } catch (error) {
      if (read != _reads) return;
      if (kDebugMode) print("loadTransfers failed: $error");

      _status = StockTransfersStatus.error;
    }

    _notify();
  }

  Future<void> _readGrant() async {
    try {
      _grant = await _permissions.mine();
      _notify();
    } catch (error) {
      if (kDebugMode) print("transfer grant failed: $error");
    }
  }

  /// The answer of a write, or an event: its row replaced, or dropped when it no longer belongs
  /// to the list on screen.
  void _place(StockTransfer transfer) {
    final belongs = _belongs(transfer);
    final index = _transfers.indexWhere((row) => row.id == transfer.id);

    if (index == -1) {
      if (belongs) unawaited(_read());
      return;
    }

    _transfers = [
      for (final row in _transfers)
        if (row.id != transfer.id) row else if (belongs) transfer
    ];
    if (!belongs) _total = _total > 0 ? _total - 1 : 0;
    if (_transfers.isEmpty) _status = StockTransfersStatus.empty;
  }

  bool _belongs(StockTransfer transfer) {
    final mine = _side == StockTransferSide.outgoing ? transfer.from == branch : transfer.to == branch;

    return mine && (_filter == null || transfer.status == _filter);
  }

  void _onChanged(dynamic data) {
    final transfer = StockTransfer.read(data);
    if (transfer == null) return;

    _place(transfer);
    _notify();
  }

  /// Reads the names of [transfers]' products not known yet, from their tables' summaries.
  Future<void> _resolve(List<StockTransfer> transfers) async {
    final tables = {
      for (final transfer in transfers)
        if (transfer.lines.any((line) => !_names.containsKey(line.productId))) transfer.tableId
    }..removeAll(_tablesRead);

    for (final table in tables) {
      _tablesRead.add(table);

      try {
        final page = await _source.summary(page: 1, size: _namesPage, tableId: table);
        _names.addAll(productNames(page));
      } catch (error) {
        if (kDebugMode) print("transfer names failed: $error");
      }
    }

    if (tables.isNotEmpty) _notify();
  }

  /// Products of the primary table matching [match], to put on a transfer: what is free to
  /// send (stock less what is held) and the table they are rows of.
  Future<List<TransferProduct>> searchProducts(String match) async {
    final page = await _source.summary(page: 1, size: 20, match: match.trim());
    final names = productNames(page);
    _names.addAll(names);

    return [
      for (final row in page.rows) (
        id: row.id,
        name: names[row.id] ?? row.id,
        // The primary table is never one of supplies (`cocina-frontend.md` §2): whole units.
        available: row.stock == null ? null : (row.stock! - (row.reserved ?? 0)).toInt(),
        table: page.table
      )
    ];
  }

  /// Each row's name in a summary page: its first text column.
  static Map<String, String> productNames(StockSummaryPage page) {
    final column = page.columns.where((column) => !column.isImage && !column.isNumber).firstOrNull;
    if (column == null) return const {};

    return {
      for (final row in page.rows)
        if ((row.values[column.key]?.toString().trim() ?? "").isNotEmpty) row.id: row.values[column.key].toString().trim()
    };
  }

  /// Seeds the list, for tests.
  @visibleForTesting
  void seed(List<StockTransfer> transfers, {StockTransferSide side = StockTransferSide.incoming, StockTransferStatus? filter, Grant? grant}) {
    _side = side;
    _filter = filter;
    _transfers = transfers;
    _total = transfers.length;
    _status = transfers.isEmpty ? StockTransfersStatus.empty : StockTransfersStatus.ready;
    if (grant != null) _grant = grant;
    _notify();
  }

  /// An event, for tests.
  @visibleForTesting
  void receiveEvent(dynamic data) => _onChanged(data);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _off?.call();
    _offRestored?.call();
    super.dispose();
  }
}
