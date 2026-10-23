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
import './form_section.dart';

/// The own delivery's prices as one ledger: **runs of days, not seven rows**
/// (see [RatesDraft]) — Monday to Friday and the weekend, split again where
/// the hours of the branch it is seen from change — and national holidays,
/// each free or with its price.
///
/// The hours are only read, so a price is set knowing whether the branch
/// opens then. A method is the company's and not one branch's, so a run
/// closed here still takes a price — another branch may open.
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

  /// The week the runs follow and show; `null` keeps weekdays and weekend.
  final OpeningHoursService? hours;

  /// The name of [hours]' branch.
  final String? branch;

  /// What a run of days is called: `Monday`, `Saturday and Sunday`, `Monday
  /// to Friday`; holidays for none.
  static String name(BuildContext context, List<int> weekdays) => switch (weekdays.length) {
    0 => S.of(context).business_delivery_rate_holidays,
    1 => WeekEditor.dayName(context, weekdays.first),
    2 => S.of(context).business_delivery_rate_pair(
      WeekEditor.dayName(context, weekdays.first),
      WeekEditor.dayName(context, weekdays.last)
    ),
    _ => S.of(context).business_delivery_rate_span(
      WeekEditor.dayName(context, weekdays.first),
      WeekEditor.dayName(context, weekdays.last)
    )
  };

  @override
  State<DeliveryRatesField> createState() => _DeliveryRatesFieldState();
}

class _DeliveryRatesFieldState extends State<DeliveryRatesField> {
  /// The week was read and the runs follow it: once, so a price typed is not
  /// regrouped under the person typing it.
  bool _grouped = false;

  @override
  void initState() {
    super.initState();

    widget.hours?.addListener(_regroup);
    _regroup();
  }

  @override
  void dispose() {
    widget.hours?.removeListener(_regroup);
    super.dispose();
  }

  void _regroup() {
    final hours = widget.hours;

    if (_grouped || hours == null || hours.status != OpeningHoursStatus.ready) return;

    _grouped = true;

    final week = [for (var weekday = 0; weekday < 7; weekday++) _stretches(hours, weekday) ?? ""];

    // A branch with no week at all keeps weekdays and weekend.
    if (week.every((day) => day.isEmpty)) return;

    if (mounted) setState(() => widget.draft.regroup(RatesDraft.spans(week)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final branch = widget.branch;
    final named = widget.hours != null && branch != null && branch.isNotEmpty;
    final groups = widget.draft.groups;

    return FormSection(
      title: S.of(context).business_delivery_rates,
      note: named
        ? S.of(context).business_delivery_rates_note(branch)
        : S.of(context).business_delivery_rates_note_plain,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.line),
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final group in groups) ...[
              _row(
                context,
                title: DeliveryRatesField.name(context, group.weekdays),
                subtitle: _hours(context, group.weekdays.first),
                draft: group.draft,
                charges: const [RateCharge.free, RateCharge.paid]
              ),
              Separator.horizontal()
            ],
            _row(
              context,
              title: S.of(context).business_delivery_rate_holidays,
              subtitle: S.of(context).business_delivery_rate_holidays_note,
              draft: widget.draft.holiday,
              charges: const [RateCharge.same, RateCharge.free, RateCharge.paid]
            )
          ]
        )
      )
    );
  }

  /// One run: its days and hours over how it is charged and, with a price,
  /// the price beside it.
  Widget _row(
    BuildContext context, {
    required String title,
    required String? subtitle,
    required RateDraft draft,
    required List<RateCharge> charges
  }) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSize.spaceXS),
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
          SizedBox(height: AppSize.gap),
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

    final week = [for (var day = 0; day < 7; day++) _stretches(hours, day)];

    if (week.every((day) => day == null)) return null;

    return week[weekday] ?? S.of(context).business_delivery_rate_closed;
  }

  /// [weekday]'s stretches as `9:00–18:00 · 19:00–22:00`; `null` closed.
  static String? _stretches(OpeningHoursService hours, int weekday) {
    final stretches = hours.of(weekday);

    if (stretches.isEmpty) return null;

    return stretches
      .map((stretch) => "${OpeningStretch.clock(stretch.opens)}–${OpeningStretch.clock(stretch.closes)}")
      .join(" · ");
  }
}
