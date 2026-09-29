import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/home/sections/business/settings/profile_tag.dart';
import 'package:app/screens/modals/business/branch_form/_branch_form.dart';

/// Branches tab: the places the company works from, the main one first, and
/// the button that opens a new one. Touching a branch opens the same form to
/// edit it — the main branch's location included: this is where the company's
/// address is edited.
///
/// The grid is `BusinessBranchesService`, provided by the business page:
/// switching tabs keeps what was read.
class BusinessBranchesTab extends StatefulWidget {
  const BusinessBranchesTab({super.key});

  @override
  State<BusinessBranchesTab> createState() => _BusinessBranchesTabState();
}

class _BusinessBranchesTabState extends State<BusinessBranchesTab> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame: the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessBranchesService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessBranchesService>();
    final failed = service.status == BusinessBranchesStatus.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(onAdd: failed ? null : () => _open(context, service)),
        SizedBox(height: AppSize.padding),
        Expanded(child: _body(context, service))
      ]
    );
  }

  Widget _body(BuildContext context, BusinessBranchesService service) {
    if (service.status == BusinessBranchesStatus.error) {
      return SectionMessage(
        icon: CI.info,
        title: S.of(context).business_branches_error_title,
        subtitle: S.of(context).business_branches_error_subtitle,
        action: () => service.load(force: true),
        actionLabel: S.of(context).business_list_retry
      );
    }

    if (service.status != BusinessBranchesStatus.ready) {
      return const Center(child: Loading());
    }

    // The backend creates the main branch with the company, so an empty list
    // is rare — but it is an answer, not a failure.
    if (service.branches.isEmpty) {
      return SectionMessage(
        icon: CI.shop,
        title: S.of(context).business_branches_empty_title,
        subtitle: S.of(context).business_branches_empty_subtitle
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: service.branches.length,
      gridDelegate: _BranchCard.grid,
      itemBuilder: (_, index) => _BranchCard(
        branch: service.branches[index],
        onTap: () => _open(context, service, service.branches[index])
      )
    );
  }

  /// A new branch without [branch], that one edited with it. The country is
  /// the company's: every branch is in it.
  Future<void> _open(
    BuildContext context,
    BusinessBranchesService service, [
    BusinessBranchModel? branch
  ]) => showBranchForm(
    context,
    branches: service,
    country: context.read<BusinessService>().profile?.country ?? "",
    branch: branch
  );
}

/// What the tab is, one line that says what it is for, and its one action.
///
/// Without [onAdd] no button is drawn: a list that could not be read does not
/// offer to grow.
class _Heading extends StatelessWidget {
  const _Heading({this.onAdd});

  final void Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextMedium(S.of(context).business_branches_title, bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              S.of(context).business_branches_subtitle,
              lines: 2,
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        )),
        if (onAdd != null) ...[
          SizedBox(width: AppSize.spaceS),
          Button(
            width: null,
            title: S.of(context).business_branches_add,
            leftIcon: Icon(CI.plus, color: scheme.button.text),
            action: onAdd!
          )
        ]
      ]
    );
  }
}

/// One branch, as a card of the grid: its icon and name on top — the main one
/// tagged there —, what kind of place it is below, and at the foot where it is
/// and its phone. Touching it opens it to edit.
class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.onTap});

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
