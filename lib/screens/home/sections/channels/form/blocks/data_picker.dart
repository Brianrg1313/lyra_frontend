import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_data_source.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// De donde saca el modelo lo que sabe: una tabla de productos, un calendario
/// de servicios o una base de conocimiento.
///
/// Es el bloque que ata el canal a datos reales de la empresa. Un canal sin
/// fuente contesta de memoria, que es lo mismo que decir que inventa precios.
///
/// De las tres, hoy **solo la tabla de productos existe**. Las otras dos se
/// muestran apagadas y con su leyenda a proposito: el calendario va a servir
/// para agendar citas y la base de conocimiento para que el modelo responda
/// preguntas o difunda marketing, y quien esta conectando un canal necesita
/// saber que eso viene para no rearmarlo despues.
///
/// Elegida la tabla de productos hay que decir **cual**: la empresa tiene
/// varias y el canal lee de una. Se guarda el id, no el nombre, asi renombrar
/// la tabla no desconecta el canal.
class DataPicker extends StatelessWidget {
  const DataPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).channel_source_title,
    subtitle: S.of(context).channel_source_subtitle,
    child: ValueListenableBuilder<ChannelDataSource>(
      valueListenable: controller.source,
      builder: (context, selected, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OptionGrid(children: [
            for (final source in ChannelDataSource.values) OptionCard(
              icon: source.icon,
              title: source.title(context),
              subtitle: source.subtitle(context),
              selected: source == selected,
              enabled: source.available,
              badge: source.available
                ? null
                : S.of(context).channel_source_soon,
              action: () => controller.source.value = source
            )
          ]),
          if (selected.needsTable) _TableSelect(controller: controller)
        ]
      )
    )
  );
}

/// Cual tabla de productos. Las trae [TablesService], que es la misma cache que
/// usa la seccion de productos, asi que normalmente ya estan cargadas.
///
/// Si la empresa no tiene ninguna se dice, en vez de mostrar un desplegable
/// vacio: lo que hay que hacer es crear una tabla, y eso no se resuelve desde
/// este formulario.
class _TableSelect extends StatelessWidget {
  const _TableSelect({required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();

    if (service.status == TablesStatus.loading ||
        service.status == TablesStatus.idle) {
      return Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS),
        child: const Center(child: Loading())
      );
    }

    if (service.tables.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS),
        child: Row(children: [
          Icon(
            CI.info,
            size: AppSize.text * 1.2,
            color: ThemeColor.of(context).icon
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextSmall(
            S.of(context).channel_source_no_tables,
            lines: 2,
            ellipsis: true,
            color: ThemeColor.of(context).text.secondary
          ))
        ])
      );
    }

    return SelectInput(
      title: S.of(context).channel_source_table_select,
      placeholder: S.of(context).channel_source_table_placeholder,
      emptyText: S.of(context).channel_source_table_empty,
      controller: controller.table,
      leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
      options: [
        for (final table in service.tables)
          SelectOption(
            value: table.id,
            placeholder: table.title,
            // La descripcion ayuda a distinguir dos tablas que se llaman
            // parecido, que es el caso en el que uno duda.
            subtitle: table.description.isEmpty ? null : table.description,
            icon: CI.list
          )
      ]
    );
  }
}
