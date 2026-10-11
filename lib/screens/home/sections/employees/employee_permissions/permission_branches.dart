import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/permissions/member_permissions_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_chip.dart';

/// Where the person works and which structure the sheets below are (`sedes-frontend.md` §4):
/// a chip per branch (every one on is "every branch"), then the structure: the base, or one
/// branch's own, which replaces the base there. Drawn only with several branches.
class PermissionBranches extends StatefulWidget {
  const PermissionBranches({super.key, required this.service, required this.onReset});

  final MemberPermissionsService service;

  /// Puts the open branch back on the base, after asking.
  final void Function() onReset;

  @override
  State<PermissionBranches> createState() => _PermissionBranchesState();
}

class _PermissionBranchesState extends State<PermissionBranches> {
  static const String _base = "";

  /// One picker per open structure: a select writes its label from its value when it mounts,
  /// so a structure closed from elsewhere (its branch taken off) gets a new one.
  InputController? _structure;
  String? _structureOf;

  InputController _picker(String? branch) {
    final current = _structure;
    if (current != null && _structureOf == branch) return current;

    if (current != null) WidgetsBinding.instance.addPostFrameCallback((_) => current.form.dispose());

    _structureOf = branch;
    return _structure = InputController.select(key: "structure", initial: branch ?? _base);
  }

  @override
  void dispose() {
    _structure?.form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final member = service.member;
    final branches = BranchService().branches;
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    if (member == null) return const SizedBox.shrink();

    final works = service.works;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (service.placeable) ...[
          TextSmall(s.permission_works_in, color: scheme.text.secondary),
          SizedBox(height: AppSize.gap),
          Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: [
              SectionFilterChip(
                title: s.permission_works_everywhere,
                isActive: works == null,
                action: service.worksEverywhere
              ),
              for (final branch in branches) SectionFilterChip(
                title: branch.name,
                icon: (works == null || works.contains(branch.id)) ? CI.check : null,
                isActive: works != null && works.contains(branch.id),
                action: () => service.toggleWorks(branch.id)
              )
            ]
          ),
          SizedBox(height: AppSize.spaceS)
        ],
        if (service.branchable) ...[
          SelectInput(
            key: ValueKey(service.branch),
            controller: _picker(service.branch),
            title: s.permission_structure_title,
            placeholder: s.permission_structure_base,
            searchable: false,
            emptyText: s.permission_template_empty,
            options: [
              SelectOption(
                value: _base,
                placeholder: s.permission_structure_base,
                subtitle: s.permission_structure_base_note
              ),
              for (final branch in branches)
                if (works == null || works.contains(branch.id)) SelectOption(
                  value: branch.id,
                  placeholder: branch.name,
                  subtitle: member.byBranch.containsKey(branch.id)
                    ? s.permission_structure_own
                    : s.permission_structure_inherits
                )
            ],
            onSelected: (option) => service.editIn(option.value.isEmpty ? null : option.value)
          ),
          if (service.branch != null) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: Row(children: [
              Expanded(child: TextSmall(
                service.inherits
                  ? s.permission_structure_inherits_note(BranchService().nameOf(service.branch))
                  : s.permission_structure_own_note(BranchService().nameOf(service.branch)),
                lines: 2,
                color: scheme.text.secondary
              )),
              if (!service.inherits) FocusableWidget(
                action: service.saving ? null : widget.onReset,
                message: s.permission_structure_reset,
                child: TextSmall(s.permission_structure_reset, color: scheme.accent)
              )
            ])
          ),
          SizedBox(height: AppSize.spaceXS)
        ]
      ]
    );
  }
}
