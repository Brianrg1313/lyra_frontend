import 'package:flutter/material.dart';

/// A hint that keeps its room while hidden, so the value beside it does not
/// jump, and takes no click while it cannot be seen.
class EmployeeHint extends StatelessWidget {
  const EmployeeHint({super.key, required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !shown,
    child: AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: child
    )
  );
}
