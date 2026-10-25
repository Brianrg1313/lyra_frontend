import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_request.dart';
import 'package:app/toolkit/backend/api.dart';

/// Status of the channel list load (`GET /channels/`).
enum ChannelsStatus { idle, loading, ready, empty, error }

/// The active company's communication channels: which networks its account is
/// connected to, what each connection is called and in what order they are
/// shown.
///
/// It concentrates the operations on the channels: the list consumed by the
/// `channels` section, the creation, the edit and the deletion, plus reading a
/// single channel's detail, which is what reopens its form.
///
/// The writes keep the cache up to date without rereading the list, each one
/// in its own way, with the same criterion as [TablesService]: the creation
/// invalidates it (`idle`) because the new channel has to be fetched —the
/// backend gives it the id and computes whether it ended up ready—; the
/// deletion corrects the row in memory, because what changed is already known
/// in full on this side. The edit also invalidates: if the configuration was
/// touched, **whether it ended up ready is decided by the backend** comparing
/// against what that network asks for, and that cannot be guessed here.
///
/// The detail is not cached. It is the only thing that brings the
/// configuration, it is read when opening a channel and discarded when leaving
/// it: keeping it in memory would be storing account ids and hosts of a channel
/// nobody is looking at anymore.
///
/// The list cache is per company: the channels travel tied to the active
/// company (the `business_id` header that [useBusiness] sets), so when changing
/// company the list reloads on its own. That is why [load] receives the
/// company id and does not deduce it, just like in the tables.
class ChannelsService extends ChangeNotifier {
  ChannelsStatus _status = ChannelsStatus.idle;
  List<ChannelLiteModel> _channels = const [];

  /// Company for which the current cache was loaded. If it does not match the
  /// active one, [load] refreshes even if the cache is `ready`.
  String? _businessId;

  ChannelsStatus get status => _status;
  List<ChannelLiteModel> get channels => List.unmodifiable(_channels);

