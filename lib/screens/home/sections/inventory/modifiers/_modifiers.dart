import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/modifiers_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/kitchen/modifier_group/_modifier_group.dart';

import './modifier_row.dart';

/// The modifiers tab: the company's groups of choices about a product — «Extras» (cheese,
/// bacon), «Término de la carne» (choose one), «Pan» (white or whole wheat) — in order, each
/// opening its form; a new one from the bar.
class ModifiersTab extends StatefulWidget {
  const ModifiersTab({super.key});

  @override
  State<ModifiersTab> createState() => _ModifiersTabState();
}

class _ModifiersTabState extends State<ModifiersTab> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ModifiersService>().load();
    });
  }

  bool get _canEdit => PermissionsService().can("inventory.modifiers.edit");

  /// Opens the form —a new group without [group]— and writes what it collected.
  Future<void> _open({ModifierGroup? group}) async {
    final service = context.read<ModifiersService>();
    final s = S.of(context);

    final draft = await showModifierGroupForm(context, group: group, canEdit: _canEdit);

    if (draft == null || !mounted) return;

    final done = draft.delete
      ? await service.remove(context, group!)
      : await service.save(context, saveModifierGroupRequest(
          id: group?.id ?? "",
          name: draft.name,
          min: draft.min,
          max: draft.max,
          position: group?.position,
          products: draft.products,
          options: draft.options
        ));

    if (done) FloatFlag.of().message(draft.delete ? s.kitchen_modifiers_deleted : s.kitchen_modifiers_saved);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ModifiersService>();
    final s = S.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: TextSmall(s.kitchen_modifiers_note, lines: 2, color: ThemeColor.of(context).text.secondary)),
        if (_canEdit) ...[
          SizedBox(width: AppSize.spaceS),
          SizedBox(
            width: 200,
            child: MainButton(title: s.kitchen_modifiers_create, leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text), action: () => _open())
          )
        ]
      ]),
      SizedBox(height: AppSize.spaceS),
      Expanded(child: switch (service.status) {
        ModifiersStatus.idle || ModifiersStatus.loading => const Center(child: Loading()),
        ModifiersStatus.error => SectionMessage(
          icon: CI.info,
          title: s.kitchen_modifiers_error,
          action: () => service.load(force: true),
          actionLabel: s.knowledge_retry
        ),
        ModifiersStatus.empty => SectionMessage(
          icon: CI.plus,
          title: s.kitchen_modifiers_empty,
          subtitle: s.kitchen_modifiers_empty_note,
          action: _canEdit ? () => _open() : null,
          actionLabel: _canEdit ? s.kitchen_modifiers_create : null,
          actionIcon: CI.plus
        ),
        ModifiersStatus.ready => ListView.separated(
          itemCount: service.groups.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
          itemBuilder: (context, index) {
            final group = service.groups[index];

            return ModifierRow(group: group, onTap: () => _open(group: group));
          }
        )
      })
    ]);
  }
}
