import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/knowledge/knowledge_service.dart';

import './knowledge_page.dart';
import './state/knowledge_view.dart';

/// Frequent questions: the content of the `knowledge` home section.
///
/// What Lyra knows to answer when a customer asks how the business works —
/// wholesale, warranties, hours, deadlines— and what customers asked that
/// nobody answered yet. Each question carries a context: not the reply Lyra
/// sends, but what she needs to know about the topic, said in her own voice
/// with nothing added to it. Lyra looks one up only on the turn a customer
/// asks something like it, so a policy written here costs nothing until it
/// is asked, unlike the channel's context, which travels in every message.
///
/// Questions arrive two ways: written here, or left by Lyra from a question a
/// customer asked that she promised to confirm. Those come without a context
/// and wait for one — that is the work this section asks for, so it opens
/// with them in view.
///
/// Owns its state: the questions, the branches the form offers and what the
/// list is narrowed to. The home remounts it on a business switch, which
/// drops all three.
class KnowledgeSection extends StatefulWidget {
  const KnowledgeSection({super.key});

  @override
  State<KnowledgeSection> createState() => _KnowledgeSectionState();
}

class _KnowledgeSectionState extends State<KnowledgeSection> {
  final _service = KnowledgeService();
  final _branches = BusinessBranchesService();
  final _view = KnowledgeView();

  @override
  void initState() {
    super.initState();

    // The loads notify; deferred so nothing rebuilds while the tree mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _service.load();
      _branches.load();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    _branches.dispose();
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _service),
      ChangeNotifierProvider.value(value: _branches),
      ChangeNotifierProvider.value(value: _view)
    ],
    child: const KnowledgePage()
  );
}
