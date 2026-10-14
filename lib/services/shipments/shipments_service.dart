import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show Grant;

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

enum ShipmentsStatus { idle, loading, ready, empty, error }

/// Which part of the board is on screen: what is still going, or what was
/// delivered.
enum ShipmentsView {
  going,
  delivered;

  /// `STATE` of the read: empty is the backend's default (every state but
  /// delivered).
  String get states => this == going ? "" : ShipmentState.delivered.code;

  bool holds(ShipmentState state) =>
    this == going ? state != ShipmentState.delivered : state == ShipmentState.delivered;
}

/// **The deliveries of the branch worked in** (`envios-frontend.md`), owned by
/// the deliveries desk.
///
/// Every route answers for the `branch_id` header's branch, so a branch switch
/// remounts the desk (the home keys its content by the branch) and drops what
/// was read. Cloud only — a master runs no deliveries board — so it calls
/// [api] itself.
///
/// A write answers the board's row, which replaces its own; `shipment/changed`
/// (to the branch, with the whole row) does the same, and `state: null` takes
/// the row off (it became a pickup). A dropped connection rereads on its way
/// back.
///
/// What the person may do is the catalog's (`shipments.dispatch`: assign,
/// schedule, move; `shipments.configure`: the branch's settings), read from
/// their own grant like the transfers: the app's areas have no door for these.
class ShipmentsService extends ChangeNotifier {
  ShipmentsService({PermissionsSource? permissions}) : _injectedPermissions = permissions;

  final PermissionsSource? _injectedPermissions;

  PermissionsSource get _permissions => _injectedPermissions ?? Sources.permissions;

  static const String changedEvent = "shipment/changed";

  ShipmentsStatus _status = ShipmentsStatus.idle;
  ShipmentsStatus get status => _status;

  ShipmentsView _view = ShipmentsView.going;
  ShipmentsView get view => _view;

  List<Shipment> _shipments = const [];
  List<Shipment> get shipments => _shipments;

  Map<ShipmentState, ShipmentStateInfo> _states = const {};

  /// The state's catalog entry, once read.
  ShipmentStateInfo? stateInfo(ShipmentState state) => _states[state];

  /// Where [shipment] may go from where it is (the catalog's `next`).
  List<ShipmentState> nextOf(Shipment shipment) => _states[shipment.state]?.next ?? const [];

  /// What the board says a state is called: the catalog's name, else the row's.
  String nameOf(ShipmentState state, {String fallback = ""}) =>
    _states[state]?.name.isNotEmpty == true ? _states[state]!.name : fallback;

  Grant _grant = Grant.none();
  bool get canDispatch => _grant.can("shipments.dispatch");
  bool get canConfigure => _grant.can("shipments.configure");

  /// Whether the person may change the branch's week and closed days
  /// (`appointments.configure`), which is where the franjas come from.
  bool get canSchedule => _grant.can("appointments.configure");

  ShipmentCarriers? _carriers;
  ShipmentCarriers? get carriers => _carriers;

  /// The id of the shipment a write is on, so its buttons wait.
  String? _busy;
  String? get busy => _busy;

  /// Shipments waiting on somebody of the company, among the ones on screen.
  int get attention => _shipments.where((row) => row.attention).length;

  /// A read is answered for the view it was asked with; one asked later wins.
  int _reads = 0;

  void Function()? _off;
  void Function()? _offRestored;
  bool _disposed = false;

  Shipment? byId(String id) {
    for (final row in _shipments) {
      if (row.id == id) return row;
    }
    return null;
  }

  Future<void> load() async {
    _off ??= ConnectionService().on(changedEvent, _onChanged);
    _offRestored ??= ConnectionService().onRestored(() => unawaited(_read()));

    unawaited(_readGrant());
    unawaited(_readStates());
    await _read();
  }

  /// Shows [view].
  Future<void> show(ShipmentsView view) async {
    if (view == _view && _status != ShipmentsStatus.error) return;

    _view = view;
    await _read();
  }

  Future<void> retry() => _read();

  /// Who can carry the branch's shipments, read once.
  Future<ShipmentCarriers> loadCarriers() async {
    final known = _carriers;
    if (known != null) return known;

    final carriers = ShipmentCarriers.read(await api.get(path: "/shipments/carriers/", version: "v1"));
    _carriers = carriers;

    return carriers;
  }

