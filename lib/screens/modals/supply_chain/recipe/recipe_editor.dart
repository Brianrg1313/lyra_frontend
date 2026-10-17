import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/kitchen_units.dart';
import 'package:app/services/kitchen/recipe_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// One line as it is being written: the ingredient, its quantity (in one of the units its own
/// can be written in, [shown]) and its waste as typed.
class _LineDraft {
  _LineDraft({
    required this.tableId,
    required this.productId,
    required this.name,
    this.supplies,
    this.unit = "",
    double? qty,
    double waste = 0,
    this.negotiable = false
  }) : units = kitchenUnitsFor(unit),
       more = negotiable || waste > 0,
       waste = InputController(key: "WASTE_$productId", pattern: "[0-9.,]", max: 6, initial: waste > 0 ? kitchenField(waste) : null) {
    final best = qty == null ? null : kitchenBestUnit(qty, unit);

    // A new line of a weight or a volume starts on the small unit: 300 g, not 0.3 kg.
    shown = best?.unit ?? units.first;
    this.qty = InputController(key: "QTY_$productId", pattern: "[0-9.,]", max: 16, initial: best == null ? null : kitchenField(best.qty));
  }

  final String tableId;
  final String productId;
  final String name;

  /// A supply takes decimals; a product for sale (the burger in a combo) whole units only.
  /// `null` on a saved line: the recipe doesn't say which, and the backend checks it anyway.
  final bool? supplies;

  /// The ingredient's own unit, the only one the backend takes (empty: counted in units).
  final String unit;

  /// What [qty] can be written in.
  final List<KitchenUnit> units;
  late KitchenUnit shown;

  late final InputController qty;
  final InputController waste;
  bool negotiable;

  /// Whether its waste and «optional» are unfolded: always when it has either.
  bool more;
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
/// A line's quantity is written in a unit of its ingredient's measure (300 g of a meat counted
/// in kg) and travels in the ingredient's own, which is the only one the backend takes.
///
/// It checks here what the backend would refuse in the same terms (a quantity above zero, whole
/// on anything counted in units; waste from 0 to under 100; at least one line it can't go
/// without), so a mistake is said beside the line. The rules only the backend knows (a recipe
/// that contains itself, more than two levels made to order) come back as its refusal, shown as
/// it comes. [onSave] writes it, or hands it back: `false` keeps the editor open.
class RecipeEditor extends StatefulWidget {
  const RecipeEditor({
    super.key,
    required this.recipe,
    required this.supplies,
    required this.canEdit,
    required this.onSave,
    required this.onCancel,
    this.exclude = const {},
    this.saveLabel,
    this.units = const {},
    this.leading = const [],
    this.validate
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

  /// The unit each ingredient is counted in, by product id, for the saved lines (the backend
  /// answers them without one); a picked ingredient brings its own.
  final Map<String, String> units;

  /// What goes above how it is made: a made product's own fields.
  final List<Widget> leading;

  /// Checks what [leading] holds, beside the lines; `false` does not save.
  final bool Function()? validate;

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
      unit: widget.units[line.productId] ?? "",
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
    supplies: product.supplies,
    unit: product.unit
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
        ...widget.leading,
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
            onNegotiable: (value) => setState(() => line.negotiable = value),
            onUnit: (unit) => setState(() => line.shown = unit),
            onMore: () => setState(() => line.more = !line.more)
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
    var valid = widget.validate?.call() ?? true;

    for (final line in _lines) {
      final typed = kitchenParse(line.qty.text);
      // In the ingredient's own unit, rounded where the backend rounds (millionths).
      final qty = typed == null ? null : double.parse((typed * line.shown.factor).toStringAsFixed(6));
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
        // A wrong waste is said where it is written.
        if (waste == null || waste < 0 || waste >= 100) line.more = true;
        continue;
      }

      drafts.add((tableId: line.tableId, productId: line.productId, qty: qty!, negotiable: line.negotiable, waste: waste!));
    }

    _error = _lines.isEmpty
      ? s.supply_chain_lines_empty
      : _lines.length == drafts.length && drafts.every((line) => line.negotiable) ? s.supply_chain_lines_essential : "";

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

/// One line: the ingredient, its quantity and the unit it is written in; its waste and whether
/// it can go without it are folded under the arrow (`cocina-frontend.md` §3: «Más opciones»).
class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.enabled,
    required this.onRemove,
    required this.onNegotiable,
    required this.onUnit,
    required this.onMore
  });

  final _LineDraft line;
  final bool enabled;
  final void Function() onRemove;
  final void Function(bool value) onNegotiable;
  final void Function(KitchenUnit unit) onUnit;
  final void Function() onMore;

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
            _UnitPicker(line: line, enabled: enabled, onUnit: onUnit),
            FocusableWidget(
              action: onMore,
              message: s.supply_chain_line_more,
              child: Padding(
                padding: EdgeInsets.all(AppSize.gap),
                child: Icon(line.more ? CI.arrow_top : CI.arrow_down, size: AppSize.text, color: scheme.text.secondary)
              )
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
          if (line.more) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: Row(children: [
              SizedBox(
                width: 110,
                child: Input(controller: line.waste, placeholder: s.supply_chain_line_waste, buttonSpace: false)
              ),
              SizedBox(width: AppSize.spaceS),
              Expanded(child: Tooltip(
                message: s.supply_chain_line_negotiable_note,
                child: Row(children: [
                  Flexible(child: TextSmall(s.supply_chain_line_negotiable, color: scheme.text.secondary, ellipsis: true)),
                  Switch(
                    value: line.negotiable,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeThumbColor: scheme.primary,
                    onChanged: enabled ? onNegotiable : null
                  )
                ])
              ))
            ])
          ),
          if (line.error.isNotEmpty) TextSmall(line.error, color: scheme.snackBar.error)
        ])
      )
    );
  }
}

/// The unit a line's quantity is written in: a weight or a volume switches between its two on
/// a tap (g ↔ kg, ml ↔ l); anything else only says its own, or «units».
class _UnitPicker extends StatelessWidget {
  const _UnitPicker({required this.line, required this.enabled, required this.onUnit});

  final _LineDraft line;
  final bool enabled;
  final void Function(KitchenUnit unit) onUnit;

  static const double _width = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final label = line.shown.symbol.isEmpty ? s.supply_chain_line_units : line.shown.symbol;

    if (line.units.length < 2) {
      return SizedBox(
        width: _width,
        child: Center(child: TextSmall(label, color: scheme.text.secondary, ellipsis: true))
      );
    }

    final next = line.units[(line.units.indexOf(line.shown) + 1) % line.units.length];

    return FeedbackButton(
      width: _width,
      height: AppSize.action,
      message: s.supply_chain_line_unit_switch(next.symbol),
      action: enabled ? () => onUnit(next) : null,
      color: scheme.surface,
      child: Center(child: TextSmall(label, bold: true))
    );
  }
}
