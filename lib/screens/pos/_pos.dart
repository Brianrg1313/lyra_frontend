import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import './desktop/_body.dart';

/// POS mode: the counter from which in-person sales happen.
///
/// It is a **standalone page**, not a home section: it declares neither `shell`
/// nor `parents`, so it enters through its own `Navigator` page and shares
/// nothing with the home shell. That is deliberate —the side bar, the search
/// bar and the company picker have no place at a counter—: whoever is taking
/// payment is looking at a screen that does a single thing.
///
/// You leave it through history (the back button in the window bar on
/// desktop, the browser one on web), which is what leaves the `/pos` URL and
/// makes it unnecessary to duplicate it on the page.
///
/// The content of the three panels does not exist yet: for now each one is its
/// empty surface, so they can be developed one at a time without revisiting
/// how the screen is divided.
class Pos extends PageBuilder {
  const Pos({super.key});

  /// Route key. The page declares it and not `routes.dart` so that whoever
  /// opens it does not depend on how the path is written.
  static const String routeKey = "pos";

  /// POS mode URL. It hangs from the root and not from `/home` because it does
  /// not live inside the home: it is another mode of the app, not another
  /// section.
  static const String path = "/pos";

  @override
  Widget build(BuildContext context) => const PosBody();
}