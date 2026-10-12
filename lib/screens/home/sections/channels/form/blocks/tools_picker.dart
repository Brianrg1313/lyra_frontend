import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_tools.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/channels/form/widgets/form_row.dart';
import 'package:app/screens/home/sections/channels/form/widgets/option_chip.dart';

/// What the model can process and produce, besides text: voice, images, video
/// and documents.
///
/// With voice, a WhatsApp audio is transcribed and it answers speaking; with
/// images or video, the model looks at the product's photo or the video of the
/// failure and responds about it.
///
/// Several can be chosen, and **each one makes the channel's processing more
/// expensive**. That is the row's one note, kept even though the rest of the
/// form lost its explanations: it is information to decide with, not a
/// disclaimer. Payment is per handled conversation, so enabling voice on a
/// channel with a lot of traffic shows up on the bill. What each tool does is
/// left to its name.
class ToolsPicker extends StatelessWidget {
  const ToolsPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => ChannelFormRow(
    label: S.of(context).channel_tools_title,
    note: S.of(context).channel_tools_cost,
    child: ValueListenableBuilder<Set<ChannelTool>>(
      valueListenable: controller.tools,
      builder: (context, selected, _) => OptionChips(children: [
        for (final tool in ChannelTool.values) OptionChip(
          icon: tool.icon,
          title: tool.title(context),
          selected: selected.contains(tool),
          multiple: true,
          action: () => controller.toggleTool(tool)
        )
      ])
    )
  );
}
