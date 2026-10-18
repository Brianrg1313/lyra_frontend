import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:core/form/style.dart' show FormStyle;

// SERVICES
import 'package:app/services/inventory/product_date.dart';

/// What the calendar answered: the day picked, or `null` when the cell was emptied.
class DateMenuPick {
  const DateMenuPick(this.day);

  final DateTime? day;
}

/// Opens a calendar anchored to [context] (a date cell) and returns the day picked, or
/// `null` when it was closed without picking.
///
/// It opens on [current] —the cell's date, or today when it holds none— and its head reads
/// that date the way its column is being read ([full]); the head's button switches the
/// column between the written and the full date ([onToggle], the cell's own button), and
/// the cross empties the cell ([clearable]). Picking a day is the answer: there is no
/// «accept», like a list's dropdown.
///
/// Core has no calendar: the month grid is Flutter's [CalendarDatePicker], painted in the
/// app's colors, inside the same frame as core's dropdowns.
Future<DateMenuPick?> showDateMenu({
  required BuildContext context,
  required ProductDate? current,
  required bool full,
  required VoidCallback onToggle,
  bool clearable = true
}) {
  final box = context.findRenderObject() as RenderBox?;
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay?.context.findRenderObject() as RenderBox?;

  if (box == null || !box.hasSize || overlay == null) return Future.value(null);

  final origin = box.localToGlobal(Offset.zero, ancestor: overlay);

  return navigator.push(_DateMenuRoute(
    anchor: origin & box.size,
    current: current,
    full: full,
    onToggle: onToggle,
    clearable: clearable && current != null
  ));
}

/// Width of the calendar: what the month grid needs to keep its days square.
double get _menuWidth => AppSize.action * 7.5;

class _DateMenuRoute extends PopupRoute<DateMenuPick> {
  _DateMenuRoute({
    required this.anchor,
    required this.current,
    required this.full,
    required this.onToggle,
    required this.clearable
  });

  final Rect anchor;
  final ProductDate? current;
  final bool full;
  final VoidCallback onToggle;
  final bool clearable;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "";

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation
  ) => CustomSingleChildLayout(
    delegate: _DateMenuLayout(anchor: anchor, padding: MediaQuery.of(context).padding),
    child: _DateMenu(
      current: current,
      full: full,
      onToggle: onToggle,
      clearable: clearable
    )
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child
  ) => FadeTransition(opacity: animation, child: child);
}

/// Below the cell when it fits, above when not, and always inside the window.
class _DateMenuLayout extends SingleChildLayoutDelegate {
  const _DateMenuLayout({required this.anchor, required this.padding});

  final Rect anchor;
  final EdgeInsets padding;

  double get _margin => AppSize.spaceXS;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(
    maxWidth: math.min(_menuWidth, math.max(constraints.maxWidth - _margin * 2, 0)),
    maxHeight: math.max(constraints.maxHeight - padding.vertical - _margin * 2, 0)
  );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = padding.top + _margin;
    final bottom = size.height - padding.bottom - _margin;
    final below = anchor.bottom + AppSize.gap;

    final y = below + childSize.height <= bottom
      ? below
      : math.max(top, anchor.top - AppSize.gap - childSize.height);

    final limit = math.max(_margin, size.width - childSize.width - _margin);
    final x = math.min(math.max(anchor.left, _margin), limit);

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_DateMenuLayout old) => anchor != old.anchor || padding != old.padding;
}

class _DateMenu extends StatefulWidget {
  const _DateMenu({
    required this.current,
    required this.full,
    required this.onToggle,
    required this.clearable
  });

  final ProductDate? current;
  final bool full;
  final VoidCallback onToggle;
  final bool clearable;

  @override
  State<_DateMenu> createState() => _DateMenuState();
}

class _DateMenuState extends State<_DateMenu> {
  /// The column's reading, kept here too: the column changes under the calendar, and its
  /// head has to follow it.
  late bool _full = widget.full;

  void _toggle() {
    widget.onToggle();
    setState(() => _full = !_full);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final locale = Localizations.localeOf(context).toString();
    final current = widget.current;
    final today = DateUtils.dateOnly(DateTime.now());
    // The grid asserts its first day inside its range: an imported 1850 opens on today.
    final initial = current == null || current.at.year < 1900 || current.at.year > 2100
      ? today
      : DateUtils.dateOnly(current.at);
    final size = AppSize.text * 1.8;

    final head = current == null
      ? S.of(context).product_table_view_date_none
      : _full ? current.full(locale) : current.short(locale);

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: FormStyle.dropdown(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSize.spaceM, AppSize.spaceS, AppSize.spaceS, 0),
              child: Row(children: [
                Expanded(child: TextMedium(
                  head,
                  bold: true,
                  ellipsis: true,
                  color: current == null ? scheme.text.secondary : null
                )),
                Tooltip(
                  message: _full
                    ? S.of(context).product_table_view_date_short_hint
                    : S.of(context).product_table_view_date_full_hint,
                  child: FeedbackButton(
                    message: _full
                      ? S.of(context).product_table_view_date_short
                      : S.of(context).product_table_view_date_full,
                    width: size,
                    height: size,
                    radius: AppSize.gap,
                    action: _toggle,
                    // The format it switches to, like the cell's button.
                    child: Center(child: Icon(
                      _full ? CI.calendar : Icons.schedule,
                      size: AppSize.text,
                      color: scheme.text.primary
                    ))
                  )
                ),
                if (widget.clearable) FeedbackButton(
                  message: S.of(context).product_table_view_date_clear,
                  width: size,
                  height: size,
                  radius: AppSize.gap,
                  action: () => Navigator.of(context).pop(const DateMenuPick(null)),
                  child: Center(child: Icon(
                    Icons.close,
                    size: AppSize.text,
                    color: scheme.text.primary
                  ))
                )
              ])
            ),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: scheme.primary,
                  onPrimary: scheme.button.text,
                  surface: scheme.input.fill,
                  onSurface: scheme.text.primary
                )
              ),
              child: CalendarDatePicker(
                initialDate: initial,
                currentDate: today,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100, 12, 31),
                onDateChanged: (day) => Navigator.of(context).pop(DateMenuPick(day))
              )
            )
          ]
        )
      )
    );
  }
}
