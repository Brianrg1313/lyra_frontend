import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/toolkit/deployment.dart';

enum PosMethodsStatus { idle, loading, ready, error }

/// How a sale can be paid (`GET /pos/methods`), which is what the checkout's
/// picker is drawn from.
///
/// The list is **the backend's and not the counter's**: it validates `METHOD`
/// against the same vocabulary and refuses anything else without ever
/// defaulting, because a sale recorded as cash because a code was misspelled is
/// money the register is short at closing time. Hard-coding it here would be the
/// client guessing at that list.
///
/// It is a description and reads nothing, so it is the same answer for every
/// company: the counter asks for it once, when it opens.
///
/// The endpoint also answers the channels a sale can come from. They are not
/// read here: this screen is the counter, so its channel is always `pos` and a
/// picker for it would be a control with one option.
class PosMethodsService extends ChangeNotifier {
  PosMethodsService({PosSource? source}) : _injected = source;

  final PosSource? _injected;

  PosSource get _source => _injected ?? Sources.pos;

  PosMethodsStatus _status = PosMethodsStatus.idle;
  List<PosPaymentMethod> _methods = const [];

  PosMethodsStatus get status => _status;

  List<PosPaymentMethod> get methods => _methods;

  /// The one the backend assumes when nothing is sent, which is what the
  /// checkout opens on. Null while the list has not arrived.
  PosPaymentMethod? get initial {
    for (final method in _methods) {
      if (method.isDefault) return method;
    }

    return _methods.isEmpty ? null : _methods.first;
  }

  /// The method [code] names, or null when it is not one of them.
  PosPaymentMethod? find(String code) {
    for (final method in _methods) {
      if (method.method == code) return method;
    }

    return null;
  }

  /// Reads the list. Without [force] it does not ask again once it is read: the
  /// answer does not depend on the company and does not change while somebody
  /// is ringing sales up.
  Future<void> load({bool force = false}) async {
    if (_status == PosMethodsStatus.loading) return;
    if (!force && _status == PosMethodsStatus.ready) return;

    _status = PosMethodsStatus.loading;
    notifyListeners();

    final List<PosPaymentMethod> methods;

    try {
      methods = await _source.methods();
    } catch (error) {
      if (kDebugMode) print("loadPosMethods failed: $error");

      _status = PosMethodsStatus.error;
      notifyListeners();

      return;
    }

    _methods = methods.where((method) => method.isValid).toList(growable: false);

    // An empty list is a read that answered nothing usable, not a company that
    // takes no payment: without a method there is no way to charge, so it is
    // reported as the failure it is and offered for retry.
    _status = _methods.isEmpty ? PosMethodsStatus.error : PosMethodsStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);
}
