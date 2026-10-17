import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// What a batch is: how many were made, how many of them went wrong, a note.
typedef BatchDraft = ({double quantity, double lost, String note});

/// Asks for a batch of [product] (`POST /recipes/produce`). Writes nothing: answers the draft,
/// or `null` when closed.
Future<BatchDraft?> showProduceBatch(BuildContext context, {required KitchenProduct product}) =>
  showModal(
    context: context,
    title: S.of(context).supply_chain_produce_title(product.label),
    builder: (context) => const ProduceBatchModal()
  ).then((value) => value is BatchDraft ? value : null);

/// The supplies of the whole [BatchDraft.quantity] are spent (with their waste); the shelf rises
/// by what is left after [BatchDraft.lost] — 100 candles, 5 cracked.
class ProduceBatchModal extends StatefulWidget {
  const ProduceBatchModal({super.key});

  @override
  State<ProduceBatchModal> createState() => _ProduceBatchModalState();
}

class _ProduceBatchModalState extends State<ProduceBatchModal> {
  final _quantity = InputController(key: "QUANTITY", pattern: "[0-9.,]", max: 16);
  final _lost = InputController(key: "LOST", pattern: "[0-9.,]", max: 16);
  final _note = InputController(key: "NOTE", max: 240);
  String _error = "";

  @override
  void dispose() {
    _quantity.dispose();
    _lost.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KitchenNote(text: s.supply_chain_produce_note),
        Input(title: s.supply_chain_produce_quantity, placeholder: "100", controller: _quantity, next: _lost.focus),
        Input(title: s.supply_chain_produce_lost, placeholder: "0", controller: _lost, next: _note.focus),
        Input(title: s.supply_chain_note, placeholder: s.supply_chain_note_hint, controller: _note),
        if (_error.isNotEmpty) KitchenNote(text: _error, color: ThemeColor.of(context).snackBar.error),
        SizedBox(height: AppSize.spaceS),
        MainButton(title: s.supply_chain_produce, action: _submit)
      ])
    );
  }

  void _submit() {
    final s = S.of(context);
    final quantity = kitchenParse(_quantity.text);
    final lost = _lost.text.trim().isEmpty ? 0.0 : kitchenParse(_lost.text);

    final error = quantity == null || quantity <= 0
      ? s.supply_chain_line_qty_invalid
      : lost == null || lost < 0 || lost > quantity ? s.supply_chain_produce_lost_invalid : "";

    if (error.isNotEmpty) return setState(() => _error = error);

    Navigator.pop(context, (quantity: quantity!, lost: lost!, note: _note.text));
  }
}
