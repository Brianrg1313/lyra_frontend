import 'package:intl/intl.dart';

import 'catalog_table.dart';

/// Nature of a currency. Decided by the backend and used to group the
/// selector: legal tender first and crypto after, which is the order they
/// arrive in.
enum CurrencyKind {
  fiat,
  crypto;

  static CurrencyKind from(dynamic raw) =>
    raw?.toString().toLowerCase() == "crypto" ? crypto : fiat;

  String get value => name;
}

/// A currency in which a price can be written, as listed by `/init`.
///
/// The list comes from the backend (`lyra_admin`.`currencies`, only the enabled
/// ones) and not from this app: **how an amount is written isn't hard-coded
/// here either**. Each currency arrives knowing what it takes to write an
/// amount the way the one charging it does:
///
/// - The [symbol] and which side it goes on ([leading]): `$22.23` but `22.23€`.
/// - Whether it's attached to the amount or separated ([space]): `Bs. 22,23`.
/// - How many [decimals] it's shown with: almost all with two, but the Chilean
///   peso and the guarani have no fraction and `1.500,00` there means nothing,
///   and a crypto can have eight.
/// - How it's grouped ([locale]): `1.234,56` or `1,234.56`. It's of the
///   **currency** and not of the app's language on purpose: a price belongs to
///   who charges it, not who looks at it, and a Venezuelan price list written
///   `Bs. 1,234.50` because the app is in English isn't a figure its customer
///   recognizes.
///
/// So enabling a currency —or fixing its symbol— is a row in the backend and
/// not a new version of the app.
class CurrencyModel {
  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    this.leading = true,
    this.space = false,
    this.decimals = 2,
    this.locale = "",
    this.kind = CurrencyKind.fiat
  });

  /// ISO 4217 code for legal tender, the ticker for crypto (`USDT`).
  /// In uppercase: it's the value that travels to the backend.
  final String code;

  /// Name of the currency, as it arrives.
  final String name;

  /// What is drawn in place of the code (`$`, `€`, `Bs.`, `₿`).
  final String symbol;

  /// Whether the symbol goes in front of the amount.
  final bool leading;

  /// Whether a space separates the symbol from the amount.
  final bool space;

  /// How many decimals the currency actually has: 0 for the Chilean peso, 8 for
  /// bitcoin.
  final int decimals;

  /// BCP-47 tag used to group the amount (`es-VE` gives `1.234,50`). Empty if
  /// the catalog doesn't bring it, and then it's grouped with the app's
  /// language.
  ///
  /// It's a tag and not a pair of characters because grouping is a pattern, not
  /// a separator: `es-VE` cuts every three digits and `hi-IN` writes
  /// `12,34,567`, and there aren't two characters that convey that difference.
  final String locale;

  final CurrencyKind kind;

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    final code = json["code"]?.toString().trim().toUpperCase() ?? "";
    final symbol = json["symbol"]?.toString().trim() ?? "";

    return CurrencyModel(
      code: code,
      name: json["name"]?.toString().trim() ?? "",
      // Without a symbol it's written with the code: a bare amount in a price
      // column doesn't read as a price.
      symbol: symbol.isEmpty ? code : symbol,
      leading: json["position"]?.toString().toLowerCase() != "right",
      space: json["space"] == true || json["space"] == 1,
      decimals: _decimals(json["decimals"]),
      locale: json["locale"]?.toString().trim() ?? "",
      kind: CurrencyKind.from(json["type"])
    );
  }

  /// The catalog currencies, in the order the backend sends them (legal tender
  /// first, each group alphabetical). Those arriving without a code are
  /// discarded: it's the data that travels.
  static List<CurrencyModel> fromResponse(dynamic data) {
    final currencies = <CurrencyModel>[];

    for (final row in catalogRows(data)) {
      final currency = CurrencyModel.fromJson(row);
      if (currency.code.isNotEmpty) currencies.add(currency);
    }

    return currencies;
  }

  /// A currency that's not in the catalog, built from the only thing known
  /// about it: its code.
  ///
  /// It's for saved data the catalog doesn't explain —a business that invoices
  /// in a currency that was disabled, or a screen painted before the catalog
  /// arrived—. The code is shown as-is instead of falling back to another
  /// currency: drawing `$` over an amount in bolivars would be lying about the
  /// data.
  factory CurrencyModel.unknown(String code) {
    final value = code.trim().toUpperCase();

    return CurrencyModel(
      code: value,
      name: value,
      symbol: value,
      // With a space because the symbol is the code: `USD 22.23` reads,
      // `USD22.23` doesn't.
      space: true
    );
  }

  static int _decimals(dynamic raw) {
    final value = raw is num ? raw.toInt() : int.tryParse("$raw");
    if (value == null || value < 0) return 2;

    // A defensive cap: [NumberFormat] doesn't accept any amount and the data
    // comes from a table edited by hand.
    return value > 8 ? 8 : value;
  }

  /// The space separating the symbol from the amount: `" "` or nothing. Used by
  /// whoever paints the symbol separately and needs the gap on the right side.
  String get gap => space ? " " : "";

  bool get isCrypto => kind == CurrencyKind.crypto;

  /// One formatter per grouping and decimal count, created the first time it's
  /// asked for and shared from then on.
  ///
  /// It matters: a stock sheet paints thousands of price cells and each new
  /// [NumberFormat] reads its locale's symbol table. It's just a few objects in
  /// the whole life of the app.
  static final Map<String, NumberFormat> _formats = {};

  /// What it's grouped with: the currency's tag, and the app's language when
  /// the currency brings none (an old catalog row, or a currency hand-built
  /// with [CurrencyModel.unknown]).
  String get _tag => locale.isEmpty ? Intl.getCurrentLocale() : locale;

  NumberFormat get _format => _formats["${_tag}_$decimals"] ??= _build();

  /// [NumberFormat] doesn't know every tag: those not in its table fall back to
  /// the language alone (`es-VE` → `es`), which is what's wanted, but one that
  /// isn't a tag —the catalog is edited by hand— throws. Then it's grouped with
  /// the app's language: a badly grouped price can still be read, an exception
  /// in the middle of a sheet can't.
  NumberFormat _build() {
    try {
      return NumberFormat.decimalPatternDigits(
        locale: _tag,
        decimalDigits: decimals
      );
    } catch (_) {
      return NumberFormat.decimalPatternDigits(
        locale: Intl.getCurrentLocale(),
        decimalDigits: decimals
      );
    }
  }

  /// The amount with this currency's grouping and decimals (`22.23`,
  /// `1,500.00`), or `null` if [raw] can't be read as a number.
  ///
  /// That `null` is what decides what's shown: what isn't an amount is shown as
  /// it was saved and without a symbol, instead of disappearing from the cell
  /// or being shown as zero.
  String? amount(String raw) {
    final value = parse(raw);
    return value == null ? null : _format.format(value);
  }

  /// The amount fully written, symbol included. It's for where the symbol can't
  /// be painted separately (a tooltip, a single-line text); the sheet cell uses
  /// [amount] and [symbol] separately, which shows them in different colors.
  String? label(String raw) {
    final text = amount(raw);
    return text == null ? null : write(text);
  }

  /// Puts the symbol on an already written amount, on the side and with the
  /// space that fits.
  String write(String amount) =>
    leading ? "$symbol$gap$amount" : "$amount$gap$symbol";

  /// Reads an amount written in either of the two ways.
  ///
  /// Prices arrive from two sides and don't agree: the backend sends them with
  /// a decimal point (`22.23`) and whoever loads them writes them the way their
  /// currency does (`22,23`, and sometimes with a thousands separator). **The
  /// last** of the two separators that appear is taken as the decimal one and
  /// the other as thousands, which is the only thing that tells `1.234,56`
  /// apart from `1,234.56` without asking anyone.
  static double? parse(String raw) {
    final text = raw.replaceAll(RegExp(r"\s"), "");
    if (text.isEmpty) return null;

    final decimal = text.lastIndexOf(",") > text.lastIndexOf(".") ? "," : ".";
    final group = decimal == "," ? "." : ",";

    return double.tryParse(
      text.replaceAll(group, "").replaceAll(decimal, ".")
    );
  }

  /// Equality is by value and not by identity because that's how it's used:
  /// price cells subscribe to the active business's currency (`context.select`),
  /// which compares what it returns against the previous one to decide whether
  /// to repaint. Compared by identity, rereading the catalog would repaint the
  /// whole sheet even when the currency is the same.
  @override
  bool operator ==(Object other) =>
    other is CurrencyModel &&
    other.code == code &&
    other.symbol == symbol &&
    other.leading == leading &&
    other.space == space &&
    other.decimals == decimals &&
    other.locale == locale;

  @override
  int get hashCode =>
    Object.hash(code, symbol, leading, space, decimals, locale);

  @override
  String toString() => "CurrencyModel($code)";
}
