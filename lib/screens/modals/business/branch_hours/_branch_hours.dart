import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show Grant;

// SERVICES
import 'package:app/services/appointments/opening_hours_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/toolkit/deployment.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/shared/opening_hours/closed_days.dart';
import 'package:app/screens/modals/shared/opening_hours/week_editor.dart';

/// Opens [branch]'s opening hours and closed days, from its form.
Future<void> showBranchHours(BuildContext context, {required BusinessBranchModel branch}) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  await showSideModal(
    context: context,
    title: S.of(context).branch_hours_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => BranchHoursModal(branch: branch)
  );
}

const double _width = 480;

/// **When one branch attends** (`sedes-frontend.md` §11), edited from the
/// branch itself: there is one week per branch and none for the company. It is
/// what the bot tells customers, what appointments follow and what the
/// delivery franjas are cut from (those are also edited from the deliveries
/// desk, for the branch worked in).
///
/// Any branch, not only the one worked in: every write names it (`BRANCH`).
/// Editable with `appointments.configure`, read from the person's own grant.
class BranchHoursModal extends StatefulWidget {
  const BranchHoursModal({super.key, required this.branch, this.grant, this.hours});

  final BusinessBranchModel branch;

  /// The person's grant, for tests; read on open otherwise.
  final Grant? grant;

  /// An already loaded week, for tests; owned and read on open otherwise.
  final OpeningHoursService? hours;

  @override
  State<BranchHoursModal> createState() => _BranchHoursModalState();
}

class _BranchHoursModalState extends State<BranchHoursModal> {
  late final OpeningHoursService _hours = widget.hours ?? OpeningHoursService(branch: widget.branch.id);
  late Grant? _grant = widget.grant;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (widget.hours == null) unawaited(_hours.load());
      if (_grant == null) unawaited(_readGrant());
    });
  }

  @override
  void dispose() {
    if (widget.hours == null) _hours.dispose();
    super.dispose();
  }

  Future<void> _readGrant() async {
    try {
      final grant = await Sources.permissions.mine();
      if (mounted) setState(() => _grant = grant);
    } catch (error) {
      // Without the grant the hours stay read only.
      if (mounted) setState(() => _grant = Grant.none());
    }
  }

  static Future<void> _nothing() async {}

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final editable = _grant?.can("appointments.configure") ?? false;

    return ListenableBuilder(
      listenable: _hours,
      builder: (context, _) {
        if (_hours.status == OpeningHoursStatus.error) {
          return SectionMessage(
            icon: CI.calendar,
            title: s.branch_hours_error,
            action: () => unawaited(_hours.load()),
            actionLabel: s.permission_retry
          );
        }

        if (_hours.status != OpeningHoursStatus.ready || _grant == null) {
          return const Center(child: Loading());
        }

        return ScrollableWidget(
          padding: EdgeInsets.only(bottom: AppSize.padding),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextSmall(
              s.branch_hours_subtitle(widget.branch.name),
              lines: 3,
              color: ThemeColor.of(context).text.secondary
            ),
            SizedBox(height: AppSize.spaceS),
            // A key per branch: the editor fills its drafts once, on mount.
            WeekEditor(key: ValueKey(widget.branch.id), service: _hours, editable: editable, onSaved: _nothing),
            ClosedDays(service: _hours, editable: editable, onChanged: _nothing)
          ]
        );
      }
    );
  }
}
