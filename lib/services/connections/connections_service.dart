import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/connections/connection_detail_model.dart';
import 'package:app/services/connections/connection_lite_model.dart';
import 'package:app/services/connections/connection_request.dart';
import 'package:app/toolkit/backend/api.dart';

/// Status of loading the connections listing (`GET /connections/`).
enum ConnectionsStatus { idle, loading, ready, empty, error }

/// The external accounts the business has connected: which service each one
/// is for, what it was named, whether it's ready to work, and how many bots
/// run on top of it.
///
/// A connection is **the account and its credentials**, nothing more: a
/// WhatsApp number, an Instagram profile, a Facebook page. What the account
/// answers is decided later, in the bots built on top of it, and that's why
/// this service knows nothing about roles, tables, or tools.
///
/// Concentrates the operations on connections: the listing the `connections`
/// section consumes, creation, editing, and deletion, plus reading the
/// detail of a single one, which is what reopens its form.
///
/// Not to be confused with `ConnectionService` (in `services/connection/`),
/// which is the socket: that one is *the* connection to the server, this is
/// *the* business's connections to outside services.
///
/// Writes keep the cache up to date without re-reading the listing, each in
/// its own way, with the same criterion as [TablesService]: creation
/// invalidates it (`idle`) because the new connection has to be fetched —
/// the backend assigns its id and computes whether it's ready —; deletion
/// corrects the row in memory, because what changed is already fully known
/// on this side. Editing also invalidates: if the configuration was
/// touched, **whether it ended up ready or not is decided by the backend**
/// by comparing it against what that service requires, and that can't be
/// guessed here.
///
/// The detail isn't cached. It's the only thing that carries the
/// configuration, it's read when a connection is opened and discarded on
/// exit: keeping it in memory would mean holding on to account ids and hosts
/// of an account nobody's looking at anymore.
///
/// The listing cache is per business: connections travel tied to the active
/// business (the `business_id` header that [useBusiness] sets), so the
/// listing reloads on its own when the business changes. That's why [load]
/// receives the business id instead of inferring it, same as with tables.
class ConnectionsService extends ChangeNotifier {
  ConnectionsStatus _status = ConnectionsStatus.idle;
  List<ConnectionLiteModel> _connections = const [];

  /// Business the current cache was loaded for. If it doesn't match the
  /// active one, [load] refreshes even if the cache is `ready`.
  String? _businessId;

  ConnectionsStatus get status => _status;
  List<ConnectionLiteModel> get connections => List.unmodifiable(_connections);

