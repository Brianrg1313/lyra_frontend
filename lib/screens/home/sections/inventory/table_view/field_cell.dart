import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';

import 'cell_editor.dart';
import 'sheet_style.dart';
import 'type_arrow.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_cursor.dart';
import 'state/sheet_widths.dart';

/// La celda de un campo: la fila 1 de la planilla.
///
/// Se comporta como cualquier otra celda, y ahi esta toda la gracia de la
/// pantalla: **el campo se edita donde se lo ve**. Escribirle un titulo a una
/// columna libre la crea, escribirle otro a un campo lo renombra, vaciarselo lo
/// elimina (con confirmacion) y la flecha le cambia el tipo. Quien decide cual
/// de las cuatro cosas es, al salir de la celda, es `FieldEdit`.
///
/// Y de la misma celda se agarra la columna para llevarla a otro lugar. El
/// arrastre no pasa por aca mas que para empezarlo: lo lleva el controlador y lo
/// dibuja `ColumnDrag` encima de la planilla, asi que mover una columna no
/// vuelve a construir esta celda ni ninguna otra hasta que se la suelta.
///
/// Todo lo suyo lo pregunta ella: el titulo, el tipo y si hay un cambio en
/// camino. Por eso renombrar una columna, cambiarle el tipo o mandar su alta
/// repinta **esta celda** y no la fila de campos, aunque los tres releen la
/// estructura entera de la tabla.
class FieldCell extends StatelessWidget {
  const FieldCell({
    super.key,
    required this.index,
    required this.widthKey
  });

  final int index;
  final String widthKey;

  @override
  Widget build(BuildContext context) {
    final style = SheetTheme.of(context);
    final controller = context.read<SheetController>();

    final state = context.select<SheetCursor, SheetCellState>(
      (cursor) => cursor.stateAt(kFieldsRow, index)
    );

    // Las cuatro cosas cambian juntas y se leen juntas: un registro las compara
    // de una y ahorra tres suscripciones por celda.
    final (name, busy, type, isField) = context
      .select<SheetColumns, (String, bool, String, bool)>(
        (columns) => (
          columns.nameOf(index),
          columns.busyAt(index),
          columns.typeOf(index),
          columns.isFieldAt(index)
        )
      );

    // El modelo del campo solo lo necesita la flecha, para mandar el cambio de
    // tipo. Se lee sin suscribirse: lo que de el se muestra —nombre y tipo— ya
    // esta arriba, asi que esta celda se rehace cuando cambia.
    final field = isField ? context.read<SheetColumns>().fieldAt(index) : null;

    // El titulo de un campo se escribe como el de una columna libre: es la misma
    // celda, y lo que cambia es que salir de ella renombra el campo (o lo
    // elimina, si quedo vacia) en vez de crear uno.
    final Widget content = state == SheetCellState.editing
      ? const CellEditor(type: TableFieldType.text, alignment: TextAlign.left)
      : Row(children: [
          if (isField) ...[
            Icon(
              TableFieldType.from(type).icon,
              size: AppSize.text,
              color: style.scheme.text.secondary
            ),
            SizedBox(width: AppSize.gap)
          ],
          Expanded(child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            // Mientras el cambio viaja (se esta creando, renombrando o
            // eliminando), el titulo se ve apagado: ya es lo que va a quedar,
            // pero todavia no volvio del backend.
            style: busy ? style.pendingTitle : style.title
          )),
          // La flecha del tipo solo esta donde hay un campo: una columna libre
          // todavia no tiene tipo que cambiar, es una celda en blanco. Tampoco
          // esta mientras el campo tenga un cambio en camino: el cambio de tipo
          // manda tambien el nombre que trae la estructura, que hasta que el
          // renombre no vuelva es el viejo, y lo desharia.
          if (field != null && !busy) TypeArrow(field: field)
        ]);

    // Un campo se arrastra de lugar desde su propia celda, como en una planilla.
    // Una columna libre no: todavia no es un campo, no tiene posicion que
    // guardar. Tampoco una que tenga un cambio en camino.
    final movable = isField && !busy;

    Widget cell = MouseRegion(
      // El puntero avisa que ahi se escribe: es lo unico que queda del boton de
      // agregar columna, y ahora tambien del de renombrarla. Es el de escribir y
      // no el de una planilla porque lo que hay ahi es un titulo que se tipea;
      // lo que se toca de esta celda —la flecha del tipo— lleva el suyo. Mientras
      // el cambio viaja no se puede escribir, asi que vuelve al puntero de
      // siempre.
      cursor: busy ? SystemMouseCursors.basic : SystemMouseCursors.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.tap(kFieldsRow, index),
        // El arrastre horizontal y el toque conviven en el mismo detector: la
        // arena de gestos le da el toque al que no se movio y el arrastre al que
        // si, que es exactamente como se lee la celda —se la toca para escribir
        // el titulo, se la arrastra para mover la columna—. La franja del borde
        // derecho, que cambia el ancho, esta encima de esto en el Stack, asi que
        // se queda ella con el arrastre que empieza ahi.
        onHorizontalDragStart: movable
          ? (details) => controller.startColumnDrag(index, details)
          : null,
        onHorizontalDragUpdate: movable ? controller.updateColumnDrag : null,
        onHorizontalDragEnd: movable
          ? (_) => controller.endColumnDrag()
          : null,
        onHorizontalDragCancel: movable ? controller.cancelColumnDrag : null,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: style.cellPadding,
          decoration: style.field(selected: state != SheetCellState.idle),
          child: content
        )
      )
    );

    if (isField) {
      cell = Tooltip(
        message: TableFieldType.from(type).label(context),
        child: cell
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: context.read<SheetWidths>().of(widthKey),
      builder: (context, width, child) => SizedBox(width: width, child: child),
      child: Stack(children: [
        cell,
        // Tirador de ancho: la franja del borde derecho de la celda de campo,
        // como en una planilla. Arrastrarlo solo mueve el notificador de esta
        // columna, asi que el resto de la planilla ni se entera.
        //
        // Al soltarlo, el ancho se guarda con el campo (`PUT /tables/fields/`):
        // no es una preferencia de quien lo arrastro sino como queda la tabla, y
        // la proxima vez que se la abra —la abra quien la abra— las columnas
        // miden esto. Viaja al soltar y no en cada evento del arrastre.
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: AppSize.gap,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => controller.startResize(index),
              onHorizontalDragUpdate: (details) =>
                controller.resize(index, details.delta.dx),
              onHorizontalDragEnd: (_) => controller.endResize(index),
              // Un arrastre que se corta (se perdio el puntero, se abrio algo
              // encima) deja la columna con el ancho que alcanzo a tomar, asi
              // que se guarda igual: es el que se ve.
              onHorizontalDragCancel: () => controller.endResize(index),
              child: const SizedBox.shrink()
            )
          )
        )
      ])
    );
  }
}
