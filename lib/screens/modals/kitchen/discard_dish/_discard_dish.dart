import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/modals/kitchen/shared/kitchen_product_picker.dart';

/// Dishes lost: how many, what they went without, a note.
typedef DiscardDraft = ({int quantity, List<String> without, String note});

/// Asks for dishes of [product] made to order and lost (`POST /recipes/discard`): burned,
/// dropped. Writes nothing: answers the draft, or `null` when closed.
Future<DiscardDraft?> showDiscardDish(BuildContext context, {required KitchenProduct product, required Recipe recipe}) =>
  showModal(
    context: context,
    title: S.of(context).kitchen_discard_title(product.label),
    builder: (context) => DiscardDishModal(recipe: recipe)
  ).then((value) => value is DiscardDraft ? value : null);

/// Their supplies leave as spoiled, tied to the dish. A dish that went without a negotiable line
/// (no fries) spent none of it: those are ticked off.
class DiscardDishModal extends StatefulWidget {
  const DiscardDishModal({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<DiscardDishModal> createState() => _DiscardDishModalState();
}

class _DiscardDishModalState extends State<DiscardDishModal> {
  final _quantity = InputController(key: "QUANTITY", pattern: "[0-9]", max: 6, initial: "1");
  final _note = InputController(key: "NOTE", max: 240);
  final Set<String> _without = {};
  String _error = "";

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final negotiable = widget.recipe.negotiable;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KitchenNote(text: s.kitchen_discard_note),
        Input(title: s.kitchen_discard_quantity, placeholder: "1", controller: _quantity, next: _note.focus),
        if (negotiable.isNotEmpty) ...[
          SizedBox(height: AppSize.gap),
          TextSmall(s.kitchen_discard_without, bold: true),
          for (final line in negotiable) Row(children: [
            Checkbox(
              value: _without.contains(line.id),
              activeColor: scheme.primary,
              onChanged: (value) => setState(() => value == true ? _without.add(line.id) : _without.remove(line.id))
            ),
            Expanded(child: TextSmall(line.name.isEmpty ? line.productId : line.name, ellipsis: true))
          ])
        ],
        Input(title: s.kitchen_note, placeholder: s.kitchen_note_hint, controller: _note),
        if (_error.isNotEmpty) KitchenNote(text: _error, color: scheme.snackBar.error),
        SizedBox(height: AppSize.spaceS),
        MainButton(title: s.kitchen_discard, action: _submit)
      ])
    );
  }

  void _submit() {
    final quantity = int.tryParse(_quantity.text.trim());

    if (quantity == null || quantity <= 0) {
      return setState(() => _error = S.of(context).kitchen_line_qty_invalid);
    }

    Navigator.pop(context, (quantity: quantity, without: _without.toList(), note: _note.text));
  }
}
