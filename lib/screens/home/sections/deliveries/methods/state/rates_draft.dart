// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';

// WIDGETS
import 'package:core/form.dart';

/// How a run of days is charged in the form: free, a price typed, or
/// (holidays only) the weekday's own.
enum RateCharge { free, paid, same }

/// One price as the form holds it.
///
/// Its price field is in no form the method validates: a field hidden by
/// "Free" would otherwise still be validated with what it was left holding.
/// It has one of its own all the same, as a controller with none is disposed
/// by its `Input` when "Free" hides it, and "Price" brings that field back.
class RateDraft {
  RateDraft(this.charge, {String? price})
    : price = InputController(
        key: "RATE",
        form: FormController(),
        pattern: "[0-9.,]",
        max: 16,
        initial: price
      );

  RateCharge charge;
  final InputController price;

  /// What it says, to tell two days charged alike from two that are not.
  String get said => charge == RateCharge.paid ? "paid:${price.value.trim()}" : charge.name;
}

/// Weekdays charged alike, in the order a week is read (Monday first): one
/// row of the prices.
class RateGroup {
  RateGroup(this.weekdays, this.draft);

  /// 0 Sunday to 6 Saturday, consecutive in [RatesDraft.week].
  final List<int> weekdays;
  final RateDraft draft;
}

/// The own delivery's prices while they are typed: **runs of weekdays, not
/// seven rows**. Nobody prices Tuesday apart from Wednesday; what changes a
/// price is the weekend, and a day the branch keeps other hours. So the week
/// opens as Monday to Friday and Saturday and Sunday ([standard]), each split
/// again where the branch's hours change ([regroup]) or where a price saved
/// before already differs. Holidays are a row of their own.
///
/// "Free" is a choice and not an empty field or a 0: a blank price reads as a
/// price somebody forgot, so a run with a price has to have one written.
class RatesDraft {
  RatesDraft._(this._groups, this.holiday);

  /// What [option] charges each day: its rates, else its single fee (an
  /// option from before the rates); free when neither says a price. A new
  /// method starts free every day, and holidays as usual.
  factory RatesDraft.of(DeliveryOption? option) {
    final rates = option?.rates;
    final holiday = rates?.holiday;

    final days = [
      for (var weekday = 0; weekday < 7; weekday++) _said(rates?.days[weekday] ?? option?.fee)
    ];

    return RatesDraft._(
      _split(standard, (weekday) => days[weekday]),
      holiday == null ? RateDraft(RateCharge.same) : _draft(_said(holiday))
    );
  }

  /// The weekdays in the order a week is read: Monday first.
  static const List<int> week = [1, 2, 3, 4, 5, 6, 0];

  /// The runs a week opens with: Monday to Friday, Saturday and Sunday.
  static const List<List<int>> standard = [[1, 2, 3, 4, 5], [6, 0]];

  List<RateGroup> _groups;
  final RateDraft holiday;

  /// Rows taken off by [regroup]: their fields may still be mounted until the
  /// next frame, so they are disposed with the draft.
  final List<RateDraft> _retired = [];

  /// The rows, Monday first.
  List<RateGroup> get groups => _groups;

  /// **The runs [standard] splits into where a day's hours differ from the
  /// day before** ([hours]: one text per weekday, 0 Sunday; `""` closed):
  /// with the branch closed on Sunday, Saturday and Sunday are two rows; with
  /// the same hours every day, the week is still weekdays and weekend.
  static List<List<int>> spans(List<String> hours) => [
    for (final span in standard) ..._runs(span, (weekday) => hours[weekday])
  ];

  /// Groups the week by [spans] (see [RatesDraft.spans]), each day keeping
  /// what it is charged now; a run whose days are charged differently is
  /// split where they differ.
  void regroup(List<List<int>> spans) {
    final now = <int, RateDraft>{
      for (final group in _groups)
        for (final weekday in group.weekdays) weekday: group.draft
    };

    _retired.addAll([for (final group in _groups) group.draft]);
    _groups = _split(spans, (weekday) {
      final draft = now[weekday]!;

      return (charge: draft.charge, price: draft.price.value);
    });
  }

  /// The rates typed, or the first row that has none: `missing` is its
  /// weekdays (empty for holidays) when a price was left empty, `invalid`
  /// when one is not an amount.
  ({DeliveryRates? rates, List<int>? missing, bool invalid}) read({double max = double.infinity}) {
    final prices = List<double?>.filled(7, null);

    for (final group in _groups) {
      final price = _price(group.draft, max);

      if (price.missing) return (rates: null, missing: group.weekdays, invalid: price.invalid);

      for (final weekday in group.weekdays) {
        prices[weekday] = price.value;
      }
    }

    final price = _price(holiday, max);

    if (price.missing) return (rates: null, missing: const [], invalid: price.invalid);

    return (
      rates: DeliveryRates(days: prices, holiday: price.value),
      missing: null,
      invalid: false
    );
  }

  void dispose() {
    for (final draft in [for (final group in _groups) group.draft, holiday, ..._retired]) {
      draft.price.dispose();
      draft.price.form.dispose();
    }
  }

  /// One row's price: 0 free, `null` as usual, else the amount typed.
  static ({double? value, bool missing, bool invalid}) _price(RateDraft draft, double max) {
    switch (draft.charge) {
      case RateCharge.free:
        return (value: 0, missing: false, invalid: false);
      case RateCharge.same:
        return (value: null, missing: false, invalid: false);
      case RateCharge.paid:
        final amount = readDeliveryAmount(draft.price.value);

        if (!amount.valid || (amount.value ?? 0) > max) return (value: null, missing: true, invalid: true);
        if (amount.value == null) return (value: null, missing: true, invalid: false);

        return (value: amount.value, missing: false, invalid: false);
    }
  }

  /// [spans], each cut into runs of days [of] says alike, one row each.
  static List<RateGroup> _split(
    List<List<int>> spans,
    ({RateCharge charge, String price}) Function(int weekday) of
  ) => [
    for (final span in spans)
      for (final run in _runs(span, (weekday) => of(weekday)))
        _draftGroup(run, of(run.first))
  ];

  static RateGroup _draftGroup(List<int> weekdays, ({RateCharge charge, String price}) said) =>
    RateGroup(weekdays, _draft(said));

  static RateDraft _draft(({RateCharge charge, String price}) said) =>
    RateDraft(said.charge, price: said.charge == RateCharge.paid ? said.price : null);

  /// [span] cut where [key] changes from one day to the next.
  static List<List<int>> _runs<T>(List<int> span, T Function(int weekday) key) {
    final runs = <List<int>>[];

    for (final weekday in span) {
      if (runs.isNotEmpty && key(runs.last.last) == key(weekday)) {
        runs.last.add(weekday);
      } else {
        runs.add([weekday]);
      }
    }

    return runs;
  }

  /// A stored price as a row opens: free for none or 0, else `5`, `2.5`,
  /// never `5.00`.
  static ({RateCharge charge, String price}) _said(double? value) => value == null || value == 0
    ? (charge: RateCharge.free, price: "")
    : (charge: RateCharge.paid, price: value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), ""));
}
