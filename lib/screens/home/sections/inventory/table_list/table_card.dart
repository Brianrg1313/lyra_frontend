import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

import 'table_options.dart';

/// Tarjeta de una tabla: es como se ve el listado en escritorio, donde las filas
/// a lo ancho dejaban medio metro de aire a la derecha de cada titulo.
///
/// Lleva lo mismo que la fila del telefono ([TableListRow]) y en el mismo orden
/// —el icono, el titulo, lo que mide la tabla y su descripcion—, solo que
/// apilado en vez de en un renglon: el ancho de una tarjeta es el de una
/// columna de la grilla, asi que la descripcion entra en dos lineas en lugar de
/// cortarse a la mitad.
///
/// Toda la tarjeta abre la tabla (`/home/inventory/:id`); arriba a la derecha
/// va el boton de sus opciones ([TableOptionsButton]), que es lo unico que se
/// toca sin entrar.
///
/// Lo unico que escucha es **si su tabla se esta importando todavia**: una
/// importacion sigue corriendo despues de que la tabla ya esta en el listado
/// (el backend le pone el tipo a las columnas y recien despues suben las filas,
/// ver [TablesService.import]), y mientras dura la tarjeta lo dice en vez de
/// medir una tabla que todavia no esta. Se lee con `select` y no con `watch`
/// para que una importacion repinte su tarjeta y no la grilla entera.
class TableCard extends StatelessWidget {
  const TableCard({super.key, required this.table});

  final TableLiteModel table;

  /// Alto de la tarjeta. Lo fija la grilla (`mainAxisExtent`) y no el contenido:
  /// una tabla sin descripcion y otra con dos lineas tienen que medir lo mismo,
  /// o la fila de la grilla quedaria despareja.
  ///
  /// Sale de [AppSize] y no es un numero suelto porque las medidas del tema
  /// escalan con la densidad de la pantalla: una tarjeta de alto fijo dejaria
  /// afuera la ultima linea en las pantallas donde el texto crece.
  static double get height => AppSize.action * 3.8;

  /// Ancho maximo de una columna de la grilla. Es un techo y no una medida: la
  /// grilla reparte el ancho que tenga en tantas columnas como entren sin pasar
  /// de esto, asi que la ventana define cuantas y todas terminan iguales.
  static const double maxWidth = 320;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: AppSize.action,
              height: AppSize.action,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(
                  AppSize.cornerInset(AppSize.spaceS)
                )
              ),
              child: Center(child: Icon(
                CI.list,
                size: AppSize.text * 1.2,
                color: scheme.icon
              ))
            ),
            const Spacer(),
            // El boton se corre hacia la esquina: mide lo que mide un boton de
            // icono y la tarjeta ya tiene su padding, asi que sin esto quedaria
            // flotando lejos del borde.
            Transform.translate(
              offset: Offset(AppSize.gap, -AppSize.gap),
              child: TableOptionsButton(table: table)
            )
          ]),
          SizedBox(height: AppSize.spaceXS),
          TextMedium(table.title, ellipsis: true, bold: true),
          SizedBox(height: AppSize.gap),
          Row(children: [
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
          // La descripcion se lleva el resto del alto: es lo unico que puede
          // faltar, y asi la tarjeta de una tabla que no la tiene no acomoda
          // nada distinto, solo deja el hueco vacio.
          if (table.description.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceXS),
            Expanded(child: TextSmall(
              table.description,
              lines: 2,
              ellipsis: true,
              color: scheme.text.secondary
            ))
          ]
        ]
      )
    );
  }

  /// Lo que mide la tabla: sus columnas y sus registros, en un solo renglon.
  ///
  /// Los registros se cuentan aparte de las columnas y esa cuenta puede fallar
  /// sola (ver [TableLiteModel.records]). Cuando no vino, la tarjeta muestra
  /// solo las columnas: es preferible decir menos a decir que una tabla cargada
  /// esta vacia.
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
