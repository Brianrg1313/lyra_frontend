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

/// Weekdays charged alike: one row of the prices.
class RateGroup {
  RateGroup(this.weekdays, this.draft);

  /// 0 Sunday to 6 Saturday, in the order they are named
  /// ([RatesDraft.ordered]): not always consecutive.
  final List<int> weekdays;
  final RateDraft draft;
}

/// The own delivery's prices while they are typed: **the week as the branch
/// keeps it, not seven rows**. What changes a price is a day the branch works
/// differently, so the days with the same hours share a row wherever they
/// fall ([regroup]): a restaurant open Tuesday to Saturday that only delivers
/// on Sunday and Monday has those two rows, free and with an extra. With no
/// hours to read the week opens as Monday to Friday and the weekend
/// ([standard]).
///
/// The person shapes it further: a row splits into its days ([separate]) and
/// they join back ([join]) into the days that share hours and are charged
/// alike, so "free on weekdays, 5 on the weekend" holds on a week with the
/// same hours every day. A row whose days are charged differently (a price
/// saved before) is split where they differ. Holidays are a row of their own.
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
      _layout(null, const {}, (weekday) => days[weekday]),
      holiday == null ? RateDraft(RateCharge.same) : _draft(_said(holiday))
    );
  }

  /// The weekdays in the order a week is read: Monday first.
  static const List<int> week = [1, 2, 3, 4, 5, 6, 0];

  /// The runs a week opens with: Monday to Friday, Saturday and Sunday.
  static const List<List<int>> standard = [[1, 2, 3, 4, 5], [6, 0]];

  List<RateGroup> _groups;
  final RateDraft holiday;

  /// The branch's hours the rows follow ([regroup]); `null` before any.
  List<String>? _hours;

  /// The days the person priced on their own ([separate]).
  final Set<int> _apart = {};

  /// Rows taken off by [regroup]: their fields may still be mounted until the
  /// next frame, so they are disposed with the draft.
  final List<RateDraft> _retired = [];

  /// The rows, Monday first.
  List<RateGroup> get groups => _groups;

  /// Whether a row was split into its days, which [join] undoes.
  bool get separated => _apart.isNotEmpty;

  /// **The days that share [hours]** (one text per weekday, 0 Sunday; `""`
  /// closed), wherever they fall, each in the order it is named and the rows
  /// in the order the week is read; [standard] with no hours to read.
  static List<List<int>> spans(List<String>? hours) {
    if (hours == null || hours.every((day) => day.isEmpty)) return standard;

    return [for (final days in _partition(week, (weekday) => hours[weekday])) ordered(days)]
      ..sort((a, b) => week.indexOf(a.first).compareTo(week.indexOf(b.first)));
  }

  /// [days] in the order they are named: from the first of their run when
  /// they make one around the week (Sunday and Monday, Saturday to Monday),
  /// else Monday first.
  static List<int> ordered(Iterable<int> days) {
    final held = days.toSet();

    for (final start in week) {
      final from = week.indexOf(start);
      final run = [for (var step = 0; step < held.length; step++) week[(from + step) % 7]];

      if (run.every(held.contains)) return run;
    }

    return [for (final weekday in week) if (held.contains(weekday)) weekday];
  }

  /// Whether [days] (as [ordered] gives them) follow one another.
  static bool consecutive(List<int> days) => [
    for (var i = 1; i < days.length; i++)
      (week.indexOf(days[i]) - week.indexOf(days[i - 1])) % 7 == 1
  ].every((follows) => follows);

  /// Follows the branch's [hours] (see [spans]), each day keeping what it is
  /// charged now. Only when the hours change: never under the person typing.
  void regroup(List<String> hours) {
    _hours = hours;
    _relayout();
  }

  /// Splits [group] into its days, each with what the row charged.
  void separate(RateGroup group) {
    _apart.addAll(group.weekdays);
    _relayout();
  }

  /// Joins the days split apart back into the ones that share hours and are
  /// charged alike.
  void join() {
    _apart.clear();
    _relayout();
  }

  void _relayout() {
    final now = <int, RateDraft>{
      for (final group in _groups)
        for (final weekday in group.weekdays) weekday: group.draft
    };

    _retired.addAll([for (final group in _groups) group.draft]);
    _groups = _layout(_hours, _apart, (weekday) {
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

  /// The [spans] of [hours], each cut into the days [of] says alike and the
  /// days [apart] on their own, one row each.
  static List<RateGroup> _layout(
    List<String>? hours,
    Set<int> apart,
    ({RateCharge charge, String price}) Function(int weekday) of
  ) => [
    for (final span in spans(hours))
      for (final days in _partition<Object>(span, (weekday) => apart.contains(weekday) ? weekday : of(weekday)))
        RateGroup(ordered(days), _draft(of(days.first)))
  ];

  static RateDraft _draft(({RateCharge charge, String price}) said) =>
    RateDraft(said.charge, price: said.charge == RateCharge.paid ? said.price : null);

  /// [days] gathered by [key], in the order each key first comes.
  static List<List<int>> _partition<T>(List<int> days, T Function(int weekday) key) {
    final parts = <T, List<int>>{};

    for (final weekday in days) {
      parts.putIfAbsent(key(weekday), () => []).add(weekday);
    }

    return [...parts.values];
  }

  /// A stored price as a row opens: free for none or 0, else `5`, `2.5`,
  /// never `5.00`.
  static ({RateCharge charge, String price}) _said(double? value) => value == null || value == 0
    ? (charge: RateCharge.free, price: "")
    : (charge: RateCharge.paid, price: value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), ""));
}
