import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

import './branch_row.dart';
import './branches_heading.dart';

/// The panel over the map: what the tab is, a search, and the company's
/// branches, the main one always first.
///
/// The list is `BusinessBranchesService`, provided by the business page:
/// switching tabs keeps what was read. The search filters what was read, it
/// does not ask the backend: a company has few branches.
///
/// [onSelect] receives the branch tapped in the list.
class BranchesPanel extends StatefulWidget {
  const BranchesPanel({super.key, required this.onSelect});

  final void Function(BusinessBranchModel branch) onSelect;

  @override
  State<BranchesPanel> createState() => _BranchesPanelState();
}

class _BranchesPanelState extends State<BranchesPanel> {
  /// Its own form: without one the input owns a throwaway form and releases
  /// it when unmounted, leaving this controller with a disposed focus node.
  final _form = FormController();
  late final _search = InputController.search(form: _form);

  String _query = "";

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
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessBranchesService>();
    final scheme = ThemeColor.of(context);

    // The side bar's edge and shadow: the panel floats over the map the way
    // the bar floats over the page.
    return Container(
      padding: EdgeInsets.all(AppSize.gap),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSize.spaceS)
      ),
      child: Container(
        padding: EdgeInsets.all(AppSize.padding),
        decoration: BoxDecoration(
          color: scheme.navBar,
          border: Border.all(color: scheme.line),
          borderRadius: BorderRadius.circular(AppSize.spaceS)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BranchesHeading(
              count: service.status == BusinessBranchesStatus.ready ? service.branches.length : null
            ),
            SizedBox(height: AppSize.spaceS),
            SearchInput(
              controller: _search,
              placeholder: S.of(context).business_branches_search,
              onSearch: (value) => setState(() => _query = value.trim().toLowerCase())
            ),
            SizedBox(height: AppSize.spaceS),
            Expanded(child: _list(context, service))
          ]
        )
      ),
    );
  }

  Widget _list(BuildContext context, BusinessBranchesService service) {
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

    final branches = _shown(service.branches);

    if (branches.isEmpty) {
      return Center(child: TextSmall(
        S.of(context).business_branches_no_match,
        color: ThemeColor.of(context).text.secondary
      ));
    }

    // Rows are flat and close: the fill of the pointed-at one is what
    // separates it, not a card around each.
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: branches.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSize.gap * 0.5),
      itemBuilder: (_, index) => BranchRow(
        branch: branches[index],
        onTap: () => widget.onSelect(branches[index])
      )
    );
  }

  /// The branches that match the search, the main one first. The backend
  /// already sends it first; it is put there again so the panel does not
  /// depend on that order.
  List<BusinessBranchModel> _shown(List<BusinessBranchModel> branches) => [
    for (final branch in branches) if (branch.main && _matches(branch)) branch,
    for (final branch in branches) if (!branch.main && _matches(branch)) branch
  ];

  bool _matches(BusinessBranchModel branch) =>
    _query.isEmpty ||
    branch.name.toLowerCase().contains(_query) ||
    branch.place.toLowerCase().contains(_query);
}
