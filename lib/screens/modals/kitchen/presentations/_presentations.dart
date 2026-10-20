import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/presentation_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/inventory/kitchen_format.dart';
import 'package:app/screens/modals/kitchen/shared/kitchen_product_picker.dart';

/// Edits how a product is bought (`PUT /inventory/presentations`). Answers every presentation
/// as it should be (none = remove them all), or `null` when closed. Writes nothing.
Future<List<PresentationDraft>?> showPresentationsEditor(
  BuildContext context, {
  required List<Presentation> presentations,
  String unit = ""
}) => showModal(
  context: context,
  title: S.of(context).kitchen_presentations_title,
  builder: (context) => PresentationsModal(presentations: presentations, unit: unit)
).then((value) => value is List<PresentationDraft> ? value : null);

class _Row {
  _Row({this.id = "", String name = "", double? qty})
    : name = InputController(key: "NAME_${identityHashCode(Object())}", max: 40, initial: name),
      qty = InputController(key: "QTY_${identityHashCode(Object())}", pattern: "[0-9.,]", max: 16, initial: qty == null ? null : kitchenField(qty));

  /// Kept on a save: the movements that named it keep naming it.
  final String id;
  final InputController name;
  final InputController qty;

  void dispose() {
    name.dispose();
    qty.dispose();
  }
}

/// «Saco» = 25 kg, «Caja» = 12 botellas: a name, and what ONE holds in the product's [unit]
/// (shown beside it when the table says one; the backend doesn't). Names don't repeat.
class PresentationsModal extends StatefulWidget {
  const PresentationsModal({super.key, required this.presentations, this.unit = ""});

  final List<Presentation> presentations;
  final String unit;

  @override
  State<PresentationsModal> createState() => _PresentationsModalState();
}

class _PresentationsModalState extends State<PresentationsModal> {
  late final List<_Row> _rows = [
    for (final item in widget.presentations) _Row(id: item.id, name: item.name, qty: item.qty)
  ];
  String _error = "";

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        KitchenNote(text: s.kitchen_presentations_note),
        for (final row in _rows) Row(key: ObjectKey(row), children: [
          Expanded(child: Input(controller: row.name, placeholder: s.kitchen_presentation_name, buttonSpace: false)),
          SizedBox(width: AppSize.gap),
          SizedBox(width: 120, child: Input(controller: row.qty, placeholder: s.kitchen_presentation_qty, buttonSpace: false)),
          if (widget.unit.isNotEmpty) ...[
            SizedBox(width: AppSize.gap),
            TextSmall(widget.unit, color: scheme.text.secondary)
          ],
          FocusableWidget(
            action: () => setState(() {
              _rows.remove(row);
              row.dispose();
            }),
            message: s.kitchen_line_remove,
            child: Padding(
              padding: EdgeInsets.all(AppSize.gap),
              child: Icon(CI.trash, size: AppSize.text, color: scheme.text.secondary)
            )
          )
        ]),
        SizedBox(height: AppSize.gap),
        Button(title: s.kitchen_presentation_add, leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text), action: () => setState(() => _rows.add(_Row()))),
        if (_error.isNotEmpty) KitchenNote(text: _error, color: scheme.snackBar.error),
        SizedBox(height: AppSize.spaceS),
        MainButton(title: s.save, action: _submit)
      ])
    );
  }

  void _submit() {
    final s = S.of(context);
    final drafts = <PresentationDraft>[];
    final names = <String>{};

    for (final row in _rows) {
      final name = row.name.text.trim();
      final qty = kitchenParse(row.qty.text);

      if (name.isEmpty || qty == null || qty <= 0) return setState(() => _error = s.kitchen_presentations_invalid);
      if (!names.add(name.toLowerCase())) return setState(() => _error = s.kitchen_presentations_repeated(name));

      drafts.add((id: row.id, name: name, qty: qty));
    }

    Navigator.pop(context, drafts);
  }
}
