import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_product_search.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/kitchen/recipe_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/modals/kitchen/shared/kitchen_chip.dart';
import 'package:app/screens/modals/kitchen/shared/kitchen_product_picker.dart';

import './modifier_option_card.dart';

/// What the group form collected: the group to write, or [delete] to remove it.
typedef ModifierGroupDraft = ({
  String name,
  int min,
  int? max,
  List<ModifierProduct> products,
  List<ModifierOption> options,
  bool delete
});

/// Opens the form of a modifier group — a new one without [group]. Writes nothing: answers the
/// draft, or `null` when closed. Without [canEdit] it is read only.
///
/// Opened from a product's form, [pinned] names that product: it offers the group whatever the
/// list says (it may not exist yet), so it is drawn first and can't be taken off; there the
/// group is not deleted either ([deletable]), only no longer offered. A new group starts on
/// [min] / [max] and [title].
Future<ModifierGroupDraft?> showModifierGroupForm(
  BuildContext context, {
  ModifierGroup? group,
  bool canEdit = true,
  String? pinned,
  bool deletable = true,
  int min = 0,
  int? max,
  String? title
}) =>
  showSideModal(
    context: context,
    title: group?.name ?? title ?? S.of(context).kitchen_modifiers_create,
    builder: (context) => ModifierGroupModal(
      group: group,
      canEdit: canEdit,
      pinned: pinned,
      deletable: deletable,
      min: min,
      max: max
    )
  ).then((value) => value is ModifierGroupDraft ? value : null);

/// One group of modifiers (`cocina-frontend.md` §6): its name, how many options a line must
/// ([ModifierGroup.min]) and may ([ModifierGroup.max]) take — `1` and `1` is «choose one», and
/// the till can't charge without it —, the products that offer it, and its options.
///
/// An option's extras and what it removes from the recipe only work on a dish made to order;
/// one with only a price works on any product («with ice»). Every option keeps its id when
/// edited: open tickets name it by it.
class ModifierGroupModal extends StatefulWidget {
  const ModifierGroupModal({
    super.key,
    this.group,
    this.canEdit = true,
    this.pinned,
    this.deletable = true,
    this.min = 0,
    this.max
  });

  final ModifierGroup? group;
  final bool canEdit;

  /// The product whose form opened it, always among those offering it.
  final String? pinned;
  final bool deletable;

  /// A new group's rule.
  final int min;
  final int? max;

  @override
  State<ModifierGroupModal> createState() => _ModifierGroupModalState();
}

class _ModifierGroupModalState extends State<ModifierGroupModal> {
  final _names = KitchenProductSearch();

  late final _name = InputController(key: "NAME", max: 60, initial: widget.group?.name);
  late final _min = InputController(key: "MIN", pattern: "[0-9]", max: 3, initial: "${widget.group?.min ?? widget.min}");
  late final _max = InputController(key: "MAX", pattern: "[0-9]", max: 3, initial: (widget.group == null ? widget.max : widget.group!.max)?.toString());

  late final List<ModifierProduct> _products = [...?widget.group?.products];
  late final List<ModifierOptionDraft> _options = [
    for (final option in widget.group?.options ?? const <ModifierOption>[]) ModifierOptionDraft.of(option)
  ];

  /// Product id → name, for what the group already points at.
  final Map<String, String> _known = {};

  /// The recipes of the products that offer it: what an option can remove a line of.
  final Map<String, Recipe> _recipes = {};

  String _error = "";

