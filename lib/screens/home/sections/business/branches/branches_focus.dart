import 'package:flutter/foundation.dart';

/// Which branch the tab points at: the one opened last and the one under the
/// pointer, in the list or on the map. Both sides read it, so a row and its
/// pin light up together, wherever the pointer is.
class BranchesFocus extends ChangeNotifier {
  String? _selected;
  String? _hovered;

  String? get selected => _selected;

  /// The branch's row and pin are drawn as pointed at.
  bool lit(String id) => id == _selected || id == _hovered;

  void select(String id) {
    if (_selected == id) return;

    _selected = id;
    notifyListeners();
  }

  /// [inside] false only clears the branch that was hovered: leaving one row
  /// after entering the next must not clear the next.
  void hover(String id, bool inside) {
    if (inside) {
      if (_hovered == id) return;
      _hovered = id;
    } else {
      if (_hovered != id) return;
      _hovered = null;
    }

    notifyListeners();
  }
}
