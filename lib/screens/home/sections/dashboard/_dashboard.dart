import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import './assistant/_assistant.dart';
import './summary/_summary.dart';

/// **The home** (`/home`): the assistant's chat on two thirds, the summary
/// cards on the other one.
///
/// The chat is the main way into the app, so it gets the room; the summary is
/// what one glances at before asking. Both are placeholders until their
/// backends exist: the chat answers from `AssistantDemoSource`, the cards from
/// sample figures.
class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Expanded(flex: 2, child: AssistantPanel()),
      SizedBox(width: AppSize.gap),
      const Expanded(flex: 1, child: SummaryPanel())
    ]
  );
}
