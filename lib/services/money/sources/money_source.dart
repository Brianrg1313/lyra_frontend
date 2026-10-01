import 'dart:typed_data';

// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_receivable_model.dart';
import 'package:app/services/money/money_summary_model.dart';
import 'package:app/services/pos/pos_payment_method.dart';

/// The requirement sheets of the payment rails, by rail code.
typedef MoneyRailFields = Map<String, List<MoneyMethodField>>;

/// The requirement sheets both method reads answer with: `{rail: [...]}`.
MoneyRailFields moneyRailFields(dynamic data) => data is! Map
  ? const {}
  : {
      for (final entry in data.entries)
        entry.key.toString(): [
          for (final row in catalogRows(entry.value)) MoneyMethodField.fromJson(row)
        ].where((field) => field.isValid).toList(growable: false)
    };

/// The option catalogues: `{banks: [{code, name}], ...}`. What is not
/// understood is left out, like every catalogue in this app — a list that did
/// not arrive leaves a field without options, and the form draws it as text
/// rather than as an empty dropdown.
Map<String, List<MoneyPaymentOption>> moneyPaymentOptions(Map data) => {
  for (final entry in data.entries)
    entry.key.toString(): [
      for (final row in catalogRows(entry.value))
        MoneyPaymentOption.fromJson(row)
    ].where((option) => option.isValid).toList(growable: false)
};

/// The company's money: summary, payments, receivables, its payment accounts,
/// currencies and the vocabularies they are recorded with
/// (`docs/offline/specs/money.md`). The money AI is cloud only and not here.
///
/// Throws the normalised error (`{message, action}`). A model that reads a broken
/// answer as not loaded (`MoneySummary`, `MoneyPaymentsPage.isLoaded`, …) is
/// answered as is: its service already tells that apart. Write bodies are the
/// `*_request.dart` maps the services build; a removal takes its key.
abstract interface class MoneySource {
  /// The window since [from], or the company's today when null (the server's
  /// day, the same one the POS reports on).
  Future<MoneySummary> summary({DateTime? from});

  /// One page of payments. A null filter is every value; [state] null is
  /// every status.
  Future<MoneyPaymentsPage> payments({
    required int page,
    required int size,
    MoneyDirection? direction,
    String concept = "",
    String method = "",
    MoneyPaymentStatus? state
  });

  Future<void> recordPayment(Map<String, dynamic> request);

  Future<void> voidPayment({required String id, String reason = ""});

  /// One page of credit sales, only the ones still owed with [openOnly].
  Future<MoneyReceivablesPage> receivables({
    required int page,
    required int size,
    required bool openOnly
  });

  /// The company's payment accounts, valid or not, and the requirement sheets
  /// of their rails.
  Future<({List<MoneyMethod> methods, MoneyRailFields fields})> methods();

  /// The rails the company may turn on in its country, their requirement
  /// sheets, and the option catalogues (banks, …) when the answer has them.
  Future<({
    String country,
    List<MoneyRail> rails,
    MoneyRailFields fields,
    Map<String, List<MoneyPaymentOption>>? options
  })> rails();

  Future<void> createMethod(Map<String, dynamic> request);

  Future<void> updateMethod(Map<String, dynamic> request);

  Future<void> removeMethod(String id);

  Future<MoneyCurrencies> currencies();

  /// Adds an exchange currency or changes its rate.
  Future<void> saveCurrency(Map<String, dynamic> request);

  Future<void> removeCurrency(String currency);

  /// The valid payment concepts each way, and the methods a settlement can be
  /// paid with.
  Future<({
    List<MoneyConcept> incoming,
    List<MoneyConcept> outgoing,
    List<PosPaymentMethod> settlements
  })> catalog();

  /// The accounting export's file (`export.accounting`, M-60) for a
  /// `moneyExportRequest` body. A master's only for now (`money.md`).
  Future<Uint8List> exportAccounting(Map<String, dynamic> request);
}
