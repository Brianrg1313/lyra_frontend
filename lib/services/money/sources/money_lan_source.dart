import 'dart:typed_data';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_receivable_model.dart';
import 'package:app/services/money/money_summary_model.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/services/pos/sources/pos_lan_source.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// [MoneySource] over the master (`docs/offline/specs/money.md`).
///
/// The master answers the cloud's shapes with money in minor units of the company's main currency
/// (README, money), which this source turns into the amounts the models hold, and back for the
/// amount of a payment. An account's fixed commission is the exception: it is in the account's
/// own currency and travels as an amount, like a rate (`money.md`, release status). An account's
/// holder, document and number are sealed on the master (M-45): a session that can't open them
/// is refused with `sealed_locked`, which `MoneyMethodsService` tells apart.
class MoneyLanSource implements MoneySource {
  const MoneyLanSource(this._lan);

  final LanService _lan;

  @override
  Future<MoneySummary> summary({DateTime? from}) async {
    final answer = await _lan.call(Ops.moneySummary, args: {
      if (from != null) "from": from.toUtc().toIso8601String()
    });
    if (answer is! Map) throw const UnreadableAnswer("money.summary");

    final digits = PosLanSource.decimalsOf(answer["currency"]);
    final income = answer["income"];

    return MoneySummary.fromResponse({
      ...answer,
      if (income is Map) "income": {
        ...income,
        "sales": _amount(income["sales"], digits),
        "payments": _amount(income["payments"], digits),
        "total": PosLanSource.major(income["total"], digits)
      },
      "expenses": _amount(answer["expenses"], digits),
      "credit": _amount(answer["credit"], digits),
      "net": PosLanSource.major(answer["net"], digits),
      "methods": [
        for (final row in answer["methods"] as List? ?? const [])
          if (row is Map) {...row, ..._amounts(row, const ["in", "out", "net"], digits)}
      ],
      "concepts": [
        for (final row in answer["concepts"] as List? ?? const [])
          if (row is Map) {...row, ..._amounts(row, const ["total"], digits)}
      ]
    });
  }

  @override
  Future<MoneyPaymentsPage> payments({
    required int page,
    required int size,
    MoneyDirection? direction,
    String concept = "",
    String method = "",
    MoneyPaymentStatus? state
  }) async {
    final answer = await _lan.call(Ops.moneyPaymentsSearch, args: {
      "page": page,
      "size": size,
      if (direction != null) "direction": direction.value,
      if (concept.isNotEmpty) "concept": concept,
      if (method.isNotEmpty) "method": method,
      "status": state?.value ?? "all"
    });
    if (answer is! Map) throw const UnreadableAnswer("money.payments.search");

    final totals = answer["totals"];
    final digits = _digits;

    return MoneyPaymentsPage.fromResponse({
      ...answer,
      if (totals is Map) "totals": {
        "in": _amount(totals["in"], digits),
        "out": _amount(totals["out"], digits)
      },
      "data": [
        for (final row in answer["data"] as List? ?? const [])
          if (row is Map) {...row, ..._amounts(row, const ["amount"], PosLanSource.decimalsOf(row["currency"]))}
      ]
    });
  }

  /// The service's body is the cloud's (`recordPaymentRequest`); the master takes the amount in
  /// minor units. One with more decimals than the currency has travels as it is, for the master to
  /// refuse (M-2), rather than rounded into a payment nobody typed.
  @override
  Future<void> recordPayment(Map<String, dynamic> request) async {
    final counterpart = request["COUNTERPART"];

    await _lan.call(Ops.moneyPaymentsRecord, args: {
      "concept": request["CONCEPT"],
      "amount": _minor(request["AMOUNT"]),
      if (request["METHOD"] != null) "method": request["METHOD"],
      if (request["ACCOUNT_ID"] != null) "accountId": request["ACCOUNT_ID"],
      if (request["REFERENCE"] != null) "reference": request["REFERENCE"],
      if (counterpart is Map) "counterpart": {
        if (counterpart["NAME"] != null) "name": counterpart["NAME"],
        if (counterpart["CONTACT"] != null) "contact": counterpart["CONTACT"]
      },
      if (request["NOTE"] != null) "note": request["NOTE"],
      if (request["TICKET"] != null) "ticket": request["TICKET"],
      if (request["DATE"] != null) "date": request["DATE"]
    });
  }

  @override
  Future<void> voidPayment({required String id, String reason = ""}) => _lan.call(Ops.moneyPaymentsVoid, args: {
    "id": id,
    if (reason.trim().isNotEmpty) "reason": reason.trim()
  });

  @override
  Future<MoneyReceivablesPage> receivables({
    required int page,
    required int size,
    required bool openOnly
  }) async {
    final answer = await _lan.call(Ops.moneyReceivables, args: {"page": page, "size": size, "open": openOnly});
    if (answer is! Map) throw const UnreadableAnswer("money.receivables");

    final digits = PosLanSource.decimalsOf(answer["currency"]);
    final totals = answer["totals"];

    return MoneyReceivablesPage.fromResponse({
      ...answer,
      if (totals is Map) "totals": {...totals, ..._amounts(totals, const ["sold", "collected", "outstanding"], digits)},
      "data": [
        for (final row in answer["data"] as List? ?? const [])
          if (row is Map) {...row, ..._amounts(row, const ["total", "collected", "outstanding"], digits)}
      ]
    });
  }

