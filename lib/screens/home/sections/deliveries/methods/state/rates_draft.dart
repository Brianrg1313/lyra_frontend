// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';

// WIDGETS
import 'package:core/form.dart';

/// How one day is charged in the form: free, a price typed, or (holidays only)
/// the weekday's own.
enum RateCharge { free, paid, same }

/// One day's price as the form holds it.
///
/// Its price field is in no `FormController`: a field hidden by "Free" would
/// otherwise still be validated with what it was left holding.
class RateDraft {
  RateDraft(this.charge, {double? price})
    : price = InputController(
        key: "RATE",
        pattern: "[0-9.,]",
        max: 16,
        initial: price == null ? null : _plain(price)
      );

  RateCharge charge;
  final InputController price;

  /// A stored price as the form opens it: `5`, `2.5`, never `5.00`.
  static String _plain(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "");
}

/// The own delivery's price per day while it is typed: seven weekdays (0
/// Sunday) and national holidays.
///
/// "Free" is a choice and not an empty field or a 0: a blank price reads as a
/// price somebody forgot, so a day with a price has to have one written.
class RatesDraft {
  RatesDraft._(this.days, this.holiday);

  /// What [option] charges each day: its rates, else its single fee (an
  /// option from before the rates); free when neither says a price. A new
  /// method starts free every day, and holidays as their weekday.
  factory RatesDraft.of(DeliveryOption? option) {
    RateDraft day(double? price) => price == null || price == 0
      ? RateDraft(RateCharge.free)
      : RateDraft(RateCharge.paid, price: price);

    final rates = option?.rates;
    final holiday = rates?.holiday;

    return RatesDraft._(
      [for (var weekday = 0; weekday < 7; weekday++) day(rates?.days[weekday] ?? option?.fee)],
      holiday == null
        ? RateDraft(RateCharge.same)
        : holiday == 0 ? RateDraft(RateCharge.free) : RateDraft(RateCharge.paid, price: holiday)
    );
  }

  /// By weekday, 0 Sunday to 6 Saturday.
  final List<RateDraft> days;
  final RateDraft holiday;

  /// The rates typed, or the first day that has none: `missing` is its
  /// weekday (7 for holidays) when a price was left empty, `invalid` when one
  /// is not an amount.
  ({DeliveryRates? rates, int? missing, bool invalid}) read({double max = double.infinity}) {
    final prices = <double?>[];

    for (final (index, draft) in [...days, holiday].indexed) {
      switch (draft.charge) {
        case RateCharge.free:
          prices.add(0);
        case RateCharge.same:
          prices.add(null);
        case RateCharge.paid:
          final amount = readDeliveryAmount(draft.price.value);

          if (!amount.valid || (amount.value ?? 0) > max) return (rates: null, missing: index, invalid: true);
          if (amount.value == null) return (rates: null, missing: index, invalid: false);

          prices.add(amount.value);
      }
    }

    return (
      rates: DeliveryRates(days: prices.sublist(0, 7), holiday: prices[7]),
      missing: null,
      invalid: false
    );
  }

  void dispose() {
    for (final draft in [...days, holiday]) {
      draft.price.dispose();
    }
  }
}
