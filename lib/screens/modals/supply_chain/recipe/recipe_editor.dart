import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/recipe_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// One line as it is being written: the ingredient, and its quantity and waste as typed.
class _LineDraft {
  _LineDraft({
    required this.tableId,
    required this.productId,
    required this.name,
    this.supplies,
    double? qty,
    double waste = 0,
    this.negotiable = false
  }) : qty = InputController(key: "QTY_$productId", pattern: "[0-9.,]", max: 16, initial: qty == null ? null : kitchenField(qty)),
       waste = InputController(key: "WASTE_$productId", pattern: "[0-9.,]", max: 6, initial: waste > 0 ? kitchenField(waste) : null);

  final String tableId;
  final String productId;
  final String name;

  /// A supply takes decimals; a product for sale (the burger in a combo) whole units only.
  /// `null` on a saved line: the recipe doesn't say which, and the backend checks it anyway.
  final bool? supplies;
  final InputController qty;
  final InputController waste;
  bool negotiable;
  String error = "";

  void dispose() {
    qty.dispose();
    waste.dispose();
  }
}

/// What a recipe being written saves: its mode, its lines and their names (product id → name),
/// so the answer of a write is named.
typedef RecipeDraft = ({RecipeMode mode, List<RecipeLineDraft> lines, Map<String, String> names});

/// What a product is made of, written: how it is made, its lines — how much ONE unit takes,
/// whether it can go without it, what is lost making it — and the ingredient search that adds
/// one.
///
/// How it is made follows what the product is (`cocina-frontend.md` §1): a made product is made
/// to order unless «Made by the batch» is on; a supply's preparation (the house sauce) is
/// always by the batch, so it asks nothing.
///
/// It checks here what the backend would refuse in the same terms (a quantity above zero, whole
/// on anything counted in units; waste from 0 to under 100; at least one line it can't go
/// without), so a mistake is said beside the line. The rules only the backend knows (a recipe
/// that contains itself, more than two levels made to order) come back as its refusal, shown as
/// it comes. [onSave] writes it, or hands it back (a made row being created): `false` keeps the
/// editor open.
class RecipeEditor extends StatefulWidget {
  const RecipeEditor({
    super.key,
    required this.recipe,
    required this.supplies,
    required this.canEdit,
    required this.onSave,
    required this.onCancel,
    this.exclude = const {},
    this.saveLabel
  });

  /// What it is made of now; `null` writes the first.
  final Recipe? recipe;

  /// A supply's preparation: always by the batch.
  final bool supplies;
  final bool canEdit;
  final Future<bool> Function(RecipeDraft draft) onSave;

  /// Leaves the editor without saving.
  final void Function() onCancel;

  /// Product ids not offered as ingredients: the product itself.
  final Set<String> exclude;
  final String? saveLabel;

