import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/opening_hours/week_editor.dart';
import 'package:app/screens/home/sections/deliveries/widgets/panel_halves.dart';

import '../state/rates_draft.dart';

/// The own delivery's price per day, beside the hours of the branch it is
/// seen from: each weekday free or with its price, and national holidays as
/// their weekday, free or with their own.
///
/// The hours are only read, so the price of a day is set knowing whether the
/// branch opens then. A method is the company's and not one branch's, so a
/// day closed here still takes a price — another branch may open.
class DeliveryRatesField extends StatefulWidget {
  const DeliveryRatesField({
    super.key,
    required this.draft,
    required this.currency,
    this.hours,
    this.branch
  });

  final RatesDraft draft;

  /// The company's currency symbol, in each price's placeholder.
  final String currency;

  /// The week shown beside the prices; `null` shows the days alone.
  final OpeningHoursService? hours;

  /// The name of [hours]' branch.
  final String? branch;

  /// The weekdays in the order a week is read: Monday first.
  static const List<int> week = [1, 2, 3, 4, 5, 6, 0];

  @override
  State<DeliveryRatesField> createState() => _DeliveryRatesFieldState();
}

class _DeliveryRatesFieldState extends State<DeliveryRatesField> {
  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final hours = widget.hours;
    final branch = widget.branch;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextSmall(S.of(context).business_delivery_rates, bold: true),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          hours != null && branch != null && branch.isNotEmpty
            ? S.of(context).business_delivery_rates_note(branch)
            : S.of(context).business_delivery_rates_note_plain,
          lines: 3,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceXS),
        for (final weekday in DeliveryRatesField.week) _row(
          context,
          title: WeekEditor.dayName(context, weekday),
          subtitle: _hours(context, weekday),
          draft: widget.draft.days[weekday],
          charges: const [RateCharge.free, RateCharge.paid]
        ),
        _row(
          context,
          title: S.of(context).business_delivery_rate_holidays,
          subtitle: S.of(context).business_delivery_rate_holidays_note,
          draft: widget.draft.holiday,
          charges: const [RateCharge.same, RateCharge.free, RateCharge.paid]
        )
      ]
    );

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: hours == null ? content : ListenableBuilder(listenable: hours, builder: (context, _) => content)
    );
  }

  /// One day: its name and hours, how it is charged and, with a price, the price.
  Widget _row(
    BuildContext context, {
    required String title,
    required String? subtitle,
    required RateDraft draft,
    required List<RateCharge> charges
  }) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: TextSmall(title, bold: true, ellipsis: true)),
            if (subtitle != null) ...[
              SizedBox(width: AppSize.gap),
              Flexible(child: TextSmall(subtitle, ellipsis: true, color: scheme.text.secondary))
            ]
          ]),
          SizedBox(height: AppSize.gap * 0.5),
          Row(children: [
            Expanded(flex: 3, child: PanelHalves<RateCharge>(
              values: charges,
              selected: draft.charge,
              label: (charge) => switch (charge) {
                RateCharge.free => S.of(context).business_delivery_rate_free,
                RateCharge.paid => S.of(context).business_delivery_rate_paid,
                RateCharge.same => S.of(context).business_delivery_rate_same
              },
              onChanged: (charge) => setState(() => draft.charge = charge)
            )),
            if (draft.charge == RateCharge.paid) ...[
              SizedBox(width: AppSize.gap),
              Expanded(flex: 2, child: Input(
                placeholder: S.of(context).business_delivery_rate_hint(widget.currency),
                controller: draft.price,
                buttonSpace: false
              ))
            ]
          ])
        ]
      )
    );
  }

  /// What [weekday] the branch opens, `Closed` without a stretch; `null`
  /// before the week is read, or with none to read.
  String? _hours(BuildContext context, int weekday) {
    final hours = widget.hours;

    if (hours == null || hours.status != OpeningHoursStatus.ready) return null;

    final stretches = hours.of(weekday);

    if (stretches.isEmpty) return S.of(context).business_delivery_rate_closed;

    return stretches
      .map((stretch) => "${OpeningStretch.clock(stretch.opens)}–${OpeningStretch.clock(stretch.closes)}")
      .join(" · ");
  }
}
