// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_currency_request.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_method_request.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_payment_request.dart';
import 'package:app/services/money/money_receivable_model.dart';
import 'package:app/services/money/money_summary_model.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/toolkit/api.dart';

/// [MoneySource] over the backend's REST api.
class MoneyCloudSource implements MoneySource {
  const MoneyCloudSource();

  /// Today is the bare read and any other window is the same answer with a
  /// body: the endpoint pair exists so a screen with a range picker does not
  /// have to switch URLs when somebody drags it.
  @override
  Future<MoneySummary> summary({DateTime? from}) async => MoneySummary.fromResponse(
    from == null
      ? await api.get(path: "/money/", version: "v1")
      : await api.post(
          path: "/money/summary/",
          version: "v1",
          data: {"FROM": from.toUtc().toIso8601String()}
        )
  );

  @override
  Future<MoneyPaymentsPage> payments({
    required int page,
    required int size,
    MoneyDirection? direction,
    String concept = "",
    String method = "",
    MoneyPaymentStatus? state
  }) async => MoneyPaymentsPage.fromResponse(await api.post(
    path: "/money/payments/search/",
    version: "v1",
    data: {
      "PAGE": page,
      "SIZE": size,
      if (direction != null) "DIRECTION": direction.value,
      if (concept.isNotEmpty) "CONCEPT": concept,
      if (method.isNotEmpty) "METHOD": method,
      "STATUS": state?.value ?? "all"
    }
  ));

  @override
  Future<void> recordPayment(Map<String, dynamic> request) =>
    api.post(path: "/money/payments/", version: "v1", data: request);

  @override
  Future<void> voidPayment({required String id, String reason = ""}) => api.post(
    path: "/money/payments/void/",
    version: "v1",
    data: voidPaymentRequest(id: id, reason: reason)
  );

  @override
  Future<MoneyReceivablesPage> receivables({
    required int page,
    required int size,
    required bool openOnly
  }) async => MoneyReceivablesPage.fromResponse(await api.post(
    path: "/money/receivables/",
    version: "v1",
    data: {"PAGE": page, "SIZE": size, "OPEN": openOnly ? 1 : 0}
  ));

  @override
  Future<({List<MoneyMethod> methods, MoneyRailFields fields})> methods() async {
    final data = await api.get(path: "/money/methods/", version: "v1");

    return (
      methods: [
        for (final row in catalogRows(data is Map ? data["methods"] : null))
          MoneyMethod.fromJson(row)
      ],
      fields: moneyRailFields(data is Map ? data["fields"] : null)
    );
  }

  @override
  Future<({
    String country,
    List<MoneyRail> rails,
    MoneyRailFields fields,
    Map<String, List<MoneyPaymentOption>>? options
  })> rails() async {
    final data = await api.get(path: "/business/payments/", version: "v1");
    final options = data is Map ? data["options"] : null;

    return (
      country: (data is Map ? data["country"] ?? "" : "").toString(),
      rails: [
        for (final row in catalogRows(data is Map ? data["methods"] : null))
          MoneyRail.fromJson(row)
      ].where((entry) => entry.isValid).toList(growable: false),
      fields: moneyRailFields(data is Map ? data["fields"] : null),
      options: options is Map ? moneyPaymentOptions(options) : null
    );
  }

  @override
  Future<void> createMethod(Map<String, dynamic> request) =>
    api.post(path: "/money/methods/", version: "v1", data: request);

  @override
  Future<void> updateMethod(Map<String, dynamic> request) =>
    api.put(path: "/money/methods/", version: "v1", data: request);

  @override
  Future<void> removeMethod(String id) =>
    api.delete(path: "/money/methods/", version: "v1", data: removeMoneyMethodRequest(id));

  @override
  Future<MoneyCurrencies> currencies() async =>
    MoneyCurrencies.fromJson(await api.get(path: "/money/currencies/", version: "v1"));

  @override
  Future<void> saveCurrency(Map<String, dynamic> request) =>
    api.put(path: "/money/currencies/", version: "v1", data: request);

  @override
  Future<void> removeCurrency(String currency) => api.delete(
    path: "/money/currencies/",
    version: "v1",
    data: removeMoneyExchangeRequest(currency)
  );

  @override
  Future<({
    List<MoneyConcept> incoming,
    List<MoneyConcept> outgoing,
    List<PosPaymentMethod> settlements
  })> catalog() async {
    final data = await api.get(path: "/money/catalog/", version: "v1");
    final concepts = data is Map ? data["concepts"] : null;

    return (
      incoming: _concepts(concepts is Map ? concepts["in"] : null),
      outgoing: _concepts(concepts is Map ? concepts["out"] : null),
      settlements: _methods(data is Map ? data["methods"] : null)
    );
  }

  static List<MoneyConcept> _concepts(dynamic raw) => raw is! List
    ? const []
    : [
        for (final entry in raw)
          if (entry is Map)
            MoneyConcept.fromJson(Map<String, dynamic>.from(entry))
      ].where((concept) => concept.isValid).toList(growable: false);

  static List<PosPaymentMethod> _methods(dynamic raw) => raw is! List
    ? const []
    : [
        for (final entry in raw)
          if (entry is Map)
            PosPaymentMethod.fromJson(Map<String, dynamic>.from(entry))
      ].where((method) => method.isValid).toList(growable: false);
}
