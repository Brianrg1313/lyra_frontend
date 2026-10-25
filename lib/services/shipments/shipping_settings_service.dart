import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipment_request.dart';
import 'package:app/toolkit/backend/api.dart';

enum ShippingSettingsStatus { idle, loading, ready, error }

/// **How the branch worked in schedules its deliveries** (`envios-frontend.md`
/// §6, §7): its settings, the franjas they cut from its week, and what the bot
/// would offer a customer today. Owned by the panel that edits them; cloud
/// only, like the board.
///
/// The franjas and the offer are measured, never stored: they are read again
/// after every write here or to the week, so the panel shows what a customer
/// would actually be told.
class ShippingSettingsService extends ChangeNotifier {
  ShippingSettingsStatus _status = ShippingSettingsStatus.idle;
  ShippingSettingsStatus get status => _status;

  ShippingSettings _settings = const ShippingSettings();
  ShippingSettings get settings => _settings;

  List<DeliverySlot> _slots = const [];

  /// The franjas of the days ahead, the full ones too.
  List<DeliverySlot> get slots => _slots;

  List<DeliveryOffer> _offer = const [];
  List<DeliveryOffer> get offer => _offer;

  /// The refusal of the franjas' read (`business_has_no_timezone`), or null.
  String? _slotsError;
  String? get slotsError => _slotsError;

  bool _writing = false;
  bool get writing => _writing;

  bool _disposed = false;

  Future<void> load() async {
    _status = ShippingSettingsStatus.loading;
    _notify();

    try {
      _settings = ShippingSettings.read(await api.get(path: "/shipments/settings/", version: "v1"));
      _status = ShippingSettingsStatus.ready;
    } catch (error) {
      if (kDebugMode) print("loadShippingSettings failed: $error");
      _status = ShippingSettingsStatus.error;
    }

    _notify();
    if (_status == ShippingSettingsStatus.ready) await measure();
  }

  /// Reads the franjas and the offer again.
  Future<void> measure() async {
    try {
      final answers = await Future.wait([
        api.get(path: "/shipments/windows/", version: "v1", query: {"ALL": "1"}),
        api.get(path: "/shipments/offer/", version: "v1")
      ]);

      _slots = DeliverySlot.list(answers[0]);
      _offer = DeliveryOffer.list(answers[1]);
      _slotsError = null;
    } catch (error) {
      if (kDebugMode) print("measureShipping failed: $error");

      _slots = const [];
      _offer = const [];
      _slotsError = error is Map ? error["message"]?.toString() ?? "" : "";
    }

    _notify();
  }

  /// Writes what changed. Throws the backend's refusal.
  Future<void> save(ShippingSettings edited) async {
    final body = shippingSettingsRequest(_settings, edited);
    if (body.isEmpty || _writing) return;

    _writing = true;
    _notify();

    try {
      _settings = ShippingSettings.read(await api.put(path: "/shipments/settings/", version: "v1", data: body));
    } finally {
      _writing = false;
      _notify();
    }

    await measure();
  }

  /// Seeds the panel, for tests.
  @visibleForTesting
  void seed(ShippingSettings settings, {List<DeliverySlot> slots = const [], List<DeliveryOffer> offer = const []}) {
    _settings = settings;
    _slots = slots;
    _offer = offer;
    _status = ShippingSettingsStatus.ready;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