  @override
  State<RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<RecipeEditor> {
  late bool _batch = widget.supplies || widget.recipe?.mode == RecipeMode.batch;

  late final List<_LineDraft> _lines = [
    for (final line in widget.recipe?.lines ?? const <RecipeLine>[]) _LineDraft(
      tableId: line.tableId,
      productId: line.productId,
      name: line.name,
      qty: line.qty,
      waste: line.waste,
      negotiable: line.negotiable
    )
  ];

  final _saving = ValueNotifier(false);
  String _error = "";

  @override
  void dispose() {
    _saving.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _add(KitchenProduct product) => setState(() => _lines.add(_LineDraft(
    tableId: product.tableId,
    productId: product.id,
    name: product.label,
    supplies: product.supplies
  )));

  void _remove(_LineDraft line) => setState(() {
    _lines.remove(line);
    line.dispose();
  });

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.supplies) Surface.over(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextSmall(s.supply_chain_mode_batch, bold: true),
              TextSmall(
                _batch ? s.supply_chain_mode_batch_note : s.supply_chain_mode_order_note,
                lines: 3,
                color: scheme.text.secondary
              )
            ])),
            SizedBox(width: AppSize.spaceS),
            Switch(
              value: _batch,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: scheme.primary,
              onChanged: widget.canEdit ? (value) => setState(() => _batch = value) : null
            )
          ])
        ),
        SizedBox(height: AppSize.spaceXS),
        TextMedium(s.supply_chain_lines_title, bold: true),
        KitchenNote(text: s.supply_chain_lines_note),
        if (_lines.isEmpty)
          KitchenNote(text: s.supply_chain_lines_empty, color: scheme.text.secondary)
        else
          for (final line in _lines) _LineRow(
            key: ObjectKey(line),
            line: line,
            enabled: widget.canEdit,
            onRemove: () => _remove(line),
            onNegotiable: (value) => setState(() => line.negotiable = value)
          ),
        if (widget.canEdit) ...[
          SizedBox(height: AppSize.spaceXS),
          KitchenProductPicker(
            placeholder: s.supply_chain_lines_add,
            exclude: {...widget.exclude, for (final line in _lines) line.productId},
            onPick: _add
          )
        ],
        if (_error.isNotEmpty) KitchenNote(text: _error, color: scheme.snackBar.error),
        if (widget.canEdit) ...[
          SizedBox(height: AppSize.spaceM),
          Row(children: [
            Expanded(child: Button(title: s.cancel, action: widget.onCancel)),
            SizedBox(width: AppSize.spaceS),
            Expanded(child: MainButton(title: widget.saveLabel ?? s.save, loading: _saving, action: _save))
          ])
        ]
      ]
    );
  }

  Future<void> _save() async {
    final s = S.of(context);
    final drafts = <RecipeLineDraft>[];
    var valid = true;

    for (final line in _lines) {
      final qty = kitchenParse(line.qty.text);
      final waste = line.waste.text.trim().isEmpty ? 0.0 : kitchenParse(line.waste.text);

      line.error = switch ((qty, waste)) {
        (null, _) => s.supply_chain_line_qty_invalid,
        (final double value, _) when value <= 0 => s.supply_chain_line_qty_invalid,
        (final double value, _) when line.supplies == false && value != value.roundToDouble() => s.supply_chain_line_qty_whole,
        (_, null) => s.supply_chain_line_waste_invalid,
        (_, final double value) when value < 0 || value >= 100 => s.supply_chain_line_waste_invalid,
        _ => ""
      };

      if (line.error.isNotEmpty) {
        valid = false;
        continue;
      }

      drafts.add((tableId: line.tableId, productId: line.productId, qty: qty!, negotiable: line.negotiable, waste: waste!));
    }

    _error = _lines.isEmpty
      ? s.supply_chain_lines_empty
      : valid && drafts.every((line) => line.negotiable) ? s.supply_chain_lines_essential : "";

    setState(() {});
    if (!valid || _error.isNotEmpty) return;

    _saving.value = true;

    await widget.onSave((
      mode: _batch ? RecipeMode.batch : RecipeMode.order,
      lines: drafts,
      names: {for (final line in _lines) line.productId: line.name}
    ));

    if (mounted) _saving.value = false;
  }
}

/// One line: the ingredient, its quantity, its waste, whether it can go without it.
class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.enabled,
    required this.onRemove,
    required this.onNegotiable
  });

  final _LineDraft line;
  final bool enabled;
  final void Function() onRemove;
  final void Function(bool value) onNegotiable;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Surface.over(
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(line.supplies == false ? CI.product : CI.warehouse, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextSmall(line.name, ellipsis: true, bold: true)),
            SizedBox(
              width: 110,
              child: Input(controller: line.qty, placeholder: s.supply_chain_line_qty, buttonSpace: false)
            ),
            SizedBox(width: AppSize.gap),
            SizedBox(
              width: 80,
              child: Input(controller: line.waste, placeholder: s.supply_chain_line_waste, buttonSpace: false)
            ),
            SizedBox(width: AppSize.gap),
            Tooltip(
              message: s.supply_chain_line_negotiable_note,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                TextSmall(s.supply_chain_line_negotiable, color: scheme.text.secondary),
                Switch(
                  value: line.negotiable,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: scheme.primary,
                  onChanged: enabled ? onNegotiable : null
                )
              ])
            ),
            if (enabled) FocusableWidget(
              action: onRemove,
              message: s.supply_chain_line_remove,
              child: Padding(
                padding: EdgeInsets.all(AppSize.gap),
                child: Icon(CI.trash, size: AppSize.text, color: scheme.text.secondary)
              )
            )
          ]),
          if (line.error.isNotEmpty) TextSmall(line.error, color: scheme.snackBar.error)
        ])
      )
    );
  }
}
