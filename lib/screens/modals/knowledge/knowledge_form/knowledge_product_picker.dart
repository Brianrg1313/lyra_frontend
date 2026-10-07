import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/services/knowledge/knowledge_product_search.dart';

// WIDGETS
import 'package:core/form.dart';

/// The products a question is about: the ones picked, as chips that come off
/// with a click, and a search that adds more.
///
/// The search is the panel's own (`POST /knowledge/products/`, the register's
/// catalog behind the `knowledge` permission) and lives as long as this
/// picker: the form is a modal, above the section's providers.
class KnowledgeProductPicker extends StatefulWidget {
  const KnowledgeProductPicker({
    super.key,
    required this.selected,
    required this.onAdd,
    required this.onRemove
  });

  final List<KnowledgeProduct> selected;
  final void Function(KnowledgeProduct product) onAdd;
  final void Function(KnowledgeProduct product) onRemove;

  /// The backend's ceiling (`Knowledge.#maxProducts`).
  static const int max = 20;

  @override
  State<KnowledgeProductPicker> createState() => _KnowledgeProductPickerState();
}

class _KnowledgeProductPickerState extends State<KnowledgeProductPicker> {
  final _search = KnowledgeProductSearch();

  /// Owned by its input, which disposes it: it belongs to no form.
  final _query = InputController.search(key: "KNOWLEDGE_PRODUCT_SEARCH");

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _full => widget.selected.length >= KnowledgeProductPicker.max;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selected.isNotEmpty) Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceXS),
          child: Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: [
              for (final product in widget.selected) _Chip(
                label: product.name.isEmpty ? product.id : product.name,
                onRemove: () => widget.onRemove(product)
              )
            ]
          )
        ),
        if (_full)
          TextSmall(
            S.of(context).knowledge_form_products_max,
            color: scheme.text.secondary
          )
        else ...[
          SearchInput(
            controller: _query,
            placeholder: S.of(context).knowledge_form_products_search,
            onSearch: _search.search
          ),
          ListenableBuilder(
            listenable: _search,
            builder: (context, _) => _results(context)
          )
        ]
      ]
    );
  }

  Widget _results(BuildContext context) {
    final scheme = ThemeColor.of(context);

    switch (_search.status) {
      case KnowledgeProductSearchStatus.idle:
        return const SizedBox.shrink();
      case KnowledgeProductSearchStatus.loading:
        return Padding(
          padding: EdgeInsets.all(AppSize.spaceS),
          child: const Center(child: Loading())
        );
      case KnowledgeProductSearchStatus.error:
        return _Note(text: S.of(context).knowledge_form_products_error);
      case KnowledgeProductSearchStatus.ready:
        final results = _search.results
          .where((product) => !widget.selected.contains(product))
          .toList();

        if (results.isEmpty) {
          return _Note(text: S.of(context).knowledge_form_products_empty);
        }

        return Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Column(children: [
            for (final product in results) FeedbackButton(
              action: () => widget.onAdd(product),
              color: scheme.surfaceOver,
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.spaceS,
                vertical: AppSize.spaceXS
              ),
              child: Row(children: [
                Icon(CI.product, size: AppSize.text, color: scheme.icon),
                SizedBox(width: AppSize.gap),
                Expanded(child: TextSmall(
                  product.name.isEmpty ? product.id : product.name,
                  ellipsis: true
                )),
                Icon(CI.plus, size: AppSize.text, color: scheme.icon)
              ])
            )
          ])
        );
    }
  }
}

/// A picked product, with the cross that takes it off.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});

  final String label;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: onRemove,
      color: scheme.surfaceOver,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.spaceS,
        vertical: AppSize.gap
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: TextSmall(label, ellipsis: true)
        ),
        SizedBox(width: AppSize.gap),
        Icon(CI.delete, size: AppSize.text * 0.9, color: scheme.text.secondary)
      ])
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: TextSmall(text, color: ThemeColor.of(context).text.secondary)
  );
}
