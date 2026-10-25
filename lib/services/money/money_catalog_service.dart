import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/toolkit/backend/deployment.dart';

enum MoneyCatalogStatus { idle, loading, ready, error }

/// The two vocabularies the payment form is built from
/// (`GET /money/catalog`): what a payment can be for, and how money can move.
///
/// Both are closed lists the backend validates against, so handing them over is
/// what keeps this app from hard-coding them —and from drifting the day one
/// grows—. It is a description and reads nothing, so it is the same answer for
/// every company: it is asked for once and kept.
///
/// The concepts arrive **split by direction** because the form is: the two
/// halves of the record panel (received / paid) are exactly these two lists,
/// and the concept is what tells the backend which way the money went.
///
/// The settlement kinds are the same vocabulary the counter draws its payment
/// picker from, which is why they are read as [PosPaymentMethod] instead of a
/// second model of the same four fields: both endpoints answer from the
/// backend's `pos/payments` catalog. What this app does **not** confuse with
/// them are the company's own accounts (`MoneyMethodsService`): those are what
/// it turned on, with the number a customer is actually told.
class MoneyCatalogService extends ChangeNotifier {
  MoneyCatalogService({MoneySource? source}) : _injected = source;

  final MoneySource? _injected;

  MoneySource get _source => _injected ?? Sources.money;

  MoneyCatalogStatus _status = MoneyCatalogStatus.idle;

  List<MoneyConcept> _incoming = const [];
  List<MoneyConcept> _outgoing = const [];
  List<PosPaymentMethod> _settlements = const [];

  MoneyCatalogStatus get status => _status;

  /// What money coming in can be for.
  List<MoneyConcept> get incoming => _incoming;

  /// What money going out can be for.
  List<MoneyConcept> get outgoing => _outgoing;

  /// How money can move. Same vocabulary as the counter's picker.
  List<PosPaymentMethod> get settlements => _settlements;

  /// The concepts of one direction, which is how the form asks for them.
  List<MoneyConcept> of(MoneyDirection direction) =>
    direction.isIncoming ? _incoming : _outgoing;

  /// The concept [code] names, whichever direction it belongs to, or null when
  /// it is not one of them.
  MoneyConcept? concept(String code) {
    for (final entry in [..._incoming, ..._outgoing]) {
      if (entry.concept == code) return entry;
    }

    return null;
  }

  /// The settlement kind the backend assumes when nothing is sent, which is
  /// what the record form opens on. Null while the catalog has not arrived.
  PosPaymentMethod? get initialSettlement {
    for (final method in _settlements) {
      if (method.isDefault) return method;
    }

    return _settlements.isEmpty ? null : _settlements.first;
  }

  /// Reads the catalog. Without [force] it does not ask again once it is read:
  /// the answer does not depend on the company and does not change while
  /// somebody is recording payments.
  Future<void> load({bool force = false}) async {
    if (_status == MoneyCatalogStatus.loading) return;
    if (!force && _status == MoneyCatalogStatus.ready) return;

    _status = MoneyCatalogStatus.loading;
    notifyListeners();

    final ({
      List<MoneyConcept> incoming,
      List<MoneyConcept> outgoing,
      List<PosPaymentMethod> settlements
    }) data;

    try {
      data = await _source.catalog();
    } catch (error) {
      if (kDebugMode) print("loadMoneyCatalog failed: $error");

      _status = MoneyCatalogStatus.error;
      notifyListeners();

      return;
    }

    _incoming = data.incoming;
    _outgoing = data.outgoing;
    _settlements = data.settlements;

    // Without concepts there is nothing to record a payment as, so it is
    // reported as the failure it is and offered for retry: an empty vocabulary
    // is a read that answered nothing usable, not a company that moves no
    // money.
    _status = _incoming.isEmpty && _outgoing.isEmpty
      ? MoneyCatalogStatus.error
      : MoneyCatalogStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);
}