  /// The franjas the branch can still promise ([all]: the full ones too).
  Future<List<DeliverySlot>> windows({bool all = false}) async => DeliverySlot.list(await api.get(
    path: "/shipments/windows/",
    version: "v1",
    query: all ? {"ALL": "1"} : null
  ));

  /// Writes [body] (`shipmentStateRequest`, `editShipmentRequest`) and places
  /// the answer. Throws the backend's refusal.
  Future<Shipment?> move(Map<String, dynamic> body) async {
    if (_busy != null) return null;

    _busy = body["ID"]?.toString();
    _notify();

    try {
      final row = Shipment.read(await api.put(path: "/shipments/", version: "v1", data: body));
      if (row != null) _place(row);

      return row;
    } finally {
      _busy = null;
      _notify();
    }
  }

  Future<void> _read() async {
    final read = ++_reads;

    _status = ShipmentsStatus.loading;
    _notify();

    try {
      final states = _view.states;
      final data = await api.get(
        path: "/shipments/",
        version: "v1",
        query: states.isEmpty ? null : {"STATE": states}
      );

      if (read != _reads) return;

      _shipments = Shipment.list(data);
      _status = _shipments.isEmpty ? ShipmentsStatus.empty : ShipmentsStatus.ready;
    } catch (error) {
      if (read != _reads) return;
      if (kDebugMode) print("loadShipments failed: $error");

      _status = ShipmentsStatus.error;
    }

    _notify();
  }

  Future<void> _readStates() async {
    if (_states.isNotEmpty) return;

    try {
      _states = ShipmentStateInfo.catalog(await api.get(path: "/shipments/states/", version: "v1"));
      _notify();
    } catch (error) {
      if (kDebugMode) print("shipment states failed: $error");
    }
  }

  Future<void> _readGrant() async {
    try {
      _grant = await _permissions.mine();
      _notify();
    } catch (error) {
      if (kDebugMode) print("shipment grant failed: $error");
    }
  }

  /// A row from a write or an event: replaced in place, added when it is new
  /// to the view on screen, dropped when it no longer belongs to it.
  void _place(Shipment shipment) {
    final belongs = _view.holds(shipment.state);
    final index = _shipments.indexWhere((row) => row.id == shipment.id);

    if (index == -1) {
      if (!belongs) return;

      _shipments = _sorted([..._shipments, shipment]);
      _status = ShipmentsStatus.ready;
      return;
    }

    _shipments = _sorted([
      for (final row in _shipments)
        if (row.id != shipment.id) row else if (belongs) shipment
    ]);
    if (_shipments.isEmpty) _status = ShipmentsStatus.empty;
  }

  /// The backend's order: the ones with a window first, by its start; then the
  /// rest, oldest first. A window set or moved here reorders the row at once.
  static List<Shipment> _sorted(List<Shipment> rows) {
    int opened(Shipment row) => row.opened?.millisecondsSinceEpoch ?? 0;

    return rows..sort((a, b) {
      final left = a.window?.from;
      final right = b.window?.from;

      if (left != null && right != null && left != right) return left.compareTo(right);
      if (left != null && right == null) return -1;
      if (left == null && right != null) return 1;

      return opened(a).compareTo(opened(b));
    });
  }

  void _drop(String id) {
    final before = _shipments.length;

    _shipments = [for (final row in _shipments) if (row.id != id) row];
    if (_shipments.length != before && _shipments.isEmpty) _status = ShipmentsStatus.empty;
  }

  void _onChanged(dynamic data) {
    final left = Shipment.leftBoard(data);

    if (left != null) {
      _drop(left);
      _notify();
      return;
    }

    final shipment = Shipment.read(data);
    if (shipment == null) return;

    _place(shipment);
    _notify();
  }

  /// Seeds the board, for tests.
  @visibleForTesting
  void seed(
    List<Shipment> shipments, {
    ShipmentsView view = ShipmentsView.going,
    Map<ShipmentState, ShipmentStateInfo>? states,
    Grant? grant
  }) {
    _view = view;
    _shipments = shipments;
    _status = shipments.isEmpty ? ShipmentsStatus.empty : ShipmentsStatus.ready;
    if (states != null) _states = states;
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
