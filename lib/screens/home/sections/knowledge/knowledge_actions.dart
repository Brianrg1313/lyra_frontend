import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/services/knowledge/knowledge_request.dart';
import 'package:app/services/knowledge/knowledge_service.dart';

// WIDGETS
import 'package:app/screens/modals/knowledge/knowledge_form/_knowledge_form.dart';

/// Opens the question form —a new one without [entry]— and writes what it
/// collected. The bar's button, the empty state, the banner and every row
/// open it, so it lives once here.
///
/// The form is a modal, above the section's providers: the branches go in as
/// a parameter and the write happens here, with the section's service.
Future<void> openKnowledgeForm(BuildContext context, {KnowledgeEntry? entry}) async {
  final service = context.read<KnowledgeService>();
  final branches = context.read<BusinessBranchesService>();

  final draft = await showKnowledgeForm(
    context,
    entry: entry,
    branches: branches.branches,
    branchesFailed: branches.status == BusinessBranchesStatus.error
  );

  if (draft == null || !context.mounted) return;

  // Built before the write: a saved question can leave the filter on screen,
  // and the row that opened it with it.
  final saved = S.of(context).knowledge_saved;

  final done = entry == null
    ? await service.create(context, createKnowledgeRequest(draft))
    : await service.edit(context, editKnowledgeRequest(id: entry.id, draft: draft));

  if (done) FloatFlag.of().message(saved);
}
