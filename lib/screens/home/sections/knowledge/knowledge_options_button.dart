import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/services/knowledge/knowledge_service.dart';

// WIDGETS
import 'package:core/form.dart';

/// The options of a question, in a dropdown anchored to this button: turning
/// it off or on, and deleting it.
///
/// A question waiting for its context has no switch to offer — Lyra does not
/// use it either way — so it only offers deleting it: what is done with a
/// question nobody will answer.
class KnowledgeOptionsButton extends StatelessWidget {
  const KnowledgeOptionsButton({super.key, required this.entry});

  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => _open(context),
    width: AppSize.action,
    height: AppSize.action,
    color: ThemeColor.of(context).surfaceOver,
    message: S.of(context).knowledge_options,
    child: Center(child: Icon(
      CI.dots_horizontal,
      size: AppSize.text * 1.2,
      color: ThemeColor.of(context).icon
    ))
  );

  Future<void> _open(BuildContext context) async {
    final s = S.of(context);

    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        if (!entry.isPending) SelectOption(
          value: "toggle",
          placeholder: entry.enabled ? s.knowledge_turn_off : s.knowledge_turn_on,
          icon: entry.enabled ? Icons.pause_circle_outline : Icons.play_circle_outline
        ),
        SelectOption(value: "delete", placeholder: s.knowledge_delete, icon: CI.trash)
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "toggle":
        await _toggle(context);
      case "delete":
        await _delete(context);
    }
  }

  /// Nothing is asked: the same click undoes it, and nothing is lost.
  Future<void> _toggle(BuildContext context) async {
    final message = entry.enabled
      ? S.of(context).knowledge_turned_off
      : S.of(context).knowledge_turned_on;

    final done = await context.read<KnowledgeService>().toggle(context, entry);

    if (done) FloatFlag.of().message(message);
  }

  /// Asked first, naming the question, with the alternative that keeps it.
  Future<void> _delete(BuildContext context) async {
    final s = S.of(context);

    final confirmed = await showAlertModal(
      context: context,
      title: s.knowledge_delete_title,
      message: s.knowledge_delete_message(entry.question),
      confirmText: s.knowledge_delete,
      cancelText: s.cancel
    );

    if (!confirmed || !context.mounted) return;

    // Built before: the row leaves the list when it goes.
    final done = s.knowledge_deleted;

    final deleted = await context.read<KnowledgeService>().remove(context, entry);

    if (deleted) FloatFlag.of().message(done);
  }
}
