import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/opening_hours/week_editor.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';
import 'package:app/screens/home/sections/deliveries/widgets/panel_halves.dart';

import '../state/rates_draft.dart';
import './form_section.dart';

/// The own delivery's prices as one ledger: **the days that share the hours
/// of the branch it is seen from, not seven rows** (see [RatesDraft]), each
/// row splittable into its days and joined back, and national holidays, each
/// free or with its price.
///
/// The hours are edited above it (`DeliveryHoursField`) and followed here as
/// they change, so a price is set knowing how the branch works then. A method
/// is the company's and not one branch's, so a day closed here still takes a
/// price — another branch may open.
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

  /// What a row's days are called: `Monday`, `Sunday and Monday`, `Tuesday
  /// to Saturday`, `Monday, Wednesday and Friday`, `Every day`; holidays for
  /// none. [weekdays] as [RatesDraft.ordered] gives them.
  static String name(BuildContext context, List<int> weekdays) {
    final s = S.of(context);
    String day(int weekday) => WeekEditor.dayName(context, weekday);

    if (weekdays.isEmpty) return s.business_delivery_rate_holidays;
    if (weekdays.length == 7) return s.business_delivery_rate_every;
    if (weekdays.length == 1) return day(weekdays.first);
    if (weekdays.length > 2 && RatesDraft.consecutive(weekdays)) {
      return s.business_delivery_rate_span(day(weekdays.first), day(weekdays.last));
    }

    final first = weekdays
      .sublist(1, weekdays.length - 1)
      .fold(day(weekdays.first), (list, weekday) => s.business_delivery_rate_list(list, day(weekday)));

    return s.business_delivery_rate_pair(first, day(weekdays.last));
  }

  @override
  State<DeliveryRatesField> createState() => _DeliveryRatesFieldState();
}

class _DeliveryRatesFieldState extends State<DeliveryRatesField> {
  /// The week the rows follow now: they are regrouped only when it changes
  /// (the hours edited above), never under the person typing a price.
  List<String>? _week;

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

    if (hours == null || hours.status != OpeningHoursStatus.ready) return;

    final week = [for (var weekday = 0; weekday < 7; weekday++) _stretches(hours, weekday) ?? ""];

    if (listEquals(week, _week)) return;

    _week = week;

    if (mounted) setState(() => widget.draft.regroup(week));
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
                charges: const [RateCharge.free, RateCharge.paid],
                separate: group.weekdays.length > 1
                  ? () => setState(() => widget.draft.separate(group))
                  : null
              ),
              Separator.horizontal()
            ],
            if (widget.draft.separated) ...[
              Padding(
                padding: EdgeInsets.all(AppSize.spaceXS),
                child: Button(
                  title: S.of(context).business_delivery_rate_join,
                  leftIcon: Icon(CI.link, color: scheme.icon),
                  action: () => setState(widget.draft.join)
                )
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
    required List<RateCharge> charges,
    void Function()? separate
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
            ],
            if (separate != null) ...[
              SizedBox(width: AppSize.gap),
              SettingsAction(
                icon: CI.list,
                message: S.of(context).business_delivery_rate_separate,
                action: separate
              )
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
