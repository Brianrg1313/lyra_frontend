import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/kitchen/recipe_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';
import 'package:app/screens/modals/supply_chain/discard_dish/_discard_dish.dart';
import 'package:app/screens/modals/supply_chain/presentations/_presentations.dart';
import 'package:app/screens/modals/supply_chain/produce_batch/_produce_batch.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

import './recipe_editor.dart';

/// Opens [product]'s panel: its recipe, what it makes now, its 86, batches, lost dishes and how
/// it is bought. Answers whether anything was written, so the list measures it again.
Future<bool> showRecipePanel(BuildContext context, {required KitchenProduct product}) async {
  var changed = false;

  await showSideModal(
    context: context,
    title: product.label,
    builder: (context) => RecipePanel(product: product, onChanged: () => changed = true)
  );

  return changed;
}

/// One product's kitchen page (`cocina-frontend.md` §3, §4, §7, §8): a made product's (from its
/// inventory row: what it consumes, written as part of the record) or a supply's (how it is
/// bought, where it is used, and its preparation when the kitchen makes it). A catalog product
/// consumes nothing and has none.
///
/// Owns its [RecipeService], read when it opens and dropped when it closes. What it offers
/// follows the person's grants (`supply_chain.recipes.*`) and the recipe's mode: a batch is
/// produced, a dish made to order is lost; a dish made to order has no presentations (it is
/// never bought).
class RecipePanel extends StatefulWidget {
  const RecipePanel({super.key, required this.product, required this.onChanged, this.service});

  final KitchenProduct product;
  final void Function() onChanged;

  /// An already read one, for tests: it is not read again, nor disposed here.
  @visibleForTesting
  final RecipeService? service;

  @override
  State<RecipePanel> createState() => _RecipePanelState();
}

class _RecipePanelState extends State<RecipePanel> {
  late final _service = widget.service ?? RecipeService(product: widget.product);

  /// Whether the recipe is being written (always, once «Create recipe» is pressed).
  bool _editing = false;
  bool _busy = false;

  static const double _width = 620;

  @override
  void initState() {
    super.initState();
    if (widget.service == null) _service.load();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  bool _can(String action) => PermissionsService().can("supply_chain.recipes.$action");

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: ListenableBuilder(listenable: _service, builder: (context, _) => _body(context))
  );

