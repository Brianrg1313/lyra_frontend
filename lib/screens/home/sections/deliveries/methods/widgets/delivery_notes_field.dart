import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// The company's own sentence about delivery in general, written in place;
/// "Save" shows only while what is typed differs from what is saved.
///
/// Its controller belongs to **no** form: it is free text that is never
/// refused, and the backend's ceiling (255) is the input's own.
class DeliveryNotesField extends StatefulWidget {
  const DeliveryNotesField({super.key, required this.notes, required this.onSave});

  /// What is saved.
  final String notes;

  final Future<bool> Function(String notes) onSave;

  @override
  State<DeliveryNotesField> createState() => _DeliveryNotesFieldState();
}

class _DeliveryNotesFieldState extends State<DeliveryNotesField> {
  late final _notes = InputController(key: "NOTES_GENERAL", initial: widget.notes, max: 255);
  final _saving = ValueNotifier(false);

  bool get _changed => _notes.value.trim() != widget.notes;

  @override
  void initState() {
    super.initState();
    _notes.textController.addListener(_typed);
  }

  @override
  void dispose() {
    _notes.textController.removeListener(_typed);
    _notes.dispose();
    _saving.dispose();
    super.dispose();
  }

  void _typed() => setState(() {});

  Future<void> _save() async {
    if (_saving.value || !_changed) return;

    _saving.value = true;
    await widget.onSave(_notes.value.trim());
    if (mounted) _saving.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: S.of(context).business_delivery_notes,
          placeholder: S.of(context).business_delivery_notes_hint,
          controller: _notes,
          leftIcon: Icon(CI.chat, color: scheme.icon),
          onSubmit: _save
        ),
        TextSmall(
          S.of(context).business_delivery_notes_note,
          lines: 2,
          color: scheme.text.secondary
        ),
        if (_changed) ...[
          SizedBox(height: AppSize.spaceS),
          Button(title: S.of(context).save, action: _save, loading: _saving)
        ]
      ]
    );
  }
}
