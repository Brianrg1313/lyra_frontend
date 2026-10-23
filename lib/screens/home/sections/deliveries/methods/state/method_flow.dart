import 'package:flutter/material.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

/// The steps of adding a delivery method in the desk's panel.
///
/// - [kind]: who carries the order (three cards).
/// - [form]: that method's carrier, price and time.
/// - [areas]: where the company delivers, drawn on the map beside the panel.
enum MethodStep { kind, form, areas }

/// Where the desk's panel is in adding or editing a delivery method; `null`
/// [step] is the panel's own views.
///
/// Held by the section and not by the panel because the panel gives way to
/// the area editor while an area is shaped: the flow has to be where it was
/// when the editor closes.
class MethodFlow extends ChangeNotifier {
  MethodStep? _step;
  DeliveryMode? _mode;
  DeliveryOption? _editing;

  MethodStep? get step => _step;
  bool get isOpen => _step != null;

  /// The kind picked for a new method; an edit's is its option's.
  DeliveryMode? get mode => _editing?.mode ?? _mode;

  /// The method being edited; `null` while one is added.
  DeliveryOption? get editing => _editing;

  void start() => _go(MethodStep.kind, mode: null, editing: null);

  void pick(DeliveryMode mode) => _go(MethodStep.form, mode: mode, editing: null);

  void edit(DeliveryOption option) => _go(MethodStep.form, mode: null, editing: option);

  /// After the method was written: a new one goes on to where it delivers, an
  /// edit is done.
  void saved() => _editing == null
    ? _go(MethodStep.areas, mode: _mode, editing: null)
    : close();

  /// One step back; from the first, or from an edit, out of the flow. The
  /// areas step has nothing behind it: the method is already saved.
  void back() => switch (_step) {
    MethodStep.form when _editing == null => _go(MethodStep.kind, mode: null, editing: null),
    _ => close()
  };

  void close() => _go(null, mode: null, editing: null);

  void _go(MethodStep? step, {required DeliveryMode? mode, required DeliveryOption? editing}) {
    _step = step;
    _mode = mode;
    _editing = editing;
    notifyListeners();
  }
}
