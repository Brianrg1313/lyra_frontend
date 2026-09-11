// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

import 'money_concept_model.dart';
import 'money_summary_model.dart';

/// Whether a payment still counts.
///
/// A payment is **never edited and never deleted**: a mistake is voided and
/// written again, which is what really happened. So the voided row stays in the
/// history saying what was believed at the time, and stops adding up.
enum MoneyPaymentStatus {
  recorded,
  voided;

  /// The code the backend uses, which is also what the `STATUS` filter takes.
  String get value => name;

  static MoneyPaymentStatus from(dynamic raw) =>
    raw?.toString().trim().toLowerCase() == "voided" ? voided : recorded;
}

/// One movement of the history: money the company received or paid.
///
/// **A sale's own payment is not here.** The ticket already is that record, and
/// a second row saying the same thing is two histories that can disagree. What
/// lives here is everything around it —a supplier paid on Friday, a customer
/// settling their tab— which is why the money screen adds this list and the
/// register's takings instead of reading one of them twice.
class MoneyPayment {
  const MoneyPayment({
    required this.id,
    required this.direction,
    this.concept = "",
    this.conceptName = "",
    this.amount = 0,
    this.currency = "",
    this.method = "",
    this.methodName = "",
    this.account = "",
    this.reference = "",
    this.counterpart = "",
    this.ticket = "",
    this.note = "",
    this.status = MoneyPaymentStatus.recorded,
    this.registeredBy = "",
    this.date
  });

  /// Identifier of the payment. It is what a void names.
  final String id;

  /// Which way the money went. It is answered and never sent: the concept
  /// decides it.
  final MoneyDirection direction;

  final String concept;

  /// What the concept is called, as the backend writes it.
  final String conceptName;

  /// How much moved, always positive: the direction carries the sign.
  final double amount;

  /// Currency it was stamped in. It is the company's, and it is not converted.
  final String currency;

  /// Settlement kind it moved through (`cash`, `transfer`, `mobile`).
  final String method;
  final String methodName;

  /// Which of the company's own accounts it landed in, already read down to the
  /// label the listing shows. Empty when the payment named none.
  final String account;

  /// The number the bank or the terminal printed, so the payment can be found
  /// again on a statement.
  final String reference;

  /// Who paid, or who was paid, already read down to one value.
  final String counterpart;

  /// The sale it belongs to, on the concepts that allow one.
  final String ticket;

  final String note;
  final MoneyPaymentStatus status;

  /// Name of the person who recorded it. The backend answers a name and never
  /// an internal id.
  final String registeredBy;

  /// When the **money moved**, which is not when it was typed in: a supplier
  /// paid on Friday and recorded on Monday is three days apart, and the
  /// register's question is always about the first one.
  final DateTime? date;

  bool get isVoided => status == MoneyPaymentStatus.voided;

  factory MoneyPayment.fromJson(Map<String, dynamic> data) => MoneyPayment(
    id: (data["id"] ?? "").toString(),
    direction: MoneyDirection.from(data["direction"]) ?? MoneyDirection.outgoing,
    concept: (data["concept"] ?? "").toString(),
    conceptName: (data["conceptName"] ?? "").toString(),
    amount: moneyDouble(data["amount"]),
    currency: (data["currency"] ?? "").toString().toUpperCase(),
    method: (data["method"] ?? "").toString(),
    methodName: (data["methodName"] ?? "").toString(),
    account: (data["account"] ?? "").toString(),
    reference: (data["reference"] ?? "").toString(),
    counterpart: _counterpart(data["counterpart"]),
    ticket: (data["ticket"] ?? "").toString(),
    note: (data["note"] ?? "").toString(),
    status: MoneyPaymentStatus.from(data["status"]),
    registeredBy: (data["registeredBy"] ?? "").toString(),
    date: moneyDate(data["date"])
  );

  /// The counterpart comes flat in the listing —the backend already read it
  /// down to a name or a contact— and as `{name, contact}` on the payment a
  /// write answers with. Both are read so the same model serves the two.
  static String _counterpart(dynamic raw) {
    if (raw is Map) {
      final name = (raw["name"] ?? "").toString();
      return name.isNotEmpty ? name : (raw["contact"] ?? "").toString();
    }

    return (raw ?? "").toString();
  }
}

/// What the whole filter adds up to, in each direction.
///
/// It is **not** what the rows on screen add up to: "cuanto llevo pagado a
/// proveedores este mes" is a question about the filter and not about the page
/// being looked at. Voided payments never count towards it, whatever the
/// listing is showing.
class MoneyPaymentTotals {
  const MoneyPaymentTotals({
    this.income = const MoneyAmount(),
    this.expense = const MoneyAmount()
  });

  /// What came in under the filter (`in`).
  final MoneyAmount income;

  /// What went out under it (`out`).
  final MoneyAmount expense;

  factory MoneyPaymentTotals.fromJson(dynamic data) => data is Map
    ? MoneyPaymentTotals(
        income: MoneyAmount.fromJson(data["in"]),
        expense: MoneyAmount.fromJson(data["out"])
      )
    : const MoneyPaymentTotals();
}

/// A page of the history, with the totals of the filter it was read under.
class MoneyPaymentsPage {
  const MoneyPaymentsPage({
    this.total = 0,
    this.page = 1,
    this.size = 0,
    this.totals = const MoneyPaymentTotals(),
    this.payments = const [],
    this.isLoaded = false
  });

  /// How many payments match the filter, not how many came in this page. It is
  /// what tells the list when to stop asking for more.
  final int total;

  final int page;
  final int size;
  final MoneyPaymentTotals totals;
  final List<MoneyPayment> payments;

  /// Whether the response was understood. A page that is not is an error and
  /// not an empty history.
  final bool isLoaded;

  factory MoneyPaymentsPage.fromResponse(dynamic data) {
    if (data is! Map) return const MoneyPaymentsPage();

    return MoneyPaymentsPage(
      total: moneyInt(data["total"]),
      page: moneyInt(data["page"]),
      size: moneyInt(data["size"]),
      totals: MoneyPaymentTotals.fromJson(data["totals"]),
      payments: [
        for (final row in catalogRows(data["data"]))
          MoneyPayment.fromJson(row)
      ],
      isLoaded: true
    );
  }
}