  static const double _width = 560;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void dispose() {
    _names.dispose();
    _name.dispose();
    _min.dispose();
    _max.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  /// Names what a saved group points at and reads its products' recipes.
  Future<void> _resolve() async {
    final tables = {
      for (final product in _products) product.tableId,
      for (final option in _options) for (final line in option.lines) line.tableId
    };

    final names = tables.isEmpty ? const <String, String>{} : await _names.namesIn(tables);
    await Future.wait([for (final product in _products) _readRecipe(product.productId)]);

    if (!mounted) return;
    setState(() => _known.addAll(names));
  }

  Future<void> _readRecipe(String productId) async {
    final recipe = await RecipeService.fetch(productId);
    if (recipe != null && mounted) setState(() => _recipes[productId] = recipe);
  }

  String _nameOf(String productId) => _known[productId] ?? productId;

  void _addProduct(KitchenProduct product) {
    setState(() {
      _known[product.id] = product.label;
      _products.add((tableId: product.tableId, productId: product.id));
    });
    _readRecipe(product.id);
  }

  /// Every line of the offering products' recipes, as an option can remove it.
  List<({String id, String label})> get _removable => [
    for (final product in _products)
      for (final line in _recipes[product.productId]?.lines ?? const <RecipeLine>[])
        (id: line.id, label: "${line.name.isEmpty ? line.productId : line.name} (${_nameOf(product.productId)})")
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final edit = widget.canEdit;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitchenNote(text: s.kitchen_modifiers_form_note),
          Input(title: s.kitchen_modifiers_name, placeholder: s.kitchen_modifiers_name_hint, controller: _name),
          InputRow(
            title: s.kitchen_modifiers_rule,
            spacing: AppSize.gap,
            children: [
              Input(placeholder: s.kitchen_modifiers_min, controller: _min),
              Input(placeholder: s.kitchen_modifiers_max, controller: _max)
            ]
          ),
          KitchenNote(text: s.kitchen_modifiers_rule_note),
          SizedBox(height: AppSize.spaceXS),
          TextMedium(s.kitchen_modifiers_products_title, bold: true),
          KitchenNote(text: s.kitchen_modifiers_products_note),
          Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
            if (widget.pinned != null) KitchenChip(label: widget.pinned!),
            for (final product in _products) KitchenChip(
              label: _nameOf(product.productId),
              onRemove: edit ? () => setState(() => _products.remove(product)) : null
            )
          ]),
          if (edit) ...[
            SizedBox(height: AppSize.gap),
            KitchenProductPicker(
              placeholder: s.kitchen_modifiers_products_add,
              supplies: false,
              exclude: {for (final product in _products) product.productId},
              onPick: _addProduct
            )
          ],
          SizedBox(height: AppSize.spaceS),
          TextMedium(s.kitchen_modifiers_options_title, bold: true),
          KitchenNote(text: s.kitchen_modifiers_options_note),
          for (final option in _options) ModifierOptionCard(
            key: ObjectKey(option),
            option: option,
            enabled: edit,
            nameOf: _nameOf,
            removable: _removable,
            onChanged: (names) => setState(() => _known.addAll(names)),
            onRemove: () => setState(() {
              _options.remove(option);
              option.dispose();
            })
          ),
          if (edit) Button(
            title: s.kitchen_modifiers_option_add,
            leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
            action: () => setState(() => _options.add(ModifierOptionDraft.of(null)))
          ),
          if (_error.isNotEmpty) KitchenNote(text: _error, color: scheme.snackBar.error),
          if (edit) ...[
            SizedBox(height: AppSize.spaceM),
            MainButton(title: s.save, action: _submit),
            if (widget.group != null && widget.deletable) ...[
              SizedBox(height: AppSize.spaceXS),
              Button(title: s.kitchen_modifiers_delete, leftIcon: Icon(CI.trash, color: ThemeColor.of(context).button.text), action: _delete)
            ]
          ]
        ]
      )
    );
  }

  void _submit() {
    final s = S.of(context);
    final name = _name.text.trim();
    final min = int.tryParse(_min.text.trim()) ?? 0;
    final max = _max.text.trim().isEmpty ? null : int.tryParse(_max.text.trim());
    final options = <ModifierOption>[];

    for (final option in _options) {
      final built = option.build();
      if (built == null) return setState(() => _error = s.kitchen_modifiers_option_invalid);

      options.add(built);
    }

    final error = name.isEmpty
      ? s.kitchen_modifiers_name_empty
      : options.isEmpty ? s.kitchen_modifiers_options_empty
      : max != null && (max < min || max < 1) || min > options.length ? s.kitchen_modifiers_rule_invalid
      : "";

    if (error.isNotEmpty) return setState(() => _error = error);

    Navigator.pop(context, (name: name, min: min, max: max, products: _products, options: options, delete: false));
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final group = widget.group!;

    final confirmed = await showAlertModal(
      context: context,
      title: s.kitchen_modifiers_delete_title,
      message: s.kitchen_modifiers_delete_message(group.name),
      confirmText: s.kitchen_modifiers_delete,
      cancelText: s.cancel
    );

    if (!confirmed || !mounted) return;

    Navigator.pop(context, (name: group.name, min: group.min, max: group.max, products: group.products, options: group.options, delete: true));
  }
}
