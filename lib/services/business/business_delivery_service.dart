import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/toolkit/api.dart';

enum BusinessDeliveryStatus { idle, loading, ready, error }

/// Whether, how and where the active company delivers
/// (`/business/delivery/`, `/business/delivery/options/`) and the carriers it
/// may pick from (`/business/delivery/providers/`).
///
/// Provided by the delivery settings page (`DeliverySettingsSection`), not
/// app-wide: every endpoint answers for the business in the `business_id`
/// header, and a business switch remounts the page.
///
/// Every write rereads the whole answer instead of patching it: `delivers` is
/// measured on read (a company with options that never said reads `true`),
/// and an option is stored as the backend composed it — the carrier decides
/// the mode, a reach off local drops the zones.
class BusinessDeliveryService extends ChangeNotifier {
  BusinessDeliveryStatus _status = BusinessDeliveryStatus.idle;
  BusinessDeliveryModel? _delivery;
  DeliveryCatalog? _catalog;

  /// `true` while a write is in flight, so two cannot overlap.
  bool _writing = false;

  bool _disposed = false;

  BusinessDeliveryStatus get status => _status;

  /// The delivery answer, or `null` until it is read.
  BusinessDeliveryModel? get delivery => _delivery;

  /// The carrier catalog, or `null` while it was not read — or could not be.
  DeliveryCatalog? get catalog => _catalog;

  bool get isWriting => _writing;

  /// Reads the delivery answer. Without [force] it is read once per page.
  Future<void> load({bool force = false}) async {
    if (_status == BusinessDeliveryStatus.loading) return;
    if (!force && _status == BusinessDeliveryStatus.ready) return;

    _status = BusinessDeliveryStatus.loading;
    notifyListeners();

    final delivery = await _fetch();

    _delivery = delivery ?? _delivery;
    _status = delivery == null
      ? BusinessDeliveryStatus.error
      : BusinessDeliveryStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// Reads the carrier catalog.
  ///
  /// It is asked for by the form and not by the tab: the list of options
  /// draws itself from what it has —each row carries its carrier's name— and
  /// the catalog is only needed when somebody adds or edits one.
  ///
  /// A failure is silent on purpose: the form says the list is missing and
  /// still lets the company name its carrier, instead of the whole tab going
  /// down for something the list does not need.
  Future<void> loadCatalog({bool force = false}) async {
    if (!force && _catalog != null) return;

    try {
      final data = await api.get(
        path: "/business/delivery/providers/",
        version: "v1"
      );

      if (data is Map) _catalog = DeliveryCatalog.fromJson(data);
    } catch (error) {
      if (kDebugMode) print("loadDeliveryProviders failed: $error");

      return;
    }

    notifyListeners();
  }

  /// Sets one of the yes/no settings; `null` is "has not said".
  Future<bool> setFlag(BuildContext context, DeliveryFlag flag, bool? value) =>
    _write(context, () => api.put(
      path: "/business/delivery/",
      version: "v1",
      data: deliveryFlagRequest(flag, value)
    ));

  /// Sets whether its delivery areas are fixed or flexible (meet a customer
  /// outside them at the nearest spot it reaches).
  Future<bool> setMeeting(BuildContext context, bool value) =>
    _write(context, () => api.put(
      path: "/business/delivery/",
      version: "v1",
      data: deliveryMeetingRequest(value)
    ));

  /// Sets the company's sentence about delivery; empty erases it.
  Future<bool> setNotes(BuildContext context, String notes) =>
    _write(context, () => api.put(
      path: "/business/delivery/",
      version: "v1",
      data: deliveryNotesRequest(notes)
    ));

  /// Adds a way of delivering, from `createDeliveryOptionRequest`.
  Future<bool> createOption(BuildContext context, Map<String, dynamic> request) =>
    _write(context, () => api.post(
      path: "/business/delivery/options/",
      version: "v1",
      data: request
    ));

  /// Edits one, from `updateDeliveryOptionRequest`.
  Future<bool> updateOption(BuildContext context, Map<String, dynamic> request) =>
    _write(context, () => api.put(
      path: "/business/delivery/options/",
      version: "v1",
      data: request
    ));

  /// Removes one. Whoever calls it has already asked for confirmation.
  Future<bool> removeOption(BuildContext context, String id) =>
    _write(context, () => api.delete(
      path: "/business/delivery/options/",
      version: "v1",
      data: removeDeliveryOptionRequest(id)
    ));

  /// The common body of every write: hold the lock, send it, report a
  /// failure in the floating flag, and reread.
  ///
  /// The reread does not go through `loading`: the sheet is on screen, and
  /// swapping it for a spinner to rewrite one row is worse than a moment of
  /// the old value. A failed reread is not reported — the write went through.
  Future<bool> _write(
    BuildContext context,
    Future<dynamic> Function() call
  ) async {
    if (_writing) return false;

    _writing = true;
    notifyListeners();

    try {
      await call();
    } catch (error) {
      if (kDebugMode) print("deliveryWrite failed: $error");

      _writing = false;
      notifyListeners();

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty ? error : {"message": error.toString()}
        );
      }

      return false;
    }

    final delivery = await _fetch();

    _writing = false;
    _delivery = delivery ?? _delivery;
    notifyListeners();

    return true;
  }

  Future<BusinessDeliveryModel?> _fetch() async {
    try {
      final data = await api.get(path: "/business/delivery/", version: "v1");

      return data is Map ? BusinessDeliveryModel.fromJson(data) : null;
    } catch (error) {
      if (kDebugMode) print("loadDelivery failed: $error");

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
