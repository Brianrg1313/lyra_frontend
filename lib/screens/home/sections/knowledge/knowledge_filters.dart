import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/knowledge/knowledge_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/filter_chip.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';
import 'package:core/form.dart';

import './state/knowledge_view.dart';

/// What narrows the list: by what is to be done with a question (each chip
/// with how many there are, counted inside the branch picked) and by branch.
///
/// The branch chip is drawn only where there is a choice: a company with one
/// place, whose questions hold for it, has nothing to pick.
///
/// It scrolls rather than wraps: one row, anchored at its left edge.
class KnowledgeFilters extends StatelessWidget {
  const KnowledgeFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<KnowledgeService>();
    final branches = context.watch<BusinessBranchesService>().branches;
    final view = context.watch<KnowledgeView>();
    final s = S.of(context);

    final inPlace = service.entries.where(view.inPlace).toList();
    int count(KnowledgeFilter filter) => inPlace.where(filter.accepts).length;

    final scoped = branches.length > 1 || service.entries.any((entry) => entry.branch != null);

    final chips = [
      (KnowledgeFilter.all, s.knowledge_filter_all, CI.list),
      (KnowledgeFilter.pending, s.knowledge_filter_pending, CI.message_ai),
      (KnowledgeFilter.active, s.knowledge_filter_active, CI.chack_circle),
      (KnowledgeFilter.inactive, s.knowledge_filter_inactive, CI.eye_hidden)
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (filter, title, icon) in chips) ...[
            SectionFilterChip(
              icon: icon,
              title: "$title · ${count(filter)}",
              isActive: view.filter == filter,
              action: () => view.show(filter)
            ),
            SizedBox(width: AppSize.gap)
          ],
          if (scoped) SectionMenuChip(
            icon: CI.store,
            title: _branchTitle(context, view, branches),
            isActive: view.branch != KnowledgeView.allBranches,
            selected: view.branch,
            options: [
              SelectOption(value: KnowledgeView.allBranches, placeholder: s.knowledge_filter_branch_all),
              SelectOption(value: KnowledgeView.companyWide, placeholder: s.knowledge_filter_branch_company),
              for (final branch in branches)
                SelectOption(value: branch.id, placeholder: branch.name)
            ],
            onSelected: view.inBranch,
            emptyText: s.knowledge_filter_branch_empty
          )
        ])
      )
    );
  }

  String _branchTitle(
    BuildContext context,
    KnowledgeView view,
    List<BusinessBranchModel> branches
  ) {
    final s = S.of(context);

    return switch (view.branch) {
      KnowledgeView.allBranches => s.knowledge_filter_branch_all,
      KnowledgeView.companyWide => s.knowledge_filter_branch_company,
      final id => branches
        .where((branch) => branch.id == id)
        .map((branch) => branch.name)
        .firstOrNull ?? s.knowledge_filter_branch_all
    };
  }
}
