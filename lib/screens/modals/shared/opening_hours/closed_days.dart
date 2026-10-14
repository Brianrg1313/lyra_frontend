import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_service.dart';
import 'package:app/services/inventory/product_date.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **The days ahead the branch does not attend**: closed here, or in every
/// branch (a national holiday). No franja is offered on them and the bot does
/// not promise them; what was already scheduled on one stays for somebody to
/// call off. Read only without `appointments.configure`.
class ClosedDays extends StatefulWidget {
  const ClosedDays({super.key, required this.service, required this.editable, required this.onChanged});

  final OpeningHoursService service;
  final bool editable;

  /// After a day closes or opens: the franjas depend on it.
  final Future<void> Function() onChanged;

  @override
  State<ClosedDays> createState() => _ClosedDaysState();
}

class _ClosedDaysState extends State<ClosedDays> {
  final _form = FormController();
  late final _day = InputController(key: "DAY", form: _form, pattern: "[0-9/-]", max: 10);
  late final _reason = InputController(key: "REASON", form: _form, max: 120);
  bool _everywhere = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final s = S.of(context);
    final day = ProductDate.parse(_day.value);

    if (day == null) {
      FloatFlag.of(context).error(message: s.shipping_closed_invalid);
      return;
    }

    final at = day.at;
    final text = "${at.year.toString().padLeft(4, "0")}-${at.month.toString().padLeft(2, "0")}-${at.day.toString().padLeft(2, "0")}";

    try {
      await widget.service.close(text, reason: _reason.value, everywhere: _everywhere);
      if (!mounted) return;

      _day.textController.clear();
      _reason.textController.clear();
      setState(() => _everywhere = false);
      await widget.onChanged();
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  Future<void> _reopen(ClosedDay closed) async {
    final s = S.of(context);

    if (closed.everywhere) {
      final confirmed = await showAlertModal(
        context: context,
        title: s.shipping_closed_reopen_title,
        message: s.shipping_closed_reopen_everywhere(closed.day),
        confirmText: s.shipping_closed_reopen,
        cancelText: s.cancel
      );

      if (!confirmed || !mounted) return;
    }

    try {
      await widget.service.reopen(closed);
      await widget.onChanged();
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final closures = widget.service.closures;

    return SettingsBlock(
      title: s.shipping_closed_title,
      subtitle: s.shipping_closed_subtitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (closures.isEmpty)
          TextSmall(s.shipping_closed_empty, color: scheme.text.secondary)
        else
          for (final closed in closures) Padding(
            padding: EdgeInsets.only(bottom: AppSize.gap),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextSmall(closed.day, bold: true),
                TextSmall(
                  [
                    closed.everywhere ? s.shipping_closed_everywhere : s.shipping_closed_here,
                    if (closed.reason.isNotEmpty) closed.reason
                  ].join(" · "),
                  ellipsis: true,
                  color: scheme.text.secondary
                )
              ])),
              if (widget.editable) SettingsAction(
                icon: CI.trash,
                message: s.shipping_closed_reopen,
                action: () => unawaited(_reopen(closed))
              )
            ])
          ),
        if (widget.editable) ...[
          SizedBox(height: AppSize.spaceXS),
          Input(
            title: s.shipping_closed_day,
            placeholder: s.shipping_closed_day_hint,
            controller: _day,
            formatters: const [DateSeparatorFormatter()],
            leftIcon: Icon(CI.calendar, color: scheme.icon)
          ),
          Input(title: s.shipping_closed_reason, placeholder: s.shipping_closed_reason_hint, controller: _reason),
          SettingsToggle(
            value: _everywhere,
            label: s.shipping_closed_everywhere_toggle,
            toggle: () => setState(() => _everywhere = !_everywhere)
          ),
          SizedBox(height: AppSize.spaceXS),
          Button(
            title: s.shipping_closed_add,
            action: () {
              if (!widget.service.writing) unawaited(_close());
            }
          )
        ]
      ])
    );
  }
}
