import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_service.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/shipments/shipments_service.dart';
import 'package:app/services/shipments/shipping_settings_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/shared/opening_hours/closed_days.dart';
import 'package:app/screens/modals/shared/opening_hours/week_editor.dart';

import './offer_preview.dart';
import './slot_settings.dart';

/// Opens the schedule of the branch worked in, from the deliveries board.
/// [service] is the board's, which knows what the person may change.
Future<void> showShippingSettings(BuildContext context, {required ShipmentsService service}) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  await showSideModal(
    context: context,
    title: S.of(context).shipping_settings_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => ShippingSettingsModal(board: service)
  );
}

const double _width = 480;

/// **When the branch delivers** (`envios-frontend.md` §6–§7, `sedes-frontend.md`
/// §11): what a customer would be offered today, how the branch's hours are
/// cut into franjas, the hours themselves and the days it is closed.
///
/// The franjas come from the branch's week minus its closed days: a branch
/// with no hours has no franjas, which is why the week is edited here and not
/// only somewhere else. The same week is what the bot tells customers as the
/// branch's opening hours.
///
/// It owns its services, for the branch worked in: every route here answers
/// for the `branch_id` header (the week and closures are sent with `BRANCH`).
class ShippingSettingsModal extends StatefulWidget {
  const ShippingSettingsModal({super.key, required this.board});

  final ShipmentsService board;

  @override
  State<ShippingSettingsModal> createState() => _ShippingSettingsModalState();
}

class _ShippingSettingsModalState extends State<ShippingSettingsModal> {
  final ShippingSettingsService _settings = ShippingSettingsService();
  final String? _branch = BranchService().activeId;
  late final OpeningHoursService? _hours = _branch == null ? null : OpeningHoursService(branch: _branch);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      unawaited(_settings.load());
      unawaited(_hours?.load());
    });
  }

  @override
  void dispose() {
    _settings.dispose();
    _hours?.dispose();
    super.dispose();
  }

  /// The franjas and the offer are measured from the week: read again once it
  /// changes.
  Future<void> _remeasure() => _settings.measure();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hours = _hours;

    if (hours == null) {
      return SectionMessage(icon: CI.store, title: s.shipping_settings_no_branch, subtitle: s.shipping_settings_no_branch_subtitle);
    }

    return ListenableBuilder(
      listenable: Listenable.merge([_settings, hours]),
      builder: (context, _) {
        if (_settings.status == ShippingSettingsStatus.error || hours.status == OpeningHoursStatus.error) {
          return SectionMessage(
            icon: CI.calendar,
            title: s.shipping_settings_error,
            action: () {
              unawaited(_settings.load());
              unawaited(hours.load());
            },
            actionLabel: s.permission_retry
          );
        }

        if (_settings.status != ShippingSettingsStatus.ready || hours.status != OpeningHoursStatus.ready) {
          return const Center(child: Loading());
        }

        return ScrollableWidget(
          padding: EdgeInsets.only(bottom: AppSize.padding),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextSmall(
              s.shipping_settings_subtitle(BranchService().nameOf(_branch)),
              lines: 3,
              color: ThemeColor.of(context).text.secondary
            ),
            SizedBox(height: AppSize.spaceS),
            OfferPreview(service: _settings, hasHours: hours.week.isNotEmpty),
            SlotSettings(service: _settings, editable: widget.board.canConfigure),
            WeekEditor(service: hours, editable: widget.board.canSchedule, onSaved: _remeasure),
            ClosedDays(service: hours, editable: widget.board.canSchedule, onChanged: _remeasure)
          ]
        );
      }
    );
  }
}
