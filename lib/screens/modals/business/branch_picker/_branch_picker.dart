import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/branches/branch_glyph.dart';

/// Asks which branch the person works in, and works in the one picked (`BranchService.select`).
/// Closing it without picking keeps the branch the header already carries.
Future<void> showBranchPicker(BuildContext context) => showModal(
  context: context,
  title: S.of(context).branch_picker_title,
  builder: (context) => const BranchPickerModal()
);

/// The branches the person may work in, the main one first, each with where it is.
class BranchPickerModal extends StatelessWidget {
  const BranchPickerModal({super.key});

  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final service = BranchService();
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).branch_picker_subtitle,
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          for (final branch in service.branches) BranchChoice(
            branch: branch,
            selected: branch.id == service.activeId,
            onTap: () {
              service.select(branch.id);
              Navigator.pop(context);
            }
          )
        ]
      )
    );
  }
}

/// One branch to pick: its mark, name and address, a check on the one in use.
class BranchChoice extends StatelessWidget {
  const BranchChoice({super.key, required this.branch, required this.selected, required this.onTap});

  final BusinessBranchModel branch;
  final bool selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final place = branch.place;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: FeedbackButton(
        action: onTap,
        color: selected ? scheme.surfaceOver : null,
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          BranchGlyph(branch: branch, lit: selected, size: AppSize.action - AppSize.spaceXS),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(branch.name, ellipsis: true),
              TextSmall(
                place.isEmpty ? S.of(context).business_branch_no_address : place,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          )),
          if (selected) Icon(CI.check, size: AppSize.text * 1.2, color: scheme.primary)
        ])
      )
    );
  }
}
