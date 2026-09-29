import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/business/business_location_model.dart';
import 'package:app/toolkit/api.dart';

enum BusinessLocationStatus { idle, loading, ready, error }

/// Where the active company is: `GET` / `PUT /business/location/`.
///
/// It is the main branch's location, which is the company's. Owned by whoever
/// draws the map on it (the deliveries section, the branch form), not
/// app-wide: the endpoint answers for the business in the `business_id`
/// header. It is edited as a branch (`BusinessBranchesService`).
///
/// A write rereads instead of patching what is in memory: the backend trims,
/// uppercases the postal code, rounds the point and builds the map link, so
/// what is shown is what was stored and not what was sent.
class BusinessLocationService extends ChangeNotifier {
  BusinessLocationStatus _status = BusinessLocationStatus.idle;
  BusinessLocationModel? _location;

  /// `true` while a write is in flight, so a second save cannot overlap it.
  bool _writing = false;

  bool _disposed = false;

  BusinessLocationStatus get status => _status;

  /// The location, or `null` until it is read.
  BusinessLocationModel? get location => _location;

  bool get isWriting => _writing;

  /// Reads the location. Without [force] it is read once per page.
  Future<void> load({bool force = false}) async {
    if (_status == BusinessLocationStatus.loading) return;
    if (!force && _status == BusinessLocationStatus.ready) return;

    _status = BusinessLocationStatus.loading;
    notifyListeners();

    final location = await _fetch();

    _location = location ?? _location;
    _status = location == null
      ? BusinessLocationStatus.error
      : BusinessLocationStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// Writes a body built by `updateLocationRequest` and rereads.
  ///
  /// Returns `true` if it went through — an empty body did, since there was
  /// nothing to write. On error the floating flag says why and the location
  /// is left as it was.
  Future<bool> update(BuildContext context, Map<String, dynamic> request) async {
    if (request.isEmpty) return true;
    if (_writing) return false;

    _writing = true;
    notifyListeners();

    try {
      await api.put(path: "/business/location/", version: "v1", data: request);
    } catch (error) {
      if (kDebugMode) print("updateLocation failed: $error");

      _writing = false;
      notifyListeners();

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty ? error : {"message": error.toString()}
        );
      }

      return false;
    }

    // Reread without going through `loading`: the sheet is on screen, and
    // swapping it for a spinner to rewrite a row is worse than a moment of the
    // old value. A failed reread is not reported — the write went through, and
    // a flag would say the opposite.
    final location = await _fetch();

    _writing = false;
    _location = location ?? _location;
    notifyListeners();

    return true;
  }

  Future<BusinessLocationModel?> _fetch() async {
    try {
      final data = await api.get(path: "/business/location/", version: "v1");

      return data is Map ? BusinessLocationModel.fromJson(data) : null;
    } catch (error) {
      if (kDebugMode) print("loadLocation failed: $error");

      return null;
    }
  }

  /// A read can answer after the page that asked for it is gone (a business
  /// switch remounts it), and notifying a disposed notifier throws.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
