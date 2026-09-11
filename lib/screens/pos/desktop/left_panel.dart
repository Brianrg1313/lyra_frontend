import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import './admin_card.dart';

/// Left panel of POS mode, split into two stacked surfaces.
///
/// They are two rather than a single one divided by a line because the two
/// halves do not show the same thing nor change together: separating them
/// already lets each one develop —and repaint— on its own.
///
/// The top one (section 1, still empty) is the one that grows: it is where
/// whatever needs the extra space will go. The bottom one ([PosAdminCard])
/// measures what its content needs —the picture of whoever is attending, their
/// name, how much they have sold and the exit button— and not the other way
/// around, because stretching it would leave empty air below that data.
class PosLeftPanel extends StatelessWidget {
  const PosLeftPanel({super.key});

  @override
  Widget build(BuildContext context) => Column(children: [
    const Expanded(child: Surface(child: Center(child: Text("1")))),
    SizedBox(height: AppSize.gap),
    const Surface(child: PosAdminCard())
  ]);
}