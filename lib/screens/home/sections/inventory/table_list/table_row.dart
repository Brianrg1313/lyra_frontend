import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

import 'table_options.dart';

/// Fila del listado de tablas: el icono, el titulo con lo que mide la tabla
/// (cuantas columnas y cuantos registros) y, si la tiene, la descripcion. Al
/// tocarla abre la vista de la tabla y sus datos (`/home/inventory/:id`).
///
/// A la derecha lleva el boton de sus opciones, que es desde donde se la
/// renombra, se abren sus ajustes y se la elimina sin tener que abrirla
/// ([TableOptionsButton]).
///
/// Es la forma que toma el listado en telefono; en escritorio la misma tabla se
/// dibuja como una tarjeta de la grilla ([TableCard]).
///
/// Lo unico que escucha es **si su tabla se esta importando todavia**: una
/// importacion sigue corriendo despues de que la tabla ya esta en el listado
/// (el backend le pone el tipo a las columnas y recien despues suben las filas,
/// ver [TablesService.import]), y mientras dura la fila lo dice en vez de medir
/// una tabla que todavia no esta. Se lee con `select` y no con `watch` para que
/// una importacion repinte su fila y no el listado entero.
class TableListRow extends StatelessWidget {
  const TableListRow({super.key, required this.table});

  final TableLiteModel table;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final stage = context.select<TablesService, TableImportStage?>(
      (tables) => tables.importStage(table.id)
    );

    return FeedbackButton(
      action: () => Navis.push(context, "/home/inventory/${table.id}"),
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: scheme.surfaceOver,
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Center(child: Icon(
            CI.list,
            size: AppSize.text * 1.2,
            color: scheme.icon
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextMedium(table.title, ellipsis: true, bold: true)),
              SizedBox(width: AppSize.spaceS),
              if (stage != null) ...[
                SizedBox(
                  width: AppSize.text * 0.8,
                  height: AppSize.text * 0.8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.text.secondary
                  )
                ),
                SizedBox(width: AppSize.gap)
              ],
              Flexible(child: TextSmall(
                stage == null ? _size(context) : _stage(context, stage),
                ellipsis: true,
                color: scheme.text.secondary
              ))
            ]),
            if (table.description.isNotEmpty) ...[
              SizedBox(height: AppSize.gap),
              TextSmall(
                table.description,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ]
        )),
        SizedBox(width: AppSize.spaceS),
        TableOptionsButton(table: table)
      ])
    );
  }

  /// Lo que mide la tabla: sus columnas y sus registros, en un solo renglon.
  ///
  /// Los registros se cuentan aparte de las columnas y esa cuenta puede fallar
  /// sola (ver [TableLiteModel.records]). Cuando no vino, la fila muestra solo
  /// las columnas: es preferible decir menos a decir que una tabla cargada esta
  /// vacia.
  String _size(BuildContext context) {
    final fields = S.of(context).table_field_count(table.fields);

    final records = table.records;
    if (records == null) return fields;

    return "$fields · ${S.of(context).table_record_count(records)}";
  }

  /// Que le falta a la tabla, mientras se la esta importando.
  ///
  /// Ocupa el lugar de la medida y no se suma a ella porque esa medida todavia
  /// no significa nada: las columnas pueden cambiar de aca al final (el backend
  /// le agrega la de imagen) y las filas ni siquiera empezaron a subir. Decir
  /// "0 registros" de una planilla de mil filas seria peor que no decir nada.
  String _stage(BuildContext context, TableImportStage stage) => switch (stage) {
    TableImportStage.preparing => S.of(context).import_table_preparing,
    TableImportStage.loading => S.of(context).import_table_loading
  };
}
