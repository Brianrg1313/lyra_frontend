import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/assistant/assistant_line.dart';
import 'package:app/services/assistant/assistant_service.dart';

// WIDGETS
import 'package:core/button.dart';

/// Something the assistant wants to do that waits for the person: its summary
/// (exactly what a yes does) and the two buttons. The model cannot press them;
/// only the person can.
///
/// A pending expires on the server after five minutes: past [AssistantPending.expires]
/// the buttons go and the card says so, since a yes would run nothing.
class AssistantConfirm extends StatefulWidget {
  const AssistantConfirm({super.key, required this.pending});

  final AssistantPending pending;

  @override
  State<AssistantConfirm> createState() => _AssistantConfirmState();
}

class _AssistantConfirmState extends State<AssistantConfirm> {
  Timer? _tick;

  /// The yes being answered: core's buttons spin on it.
  final ValueNotifier<bool> _confirming = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // Minutes are what the card shows: a check every few seconds keeps it close.
    if (widget.pending.expires != null) {
      _tick = Timer.periodic(const Duration(seconds: 10), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _confirming.dispose();
    super.dispose();
  }

  Future<void> _answer(bool yes) async {
    final service = context.read<AssistantService>();
    if (service.answering(widget.pending)) return;

    if (yes) _confirming.value = true;

    try {
      await service.confirm(widget.pending, yes: yes);
    } catch (error) {
      FloatFlag.showFromError(error);
    } finally {
      if (mounted) _confirming.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final pending = widget.pending;
    final now = DateTime.now();
    final expired = pending.expiredAt(now);
    final minutes = pending.expires == null ? null : (pending.expires!.difference(now).inSeconds / 60).ceil();

    return Padding(
      // In line with the answers: past the orb's column.
      padding: EdgeInsets.only(top: AppSize.spaceS, left: AppSize.text * 1.9 + AppSize.spaceS),
      child: Container(
        padding: EdgeInsets.all(AppSize.spaceS),
        decoration: BoxDecoration(
          color: scheme.surfaceOver,
          border: Border.all(color: scheme.line),
          borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(CI.info, size: AppSize.text * 1.1, color: scheme.chart.warning),
              SizedBox(width: AppSize.gap * 1.4),
              Expanded(child: TextMedium(s.assistant_confirm_title, bold: true, ellipsis: true)),
              if (minutes != null && !expired) TextSmall(s.assistant_confirm_expires(minutes), color: scheme.text.secondary)
            ]),
            SizedBox(height: AppSize.gap * 1.6),
            TextMedium(pending.summary, lines: 6, selectable: true),
            SizedBox(height: AppSize.spaceS),
            if (expired)
              TextSmall(s.assistant_confirm_expired, color: scheme.text.secondary, lines: 2)
            else Row(children: [
              Expanded(child: Button(title: s.assistant_confirm_no, action: () => _answer(false))),
              SizedBox(width: AppSize.gap * 1.6),
              Expanded(child: MainButton(title: s.assistant_confirm_yes, loading: _confirming, action: () => _answer(true)))
            ])
          ]
        )
      )
    );
  }
}
