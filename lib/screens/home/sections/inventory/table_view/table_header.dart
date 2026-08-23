import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_settings/_table_settings.dart';

import 'header_actions.dart';
import 'state/sheet_controller.dart';

/// Barra superior: el boton de volver al listado, el color de la tabla, su
/// nombre y, a la derecha, el estado de la lectura y el guardado de las filas
/// pendientes.
///
/// El nombre lo da la estructura, que es la que trae el de verdad; hasta que
/// llega se muestra el que ya tenia cacheado el listado de tablas y, si tampoco
/// esta (se entro por deep link con el listado sin cargar), uno generico.
///
/// De los dos servicios que mira, de cada uno se lleva **textos ya resueltos** y
/// no los objetos: del listado, el titulo cacheado; de la tabla abierta, el
/// nombre, la descripcion y el color. Las dos cosas se releen seguido —el
/// listado por su cuenta, la estructura cada vez que cambia una columna— y con
/// los objetos esta barra se repintaria por cambios que no son suyos.
class TableHeader extends StatelessWidget {
  const TableHeader({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final controller = context.read<SheetController>();

    final cached = context.select<TablesService, String>(
      (tables) => _cachedTitle(tables.tables, tableId)
    );

    // Del listado tambien sale si esta tabla se sigue importando. Es lo que
    // explica lo que se ve: una planilla de mil filas abierta a los diez
    // segundos de importarla no esta vacia, esta a medio subir.
    final stage = context.select<TablesService, TableImportStage?>(
      (tables) => tables.importStage(tableId)
    );

    // De la estructura se lleva lo que muestra y no el objeto: se relee entera
    // cada vez que cambia una columna, y con el objeto esta barra se repintaria
    // por un titulo de columna que no dice nada de ella.
    final (name, description, color) = context
      .select<TableViewService, (String, String, String)>(
        (service) => (
          service.structure.name,
          service.structure.description,
          service.structure.color
        )
      );

    final tint = _tint(color);

    final title = name.isNotEmpty
      ? name
      : cached.isNotEmpty ? cached : S.of(context).product_table_view_title;

    return Padding(
      padding: EdgeInsets.all(AppSize.gap),
      child: Row(children: [
        FeedbackButton(
          action: () => controller.back(context),
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).inventory,
          child: Center(child: Icon(
            CI.arrow_left,
            color: scheme.text.primary
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        if (tint != null) ...[
          Container(
            width: AppSize.text * 0.75,
            height: AppSize.text * 0.75,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle)
          ),
          SizedBox(width: AppSize.gap)
        ],
        Expanded(child: Row(children: [
          Flexible(child: TextMedium(title, bold: true, ellipsis: true)),
          if (description.isNotEmpty) ...[
            SizedBox(width: AppSize.spaceS),
            Flexible(child: TextSmall(
              description,
              ellipsis: true,
              color: scheme.text.secondary
            ))
          ]
        ])),
        if (stage != null) ...[
          SizedBox(width: AppSize.spaceS),
          SizedBox(
            width: AppSize.text * 0.8,
            height: AppSize.text * 0.8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.gap),
          TextSmall(_stage(context, stage), color: scheme.text.secondary),
          SizedBox(width: AppSize.gap)
        ],
        const HeaderActions(),
        SizedBox(width: AppSize.gap),
        // Los ajustes de la tabla: todo lo que hay de ella menos sus filas
        // —cuantos registros tiene, de que columnas esta hecha, cuanto ve el
        // modelo y que canales la leen—.
        //
        // Se abren al costado y no en otra pantalla: son los ajustes de **esta**
        // planilla, y con el panel abierto la planilla se sigue viendo al lado.
        // Cerrarlo la devuelve entera, con su desplazamiento y su cursor donde
        // estaban. Ver [showTableSettings].
        FeedbackButton(
          action: () => showTableSettings(context, tableId),
          width: AppSize.action,
          height: AppSize.action,
          color: scheme.surfaceOver,
          message: S.of(context).table_settings_title,
          child: Center(child: Icon(
            CI.setting,
            color: scheme.text.primary
          ))
        )
      ])
    );
  }

  /// Que le falta a la tabla, mientras se la esta importando.
  ///
  /// Lleva su propio spinner y no se apoya en el de [HeaderActions]: ese avisa
  /// de las lecturas de esta pantalla, y durante la primera etapa —el backend
  /// tipando las columnas— desde aca no viaja nada, asi que estaria quieto
  /// justo cuando mas falta hace decir que la tabla no esta terminada.
  static String _stage(BuildContext context, TableImportStage stage) =>
    switch (stage) {
      TableImportStage.preparing => S.of(context).import_table_preparing,
      TableImportStage.loading => S.of(context).import_table_loading
    };

  /// Titulo de la tabla segun el listado cacheado, o vacio si todavia no esta
  /// cargado.
  static String _cachedTitle(List<TableLiteModel> tables, String id) {
    for (final table in tables) {
      if (table.id == id && table.title.isNotEmpty) return table.title;
    }
    return "";
  }

  /// Color de la tabla a partir del literal ARGB que trae la estructura
  /// (`0xFF2196F3`), o `null` si no vino o no se puede leer: es un adorno del
  /// encabezado y la pantalla se ve igual sin el.
  static Color? _tint(String raw) {
    if (raw.isEmpty) return null;

    final parsed = int.tryParse(raw);
    return parsed == null ? null : Color(parsed);
  }
}
