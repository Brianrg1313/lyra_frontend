import 'package:flutter/material.dart';

// SERVICES

/// The dot on its own.
///
/// It is public because the state filter draws the same one beside each option
/// of its list, and on the chip once one is chosen: the dropdown and the row
/// have to agree about what colour a state is, and two `Container`s with the
/// same numbers in them is exactly how they stop agreeing.
class SaleStageDot extends StatelessWidget {
  const SaleStageDot({super.key, required this.color});

  final Color color;

  /// Small enough to read as punctuation next to the label and not as a
  /// swatch: the colour is a hint about the row, not the row's subject.
  static const double _size = 8;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle)
  );
}
