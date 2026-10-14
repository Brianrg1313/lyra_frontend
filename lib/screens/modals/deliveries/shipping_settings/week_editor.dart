import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart' show DateFormat, toBeginningOfSentenceCase;

// SERVICES
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **The branch's week**: the hours it attends each weekday, in the company's
/// own time. A day with a break is two stretches; a day with none is closed.
/// It is what the franjas are cut from and what the bot says the branch's
/// opening hours are.
///
/// The week is written whole (`PUT /appointments/hours`), so it is a draft
/// until saved. Read only without `appointments.configure`.
class WeekEditor extends StatefulWidget {
  const WeekEditor({super.key, required this.service, required this.editable, required this.onSaved});

  final OpeningHoursService service;
  final bool editable;

  /// After a save: the franjas depend on the week.
  final Future<void> Function() onSaved;

  /// Monday first, Sunday last; the backend's numbers (0 is Sunday).
  static const List<int> order = [1, 2, 3, 4, 5, 6, 0];

  /// A weekday's name in the screen's language.
  static String dayName(BuildContext context, int weekday) =>
    // 2026-10-11 is a Sunday: adding the weekday lands on it.
    toBeginningOfSentenceCase(DateFormat.EEEE(Localizations.localeOf(context).toString()).format(DateTime(2026, 10, 11 + weekday)));

  @override
  State<WeekEditor> createState() => _WeekEditorState();
}

/// One stretch being typed.
class _Stretch {
  _Stretch(String opens, String closes, {required void Function() onEdit})
    : opens = InputController(key: "OPENS", pattern: "[0-9:]", max: 5, initial: opens),
      closes = InputController(key: "CLOSES", pattern: "[0-9:]", max: 5, initial: closes) {
    this.opens.textController.addListener(onEdit);
    this.closes.textController.addListener(onEdit);
  }

  final InputController opens;
  final InputController closes;

  void dispose() {
    opens.dispose();
    closes.dispose();
  }
}

class _WeekEditorState extends State<WeekEditor> {
  final Map<int, List<_Stretch>> _days = {};
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final stretches in _days.values) {
      for (final stretch in stretches) {
        stretch.dispose();
      }
    }
    _days.clear();
  }

  void _fill() {
    _clear();

    for (final weekday in WeekEditor.order) {
      _days[weekday] = [
        for (final row in widget.service.of(weekday))
          _Stretch(OpeningStretch.clock(row.opens), OpeningStretch.clock(row.closes), onEdit: _touched)
      ];
    }

    _dirty = false;
  }

  /// A time typed: the save button shows.
  void _touched() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _add(int weekday) {
    final last = _days[weekday]!.lastOrNull;

    setState(() {
      _days[weekday]!.add(last == null ? _Stretch("09:00", "18:00", onEdit: _touched) : _Stretch(last.closes.value, "", onEdit: _touched));
      _dirty = true;
    });
  }

  void _remove(int weekday, _Stretch stretch) {
    setState(() {
      _days[weekday]!.remove(stretch);
      stretch.dispose();
      _dirty = true;
    });
  }

  /// The day before's hours, copied onto [weekday].
  void _copyPrevious(int weekday) {
    final index = WeekEditor.order.indexOf(weekday);
    if (index <= 0) return;

    final previous = _days[WeekEditor.order[index - 1]]!;

    setState(() {
      for (final stretch in _days[weekday]!) {
        stretch.dispose();
      }
      _days[weekday] = [for (final stretch in previous) _Stretch(stretch.opens.value, stretch.closes.value, onEdit: _touched)];
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final s = S.of(context);
    final week = <OpeningStretch>[];

    for (final weekday in WeekEditor.order) {
      final rows = <OpeningStretch>[];

      for (final stretch in _days[weekday]!) {
        final opens = OpeningStretch.minutes(stretch.opens.value);
        final closes = OpeningStretch.minutes(stretch.closes.value);

        if (opens == null || closes == null || closes <= opens) {
          FloatFlag.of(context).error(message: s.shipping_week_invalid(WeekEditor.dayName(context, weekday)));
          return;
        }

        rows.add(OpeningStretch(weekday: weekday, opens: opens, closes: closes, branch: widget.service.branch));
      }

      rows.sort((a, b) => a.opens.compareTo(b.opens));

      for (int i = 1; i < rows.length; i++) {
        if (rows[i].opens < rows[i - 1].closes) {
          FloatFlag.of(context).error(message: s.shipping_week_overlap(WeekEditor.dayName(context, weekday)));
          return;
        }
      }

      week.addAll(rows);
    }

    try {
      await widget.service.saveWeek(week);
      if (!mounted) return;

      setState(_fill);
      FloatFlag.of(context).message(s.shipping_week_saved);
      await widget.onSaved();
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return SettingsBlock(
      title: s.shipping_week_title,
      subtitle: s.shipping_week_subtitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final weekday in WeekEditor.order) widget.editable
          ? _editable(context, weekday)
          : Padding(
              padding: EdgeInsets.only(bottom: AppSize.gap),
              child: Row(children: [
                Expanded(child: TextSmall(WeekEditor.dayName(context, weekday), bold: true)),
                TextSmall(
                  _days[weekday]!.isEmpty
                    ? s.shipping_week_closed
                    : _days[weekday]!.map((row) => "${row.opens.value}–${row.closes.value}").join(", "),
                  color: _days[weekday]!.isEmpty ? scheme.text.secondary : null
                )
              ])
            ),
        if (widget.editable && _dirty) ...[
          SizedBox(height: AppSize.spaceXS),
          Row(children: [
            Expanded(child: FeedbackButton(
              action: () => setState(_fill),
              height: AppSize.button,
              color: scheme.surfaceOver,
              radius: AppSize.cornerInset(AppSize.gap),
              message: s.shipping_week_discard,
              child: Center(child: TextSmall(s.shipping_week_discard))
            )),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Button(
              title: s.save,
              action: () {
                if (!widget.service.writing) unawaited(_save());
              }
            ))
          ])
        ]
      ])
    );
  }

  Widget _editable(BuildContext context, int weekday) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final stretches = _days[weekday]!;
    final first = WeekEditor.order.first == weekday;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: TextSmall(WeekEditor.dayName(context, weekday), bold: true)),
          if (stretches.isEmpty) TextSmall(s.shipping_week_closed, color: scheme.text.secondary),
          if (!first) ...[
            SizedBox(width: AppSize.gap),
            SettingsAction(icon: CI.copy, message: s.shipping_week_copy, action: () => _copyPrevious(weekday))
          ],
          SizedBox(width: AppSize.gap),
          SettingsAction(icon: CI.plus, message: s.shipping_week_add, action: () => _add(weekday))
        ]),
        for (final stretch in stretches) Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Row(children: [
            Expanded(child: Input(
              placeholder: s.shipping_week_opens,
              controller: stretch.opens,
              buttonSpace: false
            )),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
              child: TextSmall("–", color: scheme.text.secondary)
            ),
            Expanded(child: Input(
              placeholder: s.shipping_week_closes,
              controller: stretch.closes,
              buttonSpace: false
            )),
            SizedBox(width: AppSize.gap),
            SettingsAction(icon: CI.trash, message: s.shipping_week_remove, action: () => _remove(weekday, stretch))
          ])
        )
      ])
    );
  }
}
