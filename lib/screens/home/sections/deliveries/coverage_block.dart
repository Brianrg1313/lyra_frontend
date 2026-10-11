import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_areas_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/branches/branch_glyph.dart';
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/area/_area.dart';

import './widgets/scope_switch.dart';

/// Where the company delivers, in the desk's panel: whether its branches share
/// one map or each draws its own (switched here), and how many areas each map
/// has. A map's row opens the delivery area page on it.
///
/// Per branch, a branch with no areas is said in the warning colour: under
/// that scope it delivers nowhere. A row and the branch's pin light up
/// together (`BranchesFocus`).
class CoverageBlock extends StatelessWidget {
  const CoverageBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final service = context.watch<DeliveryAreasService>();
    final areas = service.areas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextMedium(S.of(context).deliveries_scope_title, bold: true, ellipsis: true),
        SizedBox(height: AppSize.gap),
        switch (service.status) {
          DeliveryAreasStatus.error when areas == null => _Failed(
            message: S.of(context).deliveries_area_error_title,
            onRetry: service.retry
          ),
          _ when areas == null => Padding(
            padding: EdgeInsets.all(AppSize.spaceS),
            child: const Center(child: Loading())
          ),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DeliveryScopeSwitch(
                scope: areas.scope,
                onChanged: service.isWriting ? null : (scope) => service.setScope(context, scope)
              ),
              SizedBox(height: AppSize.spaceS),
              if (areas.scope == DeliveryScope.global)
                _MapRow(
                  leading: Icon(CI.globe_shopping, size: AppSize.text, color: scheme.icon),
                  title: S.of(context).deliveries_area_map_shared,
                  count: areas.of(null).length,
                  onTap: () => Navis.push(context, DeliveryAreaSection.path)
                )
              else
                _BranchMaps(areas: areas)
            ]
          )
        }
      ]
    );
  }
}

/// One row per branch, main first, each with its own map's count.
class _BranchMaps extends StatelessWidget {
  const _BranchMaps({required this.areas});

  final DeliveryAreasModel areas;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessBranchesService>();
    final focus = context.watch<BranchesFocus>();
    final scheme = ThemeColor.of(context);

    return switch (service.status) {
      BusinessBranchesStatus.error => _Failed(
        message: S.of(context).deliveries_scope_branches_error,
        onRetry: () => service.load(force: true)
      ),
      BusinessBranchesStatus.ready when service.branches.isEmpty => TextSmall(
        S.of(context).deliveries_scope_branches_empty,
        lines: 3,
        color: scheme.text.secondary
      ),
      BusinessBranchesStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final branch in service.branches)
            MouseRegion(
              onEnter: (_) => focus.hover(branch.id, true),
              onExit: (_) => focus.hover(branch.id, false),
              child: _MapRow(
                leading: BranchGlyph(branch: branch, lit: focus.lit(branch.id), size: AppSize.text * 1.6),
                title: branch.name,
                subtitle: _place(context, branch),
                count: areas.of(branch.id).length,
                warnEmpty: true,
                onTap: () => Navis.push(context, DeliveryAreaSection.branchPath(branch.id))
              )
            )
        ]
      ),
      _ => Padding(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: const Center(child: Loading())
      )
    };
  }

  /// A branch off the map still has areas drawn by hand, but no point to
  /// measure a radius or the closest branch from: said where its place goes.
  String? _place(BuildContext context, BusinessBranchModel branch) =>
    branch.latitude == null || branch.longitude == null
      ? S.of(context).business_branch_no_point
      : null;
}

/// A map: what it is, how many areas it has, and the way into it.
class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.leading,
    required this.title,
    required this.count,
    required this.onTap,
    this.subtitle,
    this.warnEmpty = false
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final int count;

  /// A branch's map with nothing in it delivers nowhere: said in the warning
  /// colour. The shared map with nothing in it is only a map not drawn yet.
  final bool warnEmpty;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final empty = count == 0;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: FeedbackButton(
        action: onTap,
        message: S.of(context).deliveries_scope_edit,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        radius: AppSize.corner,
        color: scheme.surfaceOver,
        feedbackColor: scheme.line,
        child: Row(children: [
          leading,
          SizedBox(width: AppSize.gap),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextSmall(title, bold: true, ellipsis: true),
              TextSmall(
                [
                  if (warnEmpty) S.of(context).deliveries_scope_branch_count(count)
                  else S.of(context).deliveries_scope_global_count(count),
                  ?subtitle
                ].join(" · "),
                ellipsis: true,
                color: empty && warnEmpty ? scheme.chart.warning : scheme.text.secondary
              )
            ]
          )),
          SizedBox(width: AppSize.gap),
          Icon(CI.edit, size: AppSize.text, color: scheme.icon)
        ])
      )
    );
  }
}

/// A read that failed, and the way to read it again.
class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      Expanded(child: TextSmall(message, lines: 2, color: scheme.text.secondary)),
      SizedBox(width: AppSize.gap),
      FeedbackButton(
        action: onRetry,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        radius: AppSize.corner,
        feedbackColor: scheme.surfaceFeedback,
        child: TextSmall(S.of(context).deliveries_map_retry, bold: true, color: scheme.primary)
      )
    ]);
  }
}
