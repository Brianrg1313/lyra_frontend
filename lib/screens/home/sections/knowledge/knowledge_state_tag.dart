import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';

import './knowledge_format.dart';

/// Whether Lyra gives a question today, next to it.
///
/// The state is the backend's (it knows the company's day); this only says
/// it. Waiting is the brand colour, not a red: nothing broke, something is to
/// be written. A question not given for its dates says which date.
class KnowledgeStateTag extends StatelessWidget {
  const KnowledgeStateTag({super.key, required this.entry});

  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    final (label, color) = switch (entry.state) {
      KnowledgeState.pending => (s.knowledge_state_pending, scheme.accent),
      KnowledgeState.off => (s.knowledge_state_off, scheme.text.secondary),
      KnowledgeState.scheduled => (
        s.knowledge_state_scheduled(knowledgeDay(context, entry.from ?? "")),
        scheme.text.secondary
      ),
      KnowledgeState.expired => (
        s.knowledge_state_expired(knowledgeDay(context, entry.until ?? "")),
        scheme.text.secondary
      ),
      KnowledgeState.active => (s.knowledge_state_active, scheme.primary)
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(label, color: color)
    );
  }
}
