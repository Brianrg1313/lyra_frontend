import 'package:app/services/catalog/catalog_table.dart';

/// Where the rate of an exchange currency comes from.
///
/// It is the company's choice and it is a closed pair on purpose. The
/// **official** rate is the feed's (`EXCHANGE_RATES_URL` on the backend) and
/// moves on its own; a **custom** one is a figure the company wrote and does
/// not move until somebody writes another. In exactly the markets this exists
/// for, the two are far apart —the rate a shop in Caracas charges at is not the
/// one a feed publishes—, and a mode per currency is what lets a company quote
/// bolivars at its own rate and euros at the official one.
enum MoneyRateMode {
  official,
  custom;

  /// What travels (`MODE`). Anything unknown reads as the official one: it is
  /// the rate that exists without the company doing anything.
  static MoneyRateMode from(dynamic raw) =>
    raw?.toString().toLowerCase() == "custom" ? custom : official;

  String get value => name;
}

/// One exchange currency: money the company also takes, priced against its
/// main currency, from `GET /money/currencies` (`currencies[]`).
///
/// Every rate here reads **one unit of the main currency is [rate] of this
/// one** (`1 USD = 36.52 VES`), which is the way a shop says it out loud and
/// the way the backend stores it (`model:/currency/currency.js`). The inverse
/// is never shown: `1 VES = 0.0274 USD` is a number nobody charges with.
///
/// [rate] is the effective one —the backend's answer, whichever the mode— and
/// it is what the screen writes. The app never picks between [official] and
/// [custom] itself: a figure this app computed is a figure the backend may not
/// charge.
class MoneyExchange {
  const MoneyExchange({
    required this.currency,
    this.mode = MoneyRateMode.official,
    this.rate,
    this.official,
    this.custom,
    this.updated
  });

  /// ISO 4217 code (`VES`, `COP`, `EUR`), uppercase.
  final String currency;

  final MoneyRateMode mode;

  /// The rate the company charges at today. `null` when there is none: an
  /// official rate the feed has not answered for (or answered too long ago,
  /// past the backend's `#maxAge`), which the screen says instead of drawing
  /// a zero.
  final double? rate;

  /// The feed's rate, whichever the mode. It is what the form shows beside the
  /// custom box, so the company sees how far its own figure is from it.
  final double? official;

  /// The figure the company wrote. Kept when the mode goes back to official, so
  /// switching back does not make it type it again.
  final double? custom;

  /// When [official] was last refreshed.
  final DateTime? updated;

  factory MoneyExchange.fromJson(Map<String, dynamic> data) => MoneyExchange(
    currency: (data["currency"] ?? "").toString().trim().toUpperCase(),
    mode: MoneyRateMode.from(data["mode"]),
    rate: _rate(data["rate"]),
    official: _rate(data["official"]),
    custom: _rate(data["custom"]),
    updated: DateTime.tryParse((data["updated"] ?? "").toString())
  );

  bool get isValid => currency.isNotEmpty;

  /// Whether it can be charged in right now. A currency with no rate is still
  /// listed —the company configured it— but nothing can be converted into it.
  bool get hasRate => rate != null;

  /// A rate is a positive number or it is not a rate: a zero or a negative
  /// from a row edited by hand reads as "none", never as a price of nothing.
  static double? _rate(dynamic raw) {
    final value = switch (raw) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text.trim()),
      _ => null
    };

    return value != null && value.isFinite && value > 0 ? value : null;
  }
}

/// The company's currency setup: what its catalog is priced in and what else
/// it takes, from `GET /money/currencies`.
///
/// [main] is the currency every stored price, stock value and service is in.
/// It is **read-only here**: changing it does not convert a single figure, it
/// relabels them (a list priced in USD becomes the same numbers in EUR), which
/// is why the backend keeps it out of every settings write.
class MoneyCurrencies {
  const MoneyCurrencies({required this.main, this.exchanges = const []});

  /// ISO code of the main currency. Empty only when the answer did not carry
  /// one, and then the business's own currency (`/init`) is what is shown.
  final String main;

  /// The exchange currencies, in the order the backend sends them. Never the
  /// main one: listed as its own exchange it would read `1 USD = 1 USD`.
  final List<MoneyExchange> exchanges;

  factory MoneyCurrencies.fromJson(dynamic data) {
    final map = data is Map ? data : const {};
    final main = (map["currency"] ?? "").toString().trim().toUpperCase();

    return MoneyCurrencies(
      main: main,
      exchanges: [
        for (final row in catalogRows(map["currencies"]))
          MoneyExchange.fromJson(row)
      ].where((row) => row.isValid && row.currency != main)
        .toList(growable: false)
    );
  }

  /// The exchange currency with that code, or null.
  MoneyExchange? exchange(String code) {
    final value = code.trim().toUpperCase();

    for (final row in exchanges) {
      if (row.currency == value) return row;
    }

    return null;
  }

  /// Every currency a payment method can be in: the main one first, then the
  /// exchanges. A method in any other currency would take money nothing can
  /// price.
  List<String> get codes => [
    if (main.isNotEmpty) main,
    for (final row in exchanges) row.currency
  ];
}
