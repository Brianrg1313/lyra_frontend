import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/settings/profile_tag.dart';

/// One branch, as a card of the grid: its icon and name on top — the main one
/// tagged there —, what kind of place it is below, and at the foot where it is
/// and its phone. Touching it opens it to edit.
class BranchCard extends StatelessWidget {
  const BranchCard({super.key, required this.branch, required this.onTap});

  final BusinessBranchModel branch;
  final void Function() onTap;

  /// Height of the card. Fixed so every row of the grid measures the same,
  /// whether or not a branch has a phone or a two-line address.
  static double get height => AppSize.action * 3.4;

  /// Max width of a grid column: room for the name next to the main tag, and
  /// for an address to read in two lines.
  static double get maxWidth => AppSize.action * 7;

  /// How the grid is laid out: how many cards fit per row, how much each one
  /// measures and how much air goes between them.
  static SliverGridDelegate get grid =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxWidth,
      mainAxisExtent: height,
      crossAxisSpacing: AppSize.gap,
      mainAxisSpacing: AppSize.gap
    );

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final place = branch.place;

    return FeedbackButton(
      action: onTap,
      padding: EdgeInsets.all(AppSize.spaceXS),
      radius: AppSize.corner,
      color: scheme.surfaceOver,
      feedbackColor: scheme.surfaceFeedback,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: AppSize.button,
              height: AppSize.button,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(
                  AppSize.cornerInset(AppSize.spaceXS)
                )
              ),
              child: Center(child: Icon(
                branch.main ? CI.home : CI.shop,
                size: AppSize.text * 1.2,
                color: branch.main ? scheme.primary : scheme.icon
              ))
            ),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: TextMedium(branch.name, bold: true, ellipsis: true)),
            if (branch.main) ...[
              SizedBox(width: AppSize.gap),
              ProfileTag(
                icon: CI.home,
                label: S.of(context).business_branch_main,
                color: scheme.primary
              )
            ]
          ]),
          SizedBox(height: AppSize.gap),
          // The card's height is fixed, so the tags never push a second line:
          // on a narrow column what does not fit is cut.
          Wrap(
            spacing: AppSize.spaceXS,
            clipBehavior: Clip.hardEdge,
            children: [
              ProfileTag(
                icon: branch.storefront ? CI.store : CI.shop,
                label: branch.storefront
                  ? S.of(context).business_branch_kind_store
                  : S.of(context).business_branch_kind_warehouse,
                color: scheme.text.secondary
              ),
              if (branch.online) ProfileTag(
                icon: CI.chat,
                label: S.of(context).business_branch_online,
                color: scheme.text.secondary
              )
            ]
          ),
          const Spacer(),
          TextSmall(
            place.isEmpty ? S.of(context).business_branch_no_address : place,
            lines: 2,
            ellipsis: true,
            color: scheme.text.secondary
          ),
          if (branch.phone.isNotEmpty) ...[
            SizedBox(height: AppSize.gap * 0.5),
            Row(children: [
              Icon(CI.phone, size: AppSize.text, color: scheme.text.secondary),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextSmall(
                branch.phone,
                ellipsis: true,
                color: scheme.text.secondary
              ))
            ])
          ]
        ]
      )
    );
  }
}