  /// Loads the channels of [businessId].
  ///
  /// It is cached: returning to the section does not hit the backend again
  /// unless [force] is requested, the active company changes, or a write
  /// invalidated the cache leaving the state in `idle`.
  ///
  /// A company change always wins: it is not stopped by an ongoing read (which
  /// belongs to the previous company) nor by a `ready` cache (same), and what
  /// was loaded is released on the spot so nobody ends up seeing the other
  /// company's channels while this one's arrive.
  Future<void> load(String businessId, {bool force = false}) async {
    final changed = _businessId != businessId;

    if (!changed) {
      if (_status == ChannelsStatus.loading) return;
      if (!force && _status == ChannelsStatus.ready) return;
    }

    if (changed) _channels = const [];

    _businessId = businessId;
    _status = ChannelsStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/channels/", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadChannels failed: $error");
        return null;
      });

    // While the read was in flight the company changed: what arrived belongs
    // to the previous one. It is discarded entirely, including the error,
    // because the read that matters is the one that triggered the change and it
    // is already on its way.
    if (_businessId != businessId) return;

    if (data == null) {
      _status = ChannelsStatus.error;
      notifyListeners();
      return;
    }

    _channels = ChannelLiteModel.fromResponse(data);
    _status = _channels.isEmpty ? ChannelsStatus.empty : ChannelsStatus.ready;

    notifyListeners();
  }

  /// Reads a whole channel (`GET /channels/detail/:ID`): its
  /// configuration, which secrets it already has stored —by name, never their
  /// value— and what it needs to work. It also brings its provider's
  /// description, so with this single read the form is drawn.
  ///
  /// Returns `null` if it failed, having shown the error: whoever calls it
  /// shows its "could not open" screen and offers to retry.
  Future<ChannelDetailModel?> detail(BuildContext context, String id) async {
    if (id.isEmpty) return null;

    try {
      // No trailing slash: the id is a route segment (`params:
      // ["CHANNEL_ID"]`), and an extra slash would leave it empty on the other
      // side.
      final response = await api.get(
        path: "/channels/detail/$id",
        version: "v1"
      );

      if (response is! Map) return null;

      return ChannelDetailModel.fromJson(response);
    } catch (error) {
      if (kDebugMode) print("loadChannel failed: $error");

      if (context.mounted) _report(context, error);

      return null;
    }
  }

  /// Creation of a channel against `POST /channels/`.
  ///
  /// Returns the id of the created channel. On an error it shows the floating
  /// flag and rethrows, so the screen turns off its loading state.
  ///
  /// When it ends well it invalidates the list cache (`idle`) so the next read
  /// brings the new channel with the `ready` the backend computed.
  Future<String> create(
    BuildContext context,
    Map<String, dynamic> data
  ) async {
    try {
      final response = await api.post(
        path: "/channels/",
        version: "v1",
        data: data
      );

      final id = _readId(response);

      _status = ChannelsStatus.idle;

      return id;
    } catch (error) {
      // The error is always logged, also when it is shown: the text that
      // reaches the screen is usually truncated and the raw one stays here.
      if (kDebugMode) print("createChannel failed: $error");

      if (context.mounted) _report(context, error);

      rethrow;
    }
  }

  /// Edit of a channel against `PUT /channels/`.
  ///
  /// The cache is invalidated instead of being corrected in memory, the
  /// opposite of the tables, and for a concrete reason: an edit can complete
  /// (or empty) the configuration, and whether the channel ended up ready is
  /// resolved by the backend against what that network asks for. Rewriting the
  /// row here would be guessing that `ready`.
  ///
  /// Returns `true` if the change went well. On an error it shows the floating
  /// flag and returns `false`, with the channel as it was.
  Future<bool> edit(BuildContext context, Map<String, dynamic> data) async {
    try {
      await api.put(
        path: "/channels/",
        version: "v1",
        data: data
      );
    } catch (error) {
      if (kDebugMode) print("editChannel failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _status = ChannelsStatus.idle;

    return true;
  }

  /// Changes only a channel's switch (`ENABLED`), without touching anything
  /// else.
  ///
  /// It is the only change that does correct the row in memory: pausing a
  /// channel does not change its configuration, so its `ready` stays the same
  /// and there is nothing to go fetch. The row is updated instantly and the
  /// change travels behind; if it fails, it is put back as it was.
  Future<bool> toggle(BuildContext context, ChannelLiteModel channel) async {
    if (channel.id.isEmpty) return false;

    final enabled = !channel.enabled;

    _replace(channel.id, (current) => current.copyWith(enabled: enabled));

    try {
      await api.put(
        path: "/channels/",
        version: "v1",
        data: {"ID": channel.id, "ENABLED": enabled}
      );
    } catch (error) {
      if (kDebugMode) print("toggleChannel failed: $error");

      _replace(channel.id, (current) => current.copyWith(
        enabled: channel.enabled
      ));

      if (context.mounted) _report(context, error);

      return false;
    }

    return true;
  }

  /// Deletion of a channel against `DELETE /channels/`.
  ///
  /// It takes its credentials with it, so whoever calls it must have confirmed
  /// it before: the service does not ask. The account it was using becomes
  /// free and can be reconnected, but by configuring it anew.
  ///
  /// The cache is corrected on the spot —the row is removed— instead of being
  /// invalidated: the deleted channel is the only thing that changed, and so
  /// it disappears from the list without it flickering while loading again.
  Future<bool> remove(BuildContext context, ChannelLiteModel channel) async {
    if (channel.id.isEmpty) return false;

    try {
      await api.delete(
        path: "/channels/",
        version: "v1",
        data: deleteChannelRequest(id: channel.id)
      );
    } catch (error) {
      if (kDebugMode) print("deleteChannel failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    final remaining = _channels
      .where((current) => current.id != channel.id)
      .toList();

    // Nothing to remove: the cache was no longer the one that had this channel
    // (the company changed, or the list reloaded while the deletion was in
    // flight).
    if (remaining.length == _channels.length) return true;

    _channels = remaining;

    // The state follows what is left: without channels, the list has to show
    // its empty message and not a blank list.
    if (_status == ChannelsStatus.ready && _channels.isEmpty) {
      _status = ChannelsStatus.empty;
    }

    notifyListeners();

    return true;
  }

  /// Empties the cache. Called on sign out, together with the rest of the
  /// session services.
  void clear() {
    _channels = const [];
    _status = ChannelsStatus.idle;
    _businessId = null;
    notifyListeners();
  }

  /// Rewrites a cache row, if it is still there.
  ///
  /// The channel may have gone while a change was in flight (a company change,
  /// a reload): then there is nothing to correct and what is read later already
  /// comes right.
  void _replace(
    String id,
    ChannelLiteModel Function(ChannelLiteModel current) change
  ) {
    final index = _channels.indexWhere((current) => current.id == id);
    if (index < 0) return;

    _channels = List<ChannelLiteModel>.from(_channels)
      ..[index] = change(_channels[index]);

    notifyListeners();
  }

  /// Shows an error of an operation on the channels.
  ///
  /// It never fails silently: if the error does not bring anything displayable,
  /// it still warns. An `action` is a navigation instruction (for example, an
  /// expired session): it is rethrown as is so the one in charge handles it,
  /// so this call may not return.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Reads the channel id from the creation response, which returns it bare
  /// (`"a1b2..."`) although wrapped is also considered, just in case.
  String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["channel_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The channel was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The channel was not created (empty response)"};
    }

    return response.toString();
  }
}
