import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './knowledge_actions.dart';
import './knowledge_filters.dart';
import './knowledge_list.dart';
import './knowledge_pending_banner.dart';
import './state/knowledge_view.dart';

/// The body: the only listener of [KnowledgeService] — loading, failing, empty
/// or the list with what narrows it.
class KnowledgeBody extends StatelessWidget {
  const KnowledgeBody({super.key, required this.query});

  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<KnowledgeService>();
    final view = context.watch<KnowledgeView>();

    return switch (service.status) {
      KnowledgeStatus.loading || KnowledgeStatus.idle =>
        const Center(child: Loading()),
      KnowledgeStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).knowledge_error_title,
        subtitle: S.of(context).knowledge_error_subtitle,
        action: () => service.load(force: true),
        actionLabel: S.of(context).knowledge_retry
      ),
      KnowledgeStatus.empty => SectionMessage(
        icon: CI.help,
        title: S.of(context).knowledge_empty_title,
        subtitle: S.of(context).knowledge_empty_subtitle,
        action: () => openKnowledgeForm(context),
        actionLabel: S.of(context).knowledge_create,
        actionIcon: CI.plus
      ),
      KnowledgeStatus.ready => Column(children: [
        // Said once the person is not already looking at them.
        if (service.pending > 0 && view.filter != KnowledgeFilter.pending)
          KnowledgePendingBanner(count: service.pending, onShow: () => view.show(KnowledgeFilter.pending)),
        const KnowledgeFilters(),
        SizedBox(height: AppSize.spaceXS),
        Expanded(child: KnowledgeList(entries: service.entries, view: view, query: query))
      ])
    };
  }
}
