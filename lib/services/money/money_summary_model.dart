import 'money_concept_model.dart';

/// A figure of the summary: how much, and out of how many movements.
///
/// The count travels beside the total because they answer different questions
/// —"cuanto entro" and "cuantas veces"— and a screen that only showed the money
/// could not tell one transfer of a thousand from a hundred sales of ten.
class MoneyAmount {
  const MoneyAmount({this.count = 0, this.total = 0});

  final int count;
  final double total;

  factory MoneyAmount.fromJson(dynamic data) => data is Map
    ? MoneyAmount(
        count: moneyInt(data["count"]),
        total: moneyDouble(data["total"])
      )
    : const MoneyAmount();

  bool get isEmpty => count == 0 && total == 0;
}

/// What moved through one settlement kind in the window.
///
/// It is grouped by the kind (`cash`, `transfer`, `mobile`) and not by the
/// company's own accounts: two bank accounts of the same shop are both
/// transfers, and the question this row answers —cuanto entro en efectivo— is
/// about the rail and not about which account it landed in.
class MoneyMethodTotals {
  const MoneyMethodTotals({
    required this.method,
    required this.name,
    this.income = 0,
    this.expense = 0,
    this.net = 0,
    this.count = 0
  });

  final String method;

  /// What it is called, as the backend writes it.
  final String name;

  /// What came in through it. The backend calls it `in`, which is a reserved
  /// word here.
  final double income;

  /// What went out through it (`out`).
  final double expense;

  final double net;
  final int count;

  factory MoneyMethodTotals.fromJson(Map<String, dynamic> data) =>
    MoneyMethodTotals(
      method: (data["method"] ?? "").toString(),
      name: (data["name"] ?? "").toString(),
      income: moneyDouble(data["in"]),
      expense: moneyDouble(data["out"]),
      net: moneyDouble(data["net"]),
      count: moneyInt(data["count"])
    );
}

/// What moved under one concept in the window.
///
/// Unlike a method, a concept only goes one way —its direction is part of what
/// it means— so there is a single total and the direction says which side of
/// the screen it belongs to.
class MoneyConceptTotals {
  const MoneyConceptTotals({
    required this.concept,
    required this.name,
    required this.direction,
    this.total = 0,
    this.count = 0
  });

  final String concept;
  final String name;
  final MoneyDirection direction;
  final double total;
  final int count;

  factory MoneyConceptTotals.fromJson(Map<String, dynamic> data) =>
    MoneyConceptTotals(
      concept: (data["concept"] ?? "").toString(),
      name: (data["name"] ?? "").toString(),
      direction:
        MoneyDirection.from(data["direction"]) ?? MoneyDirection.outgoing,
      total: moneyDouble(data["total"]),
      count: moneyInt(data["count"])
    );
}

/// The money screen over a window: what came in, what went out, and what that
/// leaves.
///
/// It is **two reads added on the way out**: the register's own money comes
/// from the sales themselves —a ticket is the record of what it was paid
/// with— and everything else from the payments recorded by hand. Neither is
/// copied into the other, which is why [income] is split into `sales` and
/// `payments`.
///
/// **[credit] is not income.** A ticket settled as `account` is the store's own
/// tab: the goods left and the money did not arrive, so it is reported apart
/// and counted nowhere else. It turns into income the day somebody records the
/// settlement against that ticket, which is what the receivables tab is for.
class MoneySummary {
  const MoneySummary({
    this.from,
    this.to,
    this.currency = "",
    this.sales = const MoneyAmount(),
    this.payments = const MoneyAmount(),
    this.income = 0,
    this.expenses = const MoneyAmount(),
    this.credit = const MoneyAmount(),
    this.net = 0,
    this.methods = const [],
    this.concepts = const [],
    this.isLoaded = false
  });

  /// The window the backend actually answered about, which is not always the
  /// one that was asked for: an empty request is today, midnight to now.
  final DateTime? from;
  final DateTime? to;

  /// Code of the currency every figure is written in. The amounts are the
  /// company's own and are never converted: a total that adds two currencies
  /// together is a number nobody can act on.
  final String currency;

  /// What the register took in, from the tickets themselves.
  final MoneyAmount sales;

  /// What came in outside the register: a customer settling a tab, a refund
  /// received.
  final MoneyAmount payments;

  /// [sales] plus [payments], as the backend adds them.
  final double income;

  final MoneyAmount expenses;

  /// What went out on credit and has not been collected. Reported apart, see
  /// the class note.
  final MoneyAmount credit;

  /// [income] minus [expenses].
  final double net;

  final List<MoneyMethodTotals> methods;
  final List<MoneyConceptTotals> concepts;

  /// Whether this is an answer and not the empty summary the service starts
  /// with. A company with no movements answers zeros, which is a real reading
  /// and not the absence of one.
  final bool isLoaded;

  /// Whether nothing moved in the window. Zeros are drawn as the empty state
  /// and not as a wall of noughts.
  bool get isEmpty =>
    income == 0 && expenses.total == 0 && credit.total == 0;

  factory MoneySummary.fromResponse(dynamic data) {
    if (data is! Map) return const MoneySummary();

    final income = data["income"];

    return MoneySummary(
      from: moneyDate(data["from"]),
      to: moneyDate(data["to"]),
      currency: (data["currency"] ?? "").toString().toUpperCase(),
      sales: MoneyAmount.fromJson(income is Map ? income["sales"] : null),
      payments: MoneyAmount.fromJson(income is Map ? income["payments"] : null),
      income: income is Map ? moneyDouble(income["total"]) : 0,
      expenses: MoneyAmount.fromJson(data["expenses"]),
      credit: MoneyAmount.fromJson(data["credit"]),
      net: moneyDouble(data["net"]),
      methods: [
        for (final row in data["methods"] ?? const [])
          if (row is Map)
            MoneyMethodTotals.fromJson(Map<String, dynamic>.from(row))
      ],
      concepts: [
        for (final row in data["concepts"] ?? const [])
          if (row is Map)
            MoneyConceptTotals.fromJson(Map<String, dynamic>.from(row))
      ],
      isLoaded: true
    );
  }
}

/// The money figures arrive as numbers, but MySQL hands a DECIMAL over as text
/// often enough that reading both is cheaper than finding out in production
/// that a total renders as zero.
double moneyDouble(dynamic raw) => switch (raw) {
  final num value => value.toDouble(),
  final String text => double.tryParse(text.trim()) ?? 0,
  _ => 0
};

int moneyInt(dynamic raw) => switch (raw) {
  final num value => value.toInt(),
  final String text => int.tryParse(text.trim()) ?? 0,
  _ => 0
};

/// A date as the backend writes it (ISO, UTC), or null when the field is not
/// one. It is **not** converted here: whoever draws it moves it to local time,
/// which is where the language to write it in is also known.
DateTime? moneyDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;

  return DateTime.tryParse(raw.toString().trim());
}
