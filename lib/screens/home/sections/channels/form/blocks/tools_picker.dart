import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_tools.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// Que puede procesar y producir el modelo, ademas de texto: voz, imagenes,
/// video y documentos.
///
/// Con voz, un audio de WhatsApp se transcribe y se contesta hablando; con
/// imagenes o video, el modelo mira la foto del producto o el video de la falla
/// y responde sobre eso.
///
/// Se pueden elegir varias, y **cada una encarece el procesamiento del canal**.
/// El aviso esta arriba de las opciones y no en la letra chica de abajo a
/// proposito: es informacion para decidir, no un descargo. Se paga por
/// conversacion atendida, asi que encender voz en un canal con mucho trafico se
/// nota en la factura.
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

/// El aviso de que estas opciones cuestan mas.
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
