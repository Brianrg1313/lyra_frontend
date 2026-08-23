import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';

import 'settings_block.dart';

/// Cuanto ve el modelo de esta tabla y que puede hacer con ella.
///
/// Es la pregunta que trae a la mayoria a esta pantalla: la tabla se carga
/// para que un bot conteste con ella, asi que lo que importa no es cuantas
/// columnas tiene sino cuantas de ellas puede citar, cuantas puede usar sin
/// decirlas y cuantas ni siquiera conoce.
///
/// Las cuatro capacidades de abajo no se configuran aca ni en ningun lado:
/// **salen de los tipos de las columnas**. Una tabla se puede buscar por
/// significado porque tiene una columna indexada, y reserva stock porque tiene
/// una columna de stock. Por eso cada una dice en una linea que la habilita —o
/// que le falta—, que es lo unico accionable: se arregla en la planilla,
/// cambiandole el tipo a una columna.
class TableAgentBlock extends StatelessWidget {
  const TableAgentBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final agent = detail.agent;

    return SettingsBlock(
      title: S.of(context).table_settings_agent_title,
      subtitle: S.of(context).table_settings_agent_subtitle,
      child: SettingsList(rows: [
        SettingsRow(
          icon: CI.eye,
          label: S.of(context).table_settings_agent_visibility,
          hint: S.of(context).table_settings_agent_visibility_hint,
          child: Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap * 0.5,
            children: [
              for (final state in TableFieldVisibility.values)
                _VisibilityCount(
                  state: state,
                  count: detail.columns.of(state)
                )
            ]
          )
        ),
        SettingsValue(
          icon: CI.search,
          label: S.of(context).table_settings_agent_searchable,
          value: agent.searchable
            ? S.of(context).table_settings_available
            : S.of(context).table_settings_unavailable,
          hint: agent.searchable
            ? S.of(context).table_settings_agent_searchable_on
            : S.of(context).table_settings_agent_searchable_off
        ),
        SettingsValue(
          icon: CI.list,
          label: S.of(context).table_settings_agent_filterable,
          value: S.of(context).table_settings_column_count(agent.filterable),
          hint: S.of(context).table_settings_agent_filterable_hint
        ),
        SettingsValue(
          icon: Icons.inventory_2_outlined,
          label: S.of(context).table_settings_agent_stock,
          value: agent.stock
            ? S.of(context).table_settings_available
            : S.of(context).table_settings_unavailable,
          hint: agent.stock
            ? S.of(context).table_settings_agent_stock_on
            : S.of(context).table_settings_agent_stock_off
        ),
        SettingsValue(
          icon: CI.image,
          label: S.of(context).table_settings_agent_image,
          value: agent.image
            ? S.of(context).table_settings_available
            : S.of(context).table_settings_unavailable,
          hint: agent.image
            ? S.of(context).table_settings_agent_image_on
            : S.of(context).table_settings_agent_image_off
        )
      ])
    );
  }
}

/// Cuantas columnas hay en un estado de visibilidad, con lo que ese estado
/// significa debajo.
///
/// Los tres van siempre, tambien los que estan en cero: la fila contesta "que
/// ve el modelo" y para eso hay que ver los tres estados juntos. Un cero que
/// desaparece obligaria a saberse la lista de memoria para notar que falta.
///
/// El que esta en cero se dibuja apagado, para que los que si tienen columnas
/// se lean primero.
class _VisibilityCount extends StatelessWidget {
  const _VisibilityCount({required this.state, required this.count});

  final TableFieldVisibility state;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final color = count == 0
      ? scheme.text.secondary
      : switch (state) {
          TableFieldVisibility.visible => scheme.primary,
          TableFieldVisibility.declared => scheme.accent,
          TableFieldVisibility.hidden => scheme.text.secondary
        };

    return Tooltip(
      message: state.hint(context),
      child: SettingsTag(
        icon: state.icon,
        label: S.of(context).table_settings_type_count(
          state.label(context),
          count
        ),
        color: color
      )
    );
  }
}
