import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/modifier_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_chip.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// An extra an option spends, as typed.
class ModifierExtraDraft {
  ModifierExtraDraft({required this.tableId, required this.productId, double? qty})
    : qty = InputController(key: "EXTRA_$productId", pattern: "[0-9.,]", max: 16, initial: qty == null ? null : kitchenField(qty));

  final String tableId;
  final String productId;
  final InputController qty;
}

/// One option as it is being written. Keeps [id]: open tickets name the option by it.
class ModifierOptionDraft {
  ModifierOptionDraft._({required this.id, required String name, required double price, required this.lines, required this.remove, required this.paused})
    : name = InputController(key: "OPTION_${identityHashCode(Object())}", max: 60, initial: name),
      price = InputController(key: "PRICE_${identityHashCode(Object())}", pattern: "[0-9.,]", max: 12, initial: price > 0 ? kitchenField(price) : null);

  factory ModifierOptionDraft.of(ModifierOption? option) => ModifierOptionDraft._(
    id: option?.id ?? "",
    name: option?.name ?? "",
    price: option?.price ?? 0,
    lines: [for (final line in option?.lines ?? const <ModifierLine>[]) ModifierExtraDraft(tableId: line.tableId, productId: line.productId, qty: line.qty)],
    remove: {...?option?.remove},
    paused: option?.paused ?? false
  );

  final String id;
  final InputController name;
  final InputController price;
  final List<ModifierExtraDraft> lines;
  final Set<String> remove;
  bool paused;

  /// The option, or `null` when something typed isn't valid (no name, a negative price, an
  /// extra without a quantity above zero).
  ModifierOption? build() {
    final name = this.name.text.trim();
    final price = this.price.text.trim().isEmpty ? 0.0 : kitchenParse(this.price.text);

    if (name.isEmpty || price == null || price < 0) return null;

    final extras = <ModifierLine>[];

    for (final line in lines) {
      final qty = kitchenParse(line.qty.text);
      if (qty == null || qty <= 0) return null;

      extras.add((tableId: line.tableId, productId: line.productId, qty: qty));
    }

    return ModifierOption(id: id, name: name, price: price, lines: extras, remove: remove.toList(), paused: paused);
  }

  void dispose() {
    name.dispose();
    price.dispose();
    for (final line in lines) {
      line.qty.dispose();
    }
  }
}

/// One option of the group form: its name and price (added to ONE unit), its pause, what it
/// spends on top of the recipe (per unit) and the recipe lines it stops spending.
class ModifierOptionCard extends StatefulWidget {
  const ModifierOptionCard({
    super.key,
    required this.option,
    required this.enabled,
    required this.nameOf,
    required this.removable,
    required this.onChanged,
    required this.onRemove
  });

  final ModifierOptionDraft option;
  final bool enabled;
  final String Function(String productId) nameOf;

  /// The recipe lines of the products offering the group.
  final List<({String id, String label})> removable;

  /// Names learnt while picking (product id → name), for the form to keep.
  final void Function(Map<String, String> names) onChanged;
  final void Function() onRemove;

  @override
  State<ModifierOptionCard> createState() => _ModifierOptionCardState();
}

class _ModifierOptionCardState extends State<ModifierOptionCard> {
  bool _picking = false;

  ModifierOptionDraft get _option => widget.option;

  void _addExtra(KitchenProduct product) {
    widget.onChanged({product.id: product.label});
    setState(() {
      _option.lines.add(ModifierExtraDraft(tableId: product.tableId, productId: product.id));
      _picking = false;
    });
  }

  Future<void> _pickRemove(BuildContext anchor) async {
    final s = S.of(anchor);
    final checked = await showCheckMenu(
      context: anchor,
      checked: _option.remove.toList(),
      emptyText: s.supply_chain_modifiers_remove_empty,
      options: [
        for (final line in widget.removable) SelectOption(value: line.id, placeholder: line.label)
      ]
    );

    if (mounted) setState(() => _option.remove..clear()..addAll(checked));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final enabled = widget.enabled;
    final labels = {for (final line in widget.removable) line.id: line.label};

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Input(controller: _option.name, placeholder: s.supply_chain_modifiers_option_name, buttonSpace: false)),
            SizedBox(width: AppSize.gap),
            SizedBox(width: 110, child: Input(controller: _option.price, placeholder: s.supply_chain_modifiers_option_price, buttonSpace: false)),
            Tooltip(
              message: s.supply_chain_modifiers_option_paused_note,
              child: Switch(
                value: !_option.paused,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: scheme.primary,
                onChanged: enabled ? (value) => setState(() => _option.paused = !value) : null
              )
            ),
            if (enabled) FocusableWidget(
              action: widget.onRemove,
              message: s.supply_chain_line_remove,
              child: Padding(
                padding: EdgeInsets.all(AppSize.gap),
                child: Icon(CI.trash, size: AppSize.text, color: scheme.text.secondary)
              )
            )
          ]),
          for (final line in _option.lines) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: Row(children: [
              Icon(CI.plus, size: AppSize.text, color: scheme.icon),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextSmall(widget.nameOf(line.productId), ellipsis: true)),
              SizedBox(width: 110, child: Input(controller: line.qty, placeholder: s.supply_chain_line_qty, buttonSpace: false)),
              if (enabled) FocusableWidget(
                action: () => setState(() {
                  _option.lines.remove(line);
                  line.qty.dispose();
                }),
                message: s.supply_chain_line_remove,
                child: Padding(
                  padding: EdgeInsets.all(AppSize.gap),
                  child: Icon(CI.trash, size: AppSize.text, color: scheme.text.secondary)
                )
              )
            ])
          ),
          if (_option.remove.isNotEmpty) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
              for (final id in _option.remove) KitchenChip(
                label: s.supply_chain_modifiers_removes(labels[id] ?? id),
                onRemove: enabled ? () => setState(() => _option.remove.remove(id)) : null
              )
            ])
          ),
          if (enabled) ...[
            SizedBox(height: AppSize.gap),
            Row(children: [
              FocusableWidget(
                action: () => setState(() => _picking = !_picking),
                child: TextSmall(s.supply_chain_modifiers_extra_add, color: scheme.primary)
              ),
              SizedBox(width: AppSize.spaceS),
              if (widget.removable.isNotEmpty) Builder(builder: (anchor) => FocusableWidget(
                action: () => _pickRemove(anchor),
                child: TextSmall(s.supply_chain_modifiers_remove_add, color: scheme.primary)
              ))
            ]),
            if (_picking) KitchenProductPicker(
              placeholder: s.supply_chain_lines_add,
              exclude: {for (final line in _option.lines) line.productId},
              onPick: _addExtra
            )
          ],
          if (_option.lines.isNotEmpty || _option.remove.isNotEmpty)
            KitchenNote(text: s.supply_chain_modifiers_spends_note)
        ])
      )
    );
  }
}
