import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';

/// Which questions the list shows, by what the company has to do with them.
enum KnowledgeFilter {
  all,

  /// Waiting for their context: the work this section asks for.
  pending,

  /// Lyra gives them today.
  active,

  /// Answered and not given today: turned off, not started or ended.
  inactive;

  bool accepts(KnowledgeEntry entry) => switch (this) {
    all => true,
    pending => entry.isPending,
    active => entry.state == KnowledgeState.active,
    inactive => !entry.isPending && entry.state != KnowledgeState.active
  };
}

/// What narrows the list: the filter and the branch. Screen state, not the
/// service's: the service holds what the company wrote, this holds what the
/// person is looking at, and both are dropped with the section.
class KnowledgeView extends ChangeNotifier {
  KnowledgeFilter _filter = KnowledgeFilter.all;

  /// [allBranches], [companyWide] or a branch id.
  String _branch = allBranches;

  static const String allBranches = "";

  /// The answers that hold for every branch.
  static const String companyWide = "__company__";

  KnowledgeFilter get filter => _filter;
  String get branch => _branch;

  bool get isFiltered => _filter != KnowledgeFilter.all || _branch != allBranches;

  void show(KnowledgeFilter filter) {
    if (filter == _filter) return;

    _filter = filter;
    notifyListeners();
  }

  void inBranch(String branch) {
    if (branch == _branch) return;

    _branch = branch;
    notifyListeners();
  }

  /// Whether [entry] is in the branch picked. Ignores the filter, so the
  /// filter chips can count within the branch.
  bool inPlace(KnowledgeEntry entry) => switch (_branch) {
    allBranches => true,
    companyWide => entry.branch == null,
    _ => entry.branch?.id == _branch
  };

  bool accepts(KnowledgeEntry entry) => inPlace(entry) && _filter.accepts(entry);
}