  Widget _body(BuildContext context) {
    final s = S.of(context);

    switch (_service.status) {
      case RecipeStatus.loading:
        return Padding(padding: EdgeInsets.all(AppSize.spaceL), child: const Center(child: Loading()));
      case RecipeStatus.error:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          KitchenNote(text: s.supply_chain_recipe_error),
          Button(title: s.knowledge_retry, action: _service.load)
        ]);
      case RecipeStatus.none:
      case RecipeStatus.ready:
        break;
    }

    final recipe = _service.recipe;

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recipe != null) ..._made(context, recipe),
        if (_editing)
          RecipeEditor(
            recipe: recipe,
            supplies: widget.product.supplies,
            canEdit: _can("edit"),
            exclude: {widget.product.id},
            onSave: _save,
            onCancel: () => setState(() => _editing = false)
          )
        else if (recipe == null)
          ..._none(context)
        else
          ..._lines(context, recipe),
        if (_showsPresentations(recipe)) ..._presentations(context)
      ]
    );
  }

  /// What it makes now, its 86 and what the kitchen does with it.
  List<Widget> _made(BuildContext context, Recipe recipe) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final made = _service.availability;

    return [
      Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              RecipeTag(
                text: recipe.mode == RecipeMode.batch ? s.supply_chain_mode_batch : s.supply_chain_mode_order,
                color: scheme.accent
              ),
              if (recipe.paused) ...[
                SizedBox(width: AppSize.gap),
                RecipeTag(text: s.supply_chain_paused, color: scheme.snackBar.error)
              ]
            ]),
            SizedBox(height: AppSize.gap),
            TextMedium(made == null ? s.supply_chain_made_unknown : recipeAvailabilityLine(context, made), lines: 2),
            if (made != null && made.short.isNotEmpty) TextSmall(
              s.supply_chain_short(made.short.map((line) => line.name).where((name) => name.isNotEmpty).join(", ")),
              lines: 2,
              color: scheme.text.secondary
            )
          ])),
          SizedBox(width: AppSize.spaceS),
          Tooltip(
            message: s.supply_chain_pause_note,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              TextSmall(recipe.paused ? s.supply_chain_sold_out : s.supply_chain_available, color: scheme.text.secondary),
              Switch(
                value: !recipe.paused,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: scheme.primary,
                onChanged: _can("pause") && !_busy ? (value) => _pause(!value) : null
              )
            ])
          )
        ])
      ),
      SizedBox(height: AppSize.spaceXS),
      Row(children: [
        if (recipe.mode == RecipeMode.batch && _can("produce"))
          Expanded(child: Button(title: s.supply_chain_produce, leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text), action: () => _produce(recipe))),
        if (recipe.mode == RecipeMode.order && _can("discard"))
          Expanded(child: Button(title: s.supply_chain_discard, leftIcon: Icon(CI.trash, color: ThemeColor.of(context).button.text), action: () => _discard(recipe)))
      ]),
      SizedBox(height: AppSize.spaceS)
    ];
  }

  /// Writes the recipe from the editor; `false` keeps it open (the backend refused it).
  Future<bool> _save(RecipeDraft draft) async {
    final s = S.of(context);
    final done = await _service.save(context, mode: draft.mode, lines: draft.lines, choices: draft.choices, names: draft.names);

    if (!done || !mounted) return done;

    FloatFlag.of(context).message(s.supply_chain_recipe_saved);
    setState(() => _editing = false);
    widget.onChanged();

    return true;
  }

  /// A product with no recipe: a supply bought ready (most of them), which keeps a shelf of its
  /// own; it can be made a preparation of the kitchen. A made product always has one: none is
  /// a read that found nothing, and writing it is the way back.
  List<Widget> _none(BuildContext context) {
    final s = S.of(context);
    final supply = widget.product.supplies;

    return [
      TextMedium(supply ? s.supply_chain_preparation_none : s.supply_chain_no_recipe, bold: true),
      KitchenNote(text: supply ? s.supply_chain_preparation_note : s.supply_chain_made_without_note),
      if (_can("edit")) Button(title: supply ? s.supply_chain_preparation_create : s.supply_chain_recipe_create, leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text), action: () => setState(() => _editing = true)),
      SizedBox(height: AppSize.spaceS)
    ];
  }

  /// The recipe as it is, read only, with its edit and delete.
  List<Widget> _lines(BuildContext context, Recipe recipe) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return [
      TextMedium(s.supply_chain_lines_title, bold: true),
      SizedBox(height: AppSize.gap),
      for (final line in recipe.lines) Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap / 2),
        child: Surface.over(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
          child: Row(children: [
            Expanded(child: TextSmall(line.name.isEmpty ? line.productId : line.name, ellipsis: true, bold: true)),
            TextSmall(kitchenQty(context, line.qty)),
            if (line.waste > 0) ...[
              SizedBox(width: AppSize.spaceS),
              TextSmall(s.supply_chain_line_waste_of(kitchenPercent(context, line.waste)), color: scheme.text.secondary)
            ],
            if (line.negotiable) ...[
              SizedBox(width: AppSize.spaceS),
              RecipeTag(text: s.supply_chain_line_negotiable, color: scheme.text.secondary)
            ]
          ])
        )
      ),
      for (final choice in recipe.choices) Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap / 2),
        child: Surface.over(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
          child: Row(children: [
            Icon(CI.list, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            if (choice.name.isNotEmpty) ...[
              TextSmall(choice.name, bold: true),
              SizedBox(width: AppSize.spaceS)
            ],
            Expanded(child: TextSmall(
              s.recipe_choice_read(choice.choose, choice.options.map((option) => option.name.isEmpty ? option.productId : option.name).join(", ")),
              lines: 2
            ))
          ])
        )
      ),
      if (recipe.updated != null) KitchenNote(text: s.supply_chain_recipe_updated(kitchenDay(context, recipe.updated!), recipe.version)),
      if (_can("edit")) ...[
        SizedBox(height: AppSize.spaceXS),
        Row(children: [
          Expanded(child: Button(title: s.supply_chain_recipe_edit, leftIcon: Icon(CI.edit, color: ThemeColor.of(context).button.text), action: () => setState(() => _editing = true))),
          // A made product never goes without what it consumes (`recipe_required`).
          if (_service.removable) ...[
            SizedBox(width: AppSize.spaceS),
            Expanded(child: Button(title: s.supply_chain_recipe_delete, leftIcon: Icon(CI.trash, color: ThemeColor.of(context).button.text), action: _delete))
          ]
        ])
      ],
      SizedBox(height: AppSize.spaceS)
    ];
  }

  /// A dish made to order is never bought: it has none (`product_is_composite`).
  bool _showsPresentations(Recipe? recipe) =>
    _service.presentationsRead && recipe?.mode != RecipeMode.order && !_editing;

  List<Widget> _presentations(BuildContext context) {
    final s = S.of(context);
    final unit = widget.product.unit;
    final items = _service.presentations;

    return [
      SizedBox(height: AppSize.spaceS),
      TextMedium(s.supply_chain_presentations_title, bold: true),
      KitchenNote(text: s.supply_chain_presentations_note),
      if (items.isEmpty)
        KitchenNote(text: s.supply_chain_presentations_empty)
      else
        for (final item in items) Padding(
          padding: EdgeInsets.only(bottom: AppSize.gap / 2),
          child: Surface.over(
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
            child: Row(children: [
              Expanded(child: TextSmall(item.name, ellipsis: true, bold: true)),
              TextSmall(kitchenQty(context, item.qty, unit: unit))
            ])
          )
        ),
      if (_can("presentations")) ...[
        SizedBox(height: AppSize.gap),
        Button(title: s.supply_chain_presentations_edit, leftIcon: Icon(CI.edit, color: ThemeColor.of(context).button.text), action: _editPresentations)
      ]
    ];
  }

  Future<void> _pause(bool paused) async {
    setState(() => _busy = true);

    final done = await _service.pause(context, paused);

    if (!mounted) return;
    setState(() => _busy = false);
    if (done) widget.onChanged();
  }

  Future<void> _produce(Recipe recipe) async {
    final s = S.of(context);
    final draft = await showProduceBatch(context, product: widget.product);

    if (draft == null || !mounted) return;

    final result = await _service.produce(context, quantity: draft.quantity, lost: draft.lost, note: draft.note);

    if (result == null || !mounted) return;
    widget.onChanged();

    if (result.skipped.isEmpty) {
      FloatFlag.of(context).message(s.supply_chain_produced(kitchenQty(context, result.made)));
    } else {
      FloatFlag.of(context).alert(message: s.supply_chain_produced_without(result.skipped.join(", ")));
    }
  }

  Future<void> _discard(Recipe recipe) async {
    final s = S.of(context);
    final draft = await showDiscardDish(context, product: widget.product, recipe: recipe);

    if (draft == null || !mounted) return;

    final done = await _service.discard(context, quantity: draft.quantity, without: draft.without, note: draft.note);

    if (!done || !mounted) return;
    widget.onChanged();
    FloatFlag.of(context).message(s.supply_chain_discarded);
  }

  /// Deleting a preparation leaves the supply with a shelf of its own, bought ready: the recipes
  /// that use it are said first.
  Future<void> _delete() async {
    final s = S.of(context);
    final uses = await _service.uses();

    if (!mounted) return;

    final names = [for (final use in uses ?? const <RecipeUse>[]) if (use.name.isNotEmpty) use.name];

    final confirmed = await showAlertModal(
      context: context,
      title: s.supply_chain_recipe_delete_title,
      message: [
        s.supply_chain_recipe_delete_message(widget.product.label),
        if (names.isNotEmpty) s.supply_chain_used_in(names.join(", ")),
        if (uses == null) s.supply_chain_uses_unknown
      ].join("\n\n"),
      confirmText: s.supply_chain_recipe_delete,
      cancelText: s.cancel
    );

    if (!confirmed || !mounted) return;

    final done = await _service.remove(context);

    if (!done || !mounted) return;
    widget.onChanged();
    FloatFlag.of(context).message(s.supply_chain_recipe_deleted);
  }

  Future<void> _editPresentations() async {
    final s = S.of(context);
    final drafts = await showPresentationsEditor(
      context,
      presentations: _service.presentations,
      unit: widget.product.unit
    );

    if (drafts == null || !mounted) return;

    final done = await _service.savePresentations(context, drafts);

    if (done && mounted) FloatFlag.of(context).message(s.supply_chain_presentations_saved);
  }
}
