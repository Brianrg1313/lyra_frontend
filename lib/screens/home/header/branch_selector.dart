import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/branches/branch_glyph.dart';

/// The branch the person works in, beside the company: the till, stock, sales and money on
/// screen are its own. Drawn only when there is more than one to pick (a company with one
/// branch, or a master's devices, have nothing to switch).
class BranchSelector extends StatelessWidget {
  const BranchSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BranchService>();
    final active = service.active;

    if (!service.choosable || active == null) return const SizedBox.shrink();

    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(left: AppSize.gap),
      child: Builder(builder: (anchor) => FeedbackButton(
        message: S.of(context).branch_selector_title,
        action: () => _pick(anchor, service),
        color: scheme.input.fill,
        height: AppSize.action,
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          BranchGlyph(branch: active, lit: false, size: AppSize.action - AppSize.spaceS),
          Flexible(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
            child: TextMedium(active.name, ellipsis: true)
          )),
          Icon(CI.arrow_down, color: scheme.text.secondary)
        ])
      ))
    );
  }

  Future<void> _pick(BuildContext anchor, BranchService service) async {
    final picked = await showSelectMenu(
      context: anchor,
      selected: service.activeId,
      emptyText: S.of(anchor).business_delivery_select_empty,
      width: AppSize.action * 6,
      maxOptions: 6,
      options: [
        for (final branch in service.branches) SelectOption(
          value: branch.id,
          placeholder: branch.name,
          subtitle: branch.place.isEmpty ? null : branch.place,
          leading: BranchGlyph(branch: branch, lit: false, size: AppSize.text * 1.6)
        )
      ]
    );

    if (picked != null) service.select(picked.value);
  }
}
