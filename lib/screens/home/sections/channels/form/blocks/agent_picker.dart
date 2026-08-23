import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// Que hace el agente que atiende el canal: vender, dar soporte o atender en
/// general.
///
/// Es una sola eleccion y cambia como se comporta el modelo de punta a punta
/// —el tono, hacia donde lleva la conversacion, que hace cuando no sabe algo—,
/// no que datos ve: eso lo decide el bloque de datos.
///
/// Escucha solo a `role`: elegir un rol no repinta ni las credenciales ni el
/// resto del formulario.
class AgentPicker extends StatelessWidget {
  const AgentPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).channel_role_title,
    subtitle: S.of(context).channel_role_subtitle,
    child: ValueListenableBuilder<ChannelAgentRole>(
      valueListenable: controller.role,
      builder: (context, selected, _) => OptionGrid(children: [
        for (final role in ChannelAgentRole.values) OptionCard(
          icon: role.icon,
          title: role.title(context),
          subtitle: role.subtitle(context),
          selected: role == selected,
          action: () => controller.role.value = role
        )
      ])
    )
  );
}
