import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/business/branch_form/_branch_form.dart';

import './branch_card.dart';
import './branches_heading.dart';

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
        BranchesHeading(onAdd: failed ? null : () => _open(context, service)),
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
      gridDelegate: BranchCard.grid,
      itemBuilder: (_, index) => BranchCard(
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
