import 'package:flutter/material.dart';

/// What only holds while the company delivers, faded while it says it does not.
///
/// Still editable: the options and the areas' rule are kept for when delivery
/// is turned back on (see `MethodList`). Fading them says they are
/// not offered today without hiding what will come back, and the fade follows
/// the answer being picked, so the person sees what that answer switched off.
class DeliveryGate extends StatelessWidget {
  const DeliveryGate({super.key, required this.off, required this.child});

  /// The company said it does not deliver (`delivers == false`). "Not set" is
  /// not off: it never turns a customer away.
  final bool off;

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: off ? .45 : 1,
    duration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    child: child
  );
}
