// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

import 'money_summary_model.dart';

/// A ticket that went out on credit: what it was worth, what has been collected
/// against it and what is left.
///
/// A credit sale is one settled as `account`, the store's own tab: the goods
/// left and the money did not arrive, which is why it is not part of the income
/// on the money screen and is reported there apart. The money for it arrives
/// later as a `settlement` payment naming this ticket, and that is what pays
/// [outstanding] down.
class MoneyReceivable {
  const MoneyReceivable({
    required this.id,
    this.ticket = "",
    this.channel = "",
    this.customer = "",
    this.seller = "",
    this.total = 0,
    this.collected = 0,
    this.outstanding = 0,
    this.currency = "",
    this.date
  });

  final String id;

  /// The ticket code, which is what a settlement payment names and what the
  /// customer's copy carries.
  final String ticket;

  /// Where the sale came from (the counter, a channel).
  final String channel;

  /// Who owes it, already read down to the one value a list shows.
  final String customer;

  /// Who sold it.
  final String seller;

  /// What the ticket was worth.
  final double total;

  /// How much of it has been collected so far.
  final double collected;

  /// What is still owed. It is answered and not computed here: half a cent of
  /// float drift is a debt the backend already decided is settled.
  final double outstanding;

  final String currency;

  /// When it was sold. What was collected against it counts whenever it
  /// happened: a debt does not stop being owed because the window moved.
  final DateTime? date;

  /// Whether anything has been collected against it. It is what separates a
  /// ticket nobody has paid from one that is halfway there.
  bool get isPartial => collected > 0 && outstanding > 0;

  factory MoneyReceivable.fromJson(Map<String, dynamic> data) => MoneyReceivable(
    id: (data["id"] ?? "").toString(),
    ticket: (data["ticket"] ?? "").toString(),
    channel: (data["channel"] ?? "").toString(),
    customer: (data["customer"] ?? "").toString(),
    seller: (data["seller"] ?? "").toString(),
    total: moneyDouble(data["total"]),
    collected: moneyDouble(data["collected"]),
    outstanding: moneyDouble(data["outstanding"]),
    currency: (data["currency"] ?? "").toString().toUpperCase(),
    date: moneyDate(data["date"])
  );
}

/// The three numbers the receivables screen is opened for: how much was sold on
/// credit under the filter, how much of it has been collected and how much is
/// outstanding.
class MoneyReceivableTotals {
  const MoneyReceivableTotals({
    this.count = 0,
    this.sold = 0,
    this.collected = 0,
    this.outstanding = 0
  });

  final int count;
  final double sold;
  final double collected;
  final double outstanding;

  factory MoneyReceivableTotals.fromJson(dynamic data) => data is Map
    ? MoneyReceivableTotals(
        count: moneyInt(data["count"]),
        sold: moneyDouble(data["sold"]),
        collected: moneyDouble(data["collected"]),
        outstanding: moneyDouble(data["outstanding"])
      )
    : const MoneyReceivableTotals();
}

/// A page of what the company is still owed.
class MoneyReceivablesPage {
  const MoneyReceivablesPage({
    this.total = 0,
    this.page = 1,
    this.size = 0,
    this.currency = "",
    this.totals = const MoneyReceivableTotals(),
    this.sales = const [],
    this.isLoaded = false
  });

  /// How many credit tickets match the filter, not how many came in this page.
  final int total;

  final int page;
  final int size;

  /// The company's currency, answered once for the whole page instead of on
  /// every row.
  final String currency;

  final MoneyReceivableTotals totals;
  final List<MoneyReceivable> sales;

  final bool isLoaded;

  factory MoneyReceivablesPage.fromResponse(dynamic data) {
    if (data is! Map) return const MoneyReceivablesPage();

    return MoneyReceivablesPage(
      total: moneyInt(data["total"]),
      page: moneyInt(data["page"]),
      size: moneyInt(data["size"]),
      currency: (data["currency"] ?? "").toString().toUpperCase(),
      totals: MoneyReceivableTotals.fromJson(data["totals"]),
      sales: [
        for (final row in catalogRows(data["data"]))
          MoneyReceivable.fromJson(row)
      ],
      isLoaded: true
    );
  }
}
