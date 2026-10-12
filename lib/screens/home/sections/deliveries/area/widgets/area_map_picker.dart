import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/branches/branch_glyph.dart';
import 'package:app/screens/home/sections/deliveries/widgets/scope_switch.dart';

/// Top of the area list: whether the branches share one map or each draws its
/// own, and, per branch, whose map is open — a button that unfolds the
/// branches with how many areas each has. A branch's pin on the map opens its
/// map too. A branch's map with nothing in it is said in the warning colour:
/// under that scope the branch delivers nowhere.
class AreaMapPicker extends StatelessWidget {
  const AreaMapPicker({
    super.key,
    required this.areas,
    required this.branches,
    required this.owner,
    required this.onScope,
    required this.onOwner
  });

  final DeliveryAreasModel areas;
  final List<BusinessBranchModel> branches;

  /// The open map: a branch's id, or `null` for the shared one.
  final String? owner;

  /// `null` while a write is in flight.
  final void Function(DeliveryScope scope)? onScope;

  final void Function(String branch) onOwner;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final open = branches.where((branch) => branch.id == owner).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DeliveryScopeSwitch(scope: areas.scope, onChanged: onScope),
        if (areas.scope == DeliveryScope.branch && open != null) ...[
          SizedBox(height: AppSize.spaceS),
          TextSmall(S.of(context).deliveries_area_map, color: scheme.text.secondary),
          SizedBox(height: AppSize.gap * 0.5),
          FeedbackButton(
            action: () => _pick(context),
            message: S.of(context).deliveries_area_map,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
            radius: AppSize.corner,
            color: scheme.surfaceOver,
            feedbackColor: scheme.line,
            child: Row(children: [
              BranchGlyph(branch: open, lit: true, size: AppSize.text * 1.6),
              SizedBox(width: AppSize.gap),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextSmall(open.name, bold: true, ellipsis: true),
                  TextSmall(
                    S.of(context).deliveries_scope_branch_count(areas.of(open.id).length),
                    ellipsis: true,
                    color: areas.of(open.id).isEmpty ? scheme.chart.warning : scheme.text.secondary
                  )
                ]
              )),
              Icon(CI.arrow_down, size: AppSize.text, color: scheme.icon)
            ])
          )
        ]
      ]
    );
  }

  Future<void> _pick(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      width: AppSize.action * 8,
      options: [
        for (final branch in branches) SelectOption(
          value: branch.id,
          placeholder: branch.name,
          subtitle: S.of(anchor).deliveries_scope_branch_count(areas.of(branch.id).length),
          leading: BranchGlyph(branch: branch, lit: branch.id == owner, size: AppSize.text * 1.6)
        )
      ],
      emptyText: S.of(anchor).deliveries_scope_branches_empty
    );

    if (picked != null) onOwner(picked.value);
  }
}