  @override
  Future<({List<MoneyMethod> methods, MoneyRailFields fields})> methods() async {
    final answer = await _lan.call(Ops.moneyMethodsList);
    if (answer is! Map) throw const UnreadableAnswer("money.methods.list");

    return (
      methods: [
        for (final row in answer["methods"] as List? ?? const [])
          if (row is Map) MoneyMethod.fromJson(Map<String, dynamic>.from(row))
      ],
      fields: moneyRailFields(answer["fields"])
    );
  }

  @override
  Future<({
    String country,
    List<MoneyRail> rails,
    MoneyRailFields fields,
    Map<String, List<MoneyPaymentOption>>? options
  })> rails() async {
    final answer = await _lan.call(Ops.moneyMethodsRails);
    if (answer is! Map) throw const UnreadableAnswer("money.methods.rails");

    final options = answer["options"];

    return (
      country: (answer["country"] ?? "").toString(),
      rails: [
        for (final row in answer["methods"] as List? ?? const [])
          if (row is Map) MoneyRail.fromJson(Map<String, dynamic>.from(row))
      ].where((rail) => rail.isValid).toList(growable: false),
      fields: moneyRailFields(answer["fields"]),
      options: options is Map ? moneyPaymentOptions(options) : null
    );
  }

  /// The service's body is the cloud's (`createMoneyMethodRequest`), in the master's keys.
  @override
  Future<void> createMethod(Map<String, dynamic> request) => _lan.call(Ops.moneyMethodsCreate, args: _method(request));

  /// The service's body is the cloud's (`updateMoneyMethodRequest`): a key it leaves out keeps the
  /// value and a `null` clears it, on the master too.
  @override
  Future<void> updateMethod(Map<String, dynamic> request) => _lan.call(Ops.moneyMethodsEdit, args: _method(request));

  @override
  Future<void> removeMethod(String id) => _lan.call(Ops.moneyMethodsRemove, args: {"id": id});

  /// Rates are not money: they travel as they are (`1 main = rate`).
  @override
  Future<MoneyCurrencies> currencies() async => MoneyCurrencies.fromJson(await _lan.call(Ops.moneyCurrenciesGet));

  /// The service's body is the cloud's (`saveMoneyExchangeRequest`).
  @override
  Future<void> saveCurrency(Map<String, dynamic> request) => _lan.call(Ops.moneyCurrenciesSave, args: {
    "currency": request["CURRENCY"],
    "mode": request["MODE"],
    if (request["RATE"] != null) "rate": request["RATE"]
  });

  @override
  Future<void> removeCurrency(String currency) =>
    _lan.call(Ops.moneyCurrenciesRemove, args: {"currency": currency.trim().toUpperCase()});

  @override
  Future<({
    List<MoneyConcept> incoming,
    List<MoneyConcept> outgoing,
    List<PosPaymentMethod> settlements
  })> catalog() async {
    final answer = await _lan.call(Ops.moneyCatalog);
    final concepts = answer is Map ? answer["concepts"] : null;
    if (concepts is! Map) throw const UnreadableAnswer("money.catalog");

    List<MoneyConcept> read(Object? rows) => [
      for (final row in rows as List? ?? const [])
        if (row is Map) MoneyConcept.fromJson(Map<String, dynamic>.from(row))
    ].where((concept) => concept.isValid).toList(growable: false);

    return (
      incoming: read(concepts["in"]),
      outgoing: read(concepts["out"]),
      settlements: [
        for (final row in (answer as Map)["methods"] as List? ?? const [])
          if (row is Map) PosPaymentMethod.fromJson(Map<String, dynamic>.from(row))
      ].where((method) => method.isValid).toList(growable: false)
    );
  }

  /// `export.accounting` answers a file id, valid for an hour and readable
  /// only by this session's account (`protocol-v1.md` §6); it is fetched at once.
  @override
  Future<Uint8List> exportAccounting(Map<String, dynamic> request) async {
    final answer = await _lan.call(Ops.exportAccounting, args: request);
    final id = answer is Map ? answer["fileId"] : null;
    if (id is! String) throw const UnreadableAnswer("export.accounting");

    return _lan.download(id);
  }

  /// The cloud's account body keys, as the master names them.
  static const _methodKeys = {
    "ID": "id",
    "CODE": "code",
    "LABEL": "label",
    "HOLDER": "holder",
    "DOCUMENT": "document",
    "INSTITUTION": "institution",
    "ACCOUNT": "account",
    "INSTRUCTIONS": "instructions",
    "CURRENCY": "currency",
    "FEE_TYPE": "feeType",
    "FEE": "fee",
    "POSITION": "position"
  };

  /// [request] in the master's keys; a key it has, `null` included, travels.
  static Map<String, Object?> _method(Map<String, dynamic> request) => {
    for (final MapEntry(:key, :value) in request.entries)
      ?_methodKeys[key]: value
  };

  /// Decimals of the company's main currency, which every payment is in (M-5).
  static int get _digits => PosLanSource.decimalsOf(businessService.currencyCode);

  /// [amount] in minor units when it has no more decimals than the currency, else as it is.
  static Object? _minor(Object? amount) {
    final minor = PosLanSource.minor(amount, _digits);
    if (minor == null) return amount;

    return (PosLanSource.major(minor, _digits)! - (amount as num)).abs() < 1e-9 ? minor : amount;
  }

  /// A `{count, total}` figure with its total as an amount.
  static Object? _amount(Object? figure, int digits) =>
    figure is Map ? {...figure, ..._amounts(figure, const ["total"], digits)} : figure;

  /// [keys] of [data] from minor units to amounts; null stays null.
  static Map<String, double?> _amounts(Map data, List<String> keys, int digits) =>
    {for (final key in keys) if (data.containsKey(key)) key: PosLanSource.major(data[key], digits)};
}
