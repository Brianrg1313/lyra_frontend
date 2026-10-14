import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
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
import 'package:app/screens/home/sections/_section/filter_chip.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **The branch's week**: the hours it attends each weekday, in the company's
/// own time. A day with a break is two stretches; a day with none is closed.
/// It is what the franjas are cut from and what the bot says the branch's
/// opening hours are.
///
/// The week is written whole (`PUT /appointments/hours`), so it is a draft
/// until saved. Read only without `appointments.configure`.
///
/// Typed by [WeekMode]: most branches keep one schedule every day, or one on
/// weekdays and another on the weekend, so a group of days shares its hours
/// and the save spreads them to each day. It opens on the coarsest mode the
/// saved week fits.
class WeekEditor extends StatefulWidget {
  const WeekEditor({super.key, required this.service, required this.editable, required this.onSaved});

  final OpeningHoursService service;
  final bool editable;

  /// After a save: the franjas depend on the week.
  final Future<void> Function() onSaved;

  /// Monday first, Sunday last; the backend's numbers (0 is Sunday).
  static const List<int> order = [1, 2, 3, 4, 5, 6, 0];

  /// The days that share hours under [mode], in [order].
  static List<List<int>> groups(WeekMode mode) => switch (mode) {
    WeekMode.every => const [order],
    WeekMode.split => const [[1, 2, 3, 4, 5], [6, 0]],
    WeekMode.daily => [for (final weekday in order) [weekday]]
  };

  /// The coarsest mode under which every group of [week] has equal days.
  static WeekMode modeOf(Map<int, List<(String, String)>> week) {
    bool same(List<int> days) => days.every((day) => listEquals(week[day] ?? const [], week[days.first] ?? const []));

    for (final mode in const [WeekMode.every, WeekMode.split]) {
      if (groups(mode).every(same)) return mode;
    }
    return WeekMode.daily;
  }

  /// A weekday's name in the screen's language.
  static String dayName(BuildContext context, int weekday) =>
    // 2026-10-11 is a Sunday: adding the weekday lands on it.
    toBeginningOfSentenceCase(DateFormat.EEEE(Localizations.localeOf(context).toString()).format(DateTime(2026, 10, 11 + weekday)));

  @override
  State<WeekEditor> createState() => _WeekEditorState();
}

/// How the week is typed: one schedule for all days, one for weekdays and
/// one for the weekend, or each day its own.
enum WeekMode { every, split, daily }

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
  /// The drafts per group of [_mode], keyed by the group's first day.
  final Map<int, List<_Stretch>> _days = {};
  WeekMode _mode = WeekMode.daily;
  bool _dirty = false;

  List<List<int>> get _groups => WeekEditor.groups(_mode);

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
    final week = {
      for (final weekday in WeekEditor.order) weekday: [
        for (final row in widget.service.of(weekday)) (OpeningStretch.clock(row.opens), OpeningStretch.clock(row.closes))
      ]
    };

    _spread(WeekEditor.modeOf(week), week);
    _dirty = false;
  }

  /// The drafts rebuilt for [mode], each group taking its first day's hours.
  void _spread(WeekMode mode, Map<int, List<(String, String)>> week) {
    _clear();
    _mode = mode;

    for (final group in _groups) {
      _days[group.first] = [
        for (final (opens, closes) in week[group.first] ?? const <(String, String)>[])
          _Stretch(opens, closes, onEdit: _touched)
      ];
    }
  }

  /// Every day's typed hours, as the current groups spread them.
  Map<int, List<(String, String)>> _typed() => {
    for (final group in _groups)
      for (final weekday in group) weekday: [
        for (final stretch in _days[group.first]!) (stretch.opens.value, stretch.closes.value)
      ]
  };

  /// Another way of typing the week. A finer mode keeps every day's hours; a
  /// coarser one takes each group's first day (Monday, Saturday).
  void _switch(WeekMode mode) {
    if (mode == _mode) return;

    final week = _typed();
    setState(() {
      _spread(mode, week);
      _dirty = true;
    });
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

    for (final group in _groups) {
      final rows = <(int, int)>[];

      for (final stretch in _days[group.first]!) {
        final opens = OpeningStretch.minutes(stretch.opens.value);
        final closes = OpeningStretch.minutes(stretch.closes.value);

        if (opens == null || closes == null || closes <= opens) {
          FloatFlag.of(context).error(message: s.shipping_week_invalid(_label(context, group)));
          return;
        }

        rows.add((opens, closes));
      }

      rows.sort((a, b) => a.$1.compareTo(b.$1));

      for (int i = 1; i < rows.length; i++) {
        if (rows[i].$1 < rows[i - 1].$2) {
          FloatFlag.of(context).error(message: s.shipping_week_overlap(_label(context, group)));
          return;
        }
      }

      for (final weekday in group) {
        for (final (opens, closes) in rows) {
          week.add(OpeningStretch(weekday: weekday, opens: opens, closes: closes, branch: widget.service.branch));
        }
      }
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

  /// What a group of days is called: a day, Monday to Friday, Saturday and Sunday.
  static String _label(BuildContext context, List<int> group) {
    final s = S.of(context);
    String name(int weekday) => WeekEditor.dayName(context, weekday);

    return switch (group.length) {
      1 => name(group.first),
      2 => s.shipping_week_pair(name(group.first), name(group.last)),
      7 => s.shipping_week_every,
      _ => s.shipping_week_range(name(group.first), name(group.last))
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return SettingsBlock(
      title: s.shipping_week_title,
      subtitle: s.shipping_week_subtitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.editable) Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
            for (final (mode, title) in [
              (WeekMode.every, s.shipping_week_mode_every),
              (WeekMode.split, s.shipping_week_mode_split),
              (WeekMode.daily, s.shipping_week_mode_daily)
            ]) SectionFilterChip(title: title, isActive: _mode == mode, action: () => _switch(mode))
          ])
        ),
        for (final group in _groups) widget.editable
          ? _editable(context, group)
          : Padding(
              padding: EdgeInsets.only(bottom: AppSize.gap),
              child: Row(children: [
                Expanded(child: TextSmall(_label(context, group), bold: true)),
                TextSmall(
                  _days[group.first]!.isEmpty
                    ? s.shipping_week_closed
                    : _days[group.first]!.map((row) => "${row.opens.value}–${row.closes.value}").join(", "),
                  color: _days[group.first]!.isEmpty ? scheme.text.secondary : null
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

  Widget _editable(BuildContext context, List<int> group) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final weekday = group.first;
    final stretches = _days[weekday]!;
    // "Same as the day before" only reads as such one day at a time.
    final copyable = _mode == WeekMode.daily && WeekEditor.order.first != weekday;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: TextSmall(_label(context, group), bold: true)),
          if (stretches.isEmpty) TextSmall(s.shipping_week_closed, color: scheme.text.secondary),
          if (copyable) ...[
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