  /// Loads the connections for [businessId].
  ///
  /// It's cached: coming back to the section doesn't hit the backend again
  /// unless [force] is requested, the active business changes, or a write
  /// has invalidated the cache leaving the status at `idle`.
  ///
  /// A business change always takes priority: it isn't held back by a read
  /// in progress (which belongs to the previous business) or by a `ready`
  /// cache (same reason), and what was loaded is dropped immediately so no
  /// one ever sees the other business's accounts while this one's are still
  /// arriving.
  Future<void> load(String businessId, {bool force = false}) async {
    final changed = _businessId != businessId;

    if (!changed) {
      if (_status == ConnectionsStatus.loading) return;
      if (!force && _status == ConnectionsStatus.ready) return;
    }

    if (changed) _connections = const [];

    _businessId = businessId;
    _status = ConnectionsStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/connections/", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadConnections failed: $error");
        return null;
      });

    // The business changed while the read was in flight: what arrived
    // belongs to the previous one. It's discarded entirely, including the
    // error, because the read that counts is the one the change triggered
    // and that one is already on its way.
    if (_businessId != businessId) return;

    if (data == null) {
      _status = ConnectionsStatus.error;
      notifyListeners();
      return;
    }

    _connections = ConnectionLiteModel.fromResponse(data);
    _status = _connections.isEmpty
      ? ConnectionsStatus.empty
      : ConnectionsStatus.ready;

    notifyListeners();
  }

  /// Reads a connection in full (`GET /connections/detail/:CONNECTION_ID`):
  /// its configuration, which secrets it already has saved — by name, never
  /// their value —, what it's missing to be able to work, and which jobs
  /// already have a bot. It also brings its provider's description, so this
  /// single read is enough to draw the form.
  ///
  /// Returns `null` if it failed, having already shown the error: whoever
  /// calls it shows its "couldn't open" screen and offers a retry.
  Future<ConnectionDetailModel?> detail(
    BuildContext context,
    String id
  ) async {
    if (id.isEmpty) return null;

    try {
      // No trailing slash: the id is a route segment (`params:
      // ["CONNECTION_ID"]`), and an extra slash would leave it empty on the
      // other side.
      final response = await api.get(
        path: "/connections/detail/$id",
        version: "v1"
      );

      if (response is! Map) return null;

      return ConnectionDetailModel.fromJson(response);
    } catch (error) {
      if (kDebugMode) print("loadConnection failed: $error");

      if (context.mounted) _report(context, error);

      return null;
    }
  }

  /// Creates a connection against `POST /connections/`.
  ///
  /// Returns the created connection's id. On error it shows the floating
  /// flag and rethrows, so the screen can turn off its loading state.
  ///
  /// On success it invalidates the listing cache (`idle`) so the next read
  /// brings back the new account with the `ready` the backend computed.
  Future<String> create(
    BuildContext context,
    Map<String, dynamic> data
  ) async {
    try {
      final response = await api.post(
        path: "/connections/",
        version: "v1",
        data: data
      );

      final id = _readId(response);

      _status = ConnectionsStatus.idle;

      return id;
    } catch (error) {
      // The error is always logged, even when it's shown on screen: the
      // text that reaches the screen is often trimmed and this keeps the
      // raw version.
      if (kDebugMode) print("createConnection failed: $error");

      if (context.mounted) _report(context, error);

      rethrow;
    }
  }

  /// Edits a connection against `PUT /connections/`.
  ///
  /// The cache is invalidated instead of being corrected in memory, unlike
  /// with tables, and for a concrete reason: an edit can complete (or empty
  /// out) the configuration, and whether the account ended up ready is
  /// resolved by the backend against what that service requires. Rewriting
  /// the row here would mean guessing at that `ready`.
  ///
  /// Returns `true` if the change went through. On error it shows the
  /// floating flag and returns `false`, with the connection left as it was.
  Future<bool> edit(BuildContext context, Map<String, dynamic> data) async {
    try {
      await api.put(
        path: "/connections/",
        version: "v1",
        data: data
      );
    } catch (error) {
      if (kDebugMode) print("editConnection failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _status = ConnectionsStatus.idle;

    return true;
  }

  /// Changes only a connection's switch (`ENABLED`), without touching
  /// anything else.
  ///
  /// It's the only change that does correct the row in memory: pausing an
  /// account doesn't change its configuration, so its `ready` stays the same
  /// and there's nothing to go fetch. The row updates instantly and the
  /// change travels behind it; if it fails, it's set back the way it was.
  ///
  /// It's also what should be offered instead of deletion when what's
  /// wanted is for the account to stop answering: pausing it loses neither
  /// the credentials nor the bots running on top of it.
  Future<bool> toggle(
    BuildContext context,
    ConnectionLiteModel connection
  ) async {
    if (connection.id.isEmpty) return false;

    final enabled = !connection.enabled;

    _replace(connection.id, (current) => current.copyWith(enabled: enabled));

    try {
      await api.put(
        path: "/connections/",
        version: "v1",
        data: {"ID": connection.id, "ENABLED": enabled}
      );
    } catch (error) {
      if (kDebugMode) print("toggleConnection failed: $error");

      _replace(connection.id, (current) => current.copyWith(
        enabled: connection.enabled
      ));

      if (context.mounted) _report(context, error);

      return false;
    }

    return true;
  }

  /// Deletes a connection against `DELETE /connections/`.
  ///
  /// It takes down its credentials **and the bots that were answering
  /// through it**, so whoever calls this has to have confirmed it
  /// beforehand: the service doesn't ask. The account it occupied is freed
  /// and can be connected again, but only by configuring it from scratch.
  ///
  /// The cache is corrected on the spot — the row is removed — instead of
  /// being invalidated: the deleted connection is the only thing that
  /// changed, so it disappears from the listing without the listing
  /// flickering through a reload.
  Future<bool> remove(
    BuildContext context,
    ConnectionLiteModel connection
  ) async {
    if (connection.id.isEmpty) return false;

    try {
      await api.delete(
        path: "/connections/",
        version: "v1",
        data: deleteConnectionRequest(id: connection.id)
      );
    } catch (error) {
      if (kDebugMode) print("deleteConnection failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    final remaining = _connections
      .where((current) => current.id != connection.id)
      .toList();

    // Nothing to remove: the cache no longer was the one holding this
    // connection (the business changed, or the listing reloaded while the
    // deletion was in flight).
    if (remaining.length == _connections.length) return true;

    _connections = remaining;

    // The status follows what's left: with no connections, the listing has
    // to show its empty message and not a blank list.
    if (_status == ConnectionsStatus.ready && _connections.isEmpty) {
      _status = ConnectionsStatus.empty;
    }

    notifyListeners();

    return true;
  }

  /// Empties the cache. Called on sign-out, along with the rest of the
  /// session's services.
  void clear() {
    _connections = const [];
    _status = ConnectionsStatus.idle;
    _businessId = null;
    notifyListeners();
  }

  /// Rewrites a row in the cache, if it's still there.
  ///
  /// The connection may have gone away while a change was in flight (a
  /// business change, a reload): in that case there's nothing to correct
  /// and whatever gets read afterward will already come back right.
  void _replace(
    String id,
    ConnectionLiteModel Function(ConnectionLiteModel current) change
  ) {
    final index = _connections.indexWhere((current) => current.id == id);
    if (index < 0) return;

    _connections = List<ConnectionLiteModel>.from(_connections)
      ..[index] = change(_connections[index]);

    notifyListeners();
  }

  /// Shows an error from an operation on the connections.
  ///
  /// It never fails silently: if the error doesn't carry anything showable,
  /// it still warns. An `action` is a navigation instruction (for example,
  /// an expired session): it's rethrown as-is so whoever should handle it
  /// does, so this call may not return.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Reads the connection's identifier from the creation response, which
  /// returns it bare (`"a1b2..."`) though a wrapped form is also handled
  /// just in case.
  String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["connection_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The connection was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The connection was not created (empty response)"};
    }

    return response.toString();
  }
}
