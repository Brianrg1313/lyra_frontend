import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_tools.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/form/form_block.dart';
import 'package:app/screens/home/sections/_section/form/option_card.dart';
import 'package:app/screens/home/sections/_section/form/option_grid.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// What the model can process and produce, besides text: voice, images, video
/// and documents.
///
/// With voice, a WhatsApp audio is transcribed and it answers speaking; with
/// images or video, the model looks at the product's photo or the video of the
/// failure and responds about it.
///
/// Several can be chosen, and **each one makes the channel's processing more
/// expensive**. The warning is above the options and not in the small print at
/// the bottom on purpose: it is information to decide with, not a disclaimer.
/// Payment is per handled conversation, so enabling voice on a channel with a
/// lot of traffic shows up on the bill.
class ToolsPicker extends StatelessWidget {
  const ToolsPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).channel_tools_title,
    subtitle: S.of(context).channel_tools_subtitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CostWarning(),
        SizedBox(height: AppSize.gap),
        ValueListenableBuilder<Set<ChannelTool>>(
          valueListenable: controller.tools,
          builder: (context, selected, _) => OptionGrid(children: [
            for (final tool in ChannelTool.values) OptionCard(
              icon: tool.icon,
              title: tool.title(context),
              subtitle: tool.subtitle(context),
              selected: selected.contains(tool),
              multiple: true,
              action: () => controller.toggleTool(tool)
            )
          ])
        )
      ]
    )
  );
}

/// The warning that these options cost more.
class _CostWarning extends StatelessWidget {
  const _CostWarning();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.spaceXS,
        vertical: AppSize.gap * 1.5
      ),
      decoration: BoxDecoration(
        color: scheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(children: [
        Icon(CI.info, size: AppSize.text * 1.2, color: scheme.accent),
        SizedBox(width: AppSize.gap),
        Expanded(child: TextSmall(
          S.of(context).channel_tools_cost,
          lines: 3,
          color: scheme.text.secondary
        ))
      ])
    );
  }
}
