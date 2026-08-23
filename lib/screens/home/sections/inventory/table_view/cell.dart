import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

import 'cell_editor.dart';
import 'cells/_cells.dart';
import 'sheet_style.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_cursor.dart';
import 'state/sheet_hover.dart';
import 'state/sheet_drafts.dart';
import 'state/sheet_widths.dart';

/// Una celda del cuerpo de la planilla.
///
/// Escucha exactamente cuatro cosas, y ninguna de las cuatro es la pantalla:
///
/// - **El cursor**: como esta ella (su borde) y si el cursor esta en su fila (el
///   fondo, que es de la fila entera). Mover el cursor dispara el comparador de
///   todas las celdas visibles y vuelve a construir las dos filas que cambiaron.
/// - **Si el mouse esta sobre su fila**, que es lo mismo pero para el resaltado
///   del puntero: un booleano por celda y dos filas repintadas por movimiento.
/// - **El ancho de su columna**, que tiene un notificador propio: arrastrar el
///   borde de una columna no toca a las demas, y dentro de esta el ancho es lo
///   unico que se rehace —el contenido se pasa como `child` y sobrevive intacto
///   a todo el arrastre.
/// - **El tipo de su columna**, que es lo que decide con que editor se escribe y
///   hacia que lado se alinea. Se pregunta aca y no se recibe de la fila para que
///   cambiarle el tipo a un campo repinte esa columna y no la grilla: el resto de
///   las celdas corre un comparador que da lo mismo de siempre y no se rehace.
///
/// Su valor no lo escucha: se lo dan hecho ([saved] para un registro, [draft]
/// para una fila que se esta escribiendo). El del borrador se lee del objeto en
/// cada construccion a proposito: mientras se escribe lo muestra el editor, y
/// cuando el editor se cierra esta celda ya se esta reconstruyendo por el
/// cursor, asi que ahi lee el texto que quedo.
class SheetCellView extends StatelessWidget {
  const SheetCellView({
    super.key,
    required this.row,
    required this.position,
    required this.slot,
    required this.widthKey,
    required this.record,
    required this.saved,
    required this.draft
  });

  /// Fila del cuerpo (0 es el primer registro).
  final int row;

  /// Posicion de la columna dentro de la planilla: donde se la ve.
  final int position;

  /// De que lugar de la fila sale su valor.
  ///
  /// No es lo mismo que [position] desde que las columnas se arrastran: los
  /// registros llegan alineados a los campos tal como los da la estructura y ahi
  /// se quedan, asi que mover una columna de lugar no toca ni un dato leido,
  /// solo cambia por donde lo busca su celda.
  final int slot;

  /// Clave con la que se recuerda el ancho de la columna.
  final String widthKey;

  /// Si la fila es un registro de la tabla o una de las que se escriben.
  final bool record;

  /// El registro de esta fila, o `null` si su tramo todavia no llego.
  final TableRowModel? saved;

  /// El borrador de esta fila, o `null` si todavia no se escribio nada en ella.
  final SheetDraft? draft;

  @override
  Widget build(BuildContext context) {
    final style = SheetTheme.of(context);
    final controller = context.read<SheetController>();

    // Las dos cosas que el cursor le dice a una celda, en una sola suscripcion:
    // como esta ella (que decide su borde) y si el cursor esta en su fila (que
    // decide el fondo de la fila entera). Van juntas porque las dos se contestan
    // del mismo dato y en el mismo momento: preguntarlas por separado seria
    // correr dos comparadores por celda en cada movimiento del cursor.
    final (state, inCursorRow) = context
      .select<SheetCursor, (SheetCellState, bool)>(
        (cursor) => (cursor.stateAt(row, position), cursor.isRow(row))
      );

    // Y si el mouse esta encima de su fila. Es un booleano, asi que pasar el
    // puntero de una fila a otra corre el comparador de las celdas que se ven y
    // reconstruye las dos filas que cambiaron.
    final hovered = context.select<SheetHover, bool>(
      (hover) => hover.at(row)
    );

    final (code, isField) = context.select<SheetColumns, (String, bool)>(
      (columns) => (columns.typeOf(position), columns.isFieldAt(position))
    );

    final type = TableFieldType.from(code);

    // Una columna libre todavia no tiene donde guardar (no hay FIELD_ID), asi
    // que sus celdas se ven pero no se escriben hasta que la columna se cree. Y
    // un registro se escribe cuando ya llego con su id: sin el no hay a que fila
    // de la tabla mandarle el cambio.
    final editable = isField
      && type.editable
      && (!record || (saved?.id.isNotEmpty ?? false));

    // Como se ve el dato lo decide su tipo, no esta celda: cada tipo que se
    // muestra distinto tiene su widget en `cells/` (ver [SheetCells.value]).
    final Widget content = state == SheetCellState.editing
      ? CellEditor(type: type, alignment: type.alignment)
      : SheetCells.value(
          type: type,
          value: record
            ? saved?.at(slot)?.toString() ?? ""
            : draft?.values[slot] ?? "",
          // El valor sin convertir a texto, para el unico tipo que no guarda
          // uno: una imagen guarda la lista de ids de su galeria (ver
          // [ImageCell]).
          raw: record ? saved?.at(slot) : draft?.values[slot],
          alignment: type.alignment,
          // Los campos que lleva el backend (contador, stock) no se escriben a
          // mano: se ven como un dato mas, pero apagados.
          style: editable || record ? style.value : style.readOnlyValue,
          row: row,
          column: position,
          // La clave de la columna, no su posicion: es con lo que una fecha
          // recuerda en que formato se la esta leyendo (ver [DateCell]), igual
          // que el ancho.
          columnKey: widthKey,
          editable: editable,
          // Solo un SKU vacio y que se puede escribir ofrece armarse solo: ver
          // [SkuCell].
          onGenerateSku: editable && type == TableFieldType.sku
            ? () => controller.generateSku(SheetCell(row, position))
            : null
        );

    return ValueListenableBuilder<double>(
      valueListenable: context.read<SheetWidths>().of(widthKey),
      builder: (context, width, child) => SizedBox(width: width, child: child),
      child: MouseRegion(
        // El puntero dice que se puede hacer ahi antes de tocar: el de escribir
        // donde se escribe y el de un boton donde se despliega algo (una lista,
        // una imagen). Lo decide el tipo, como la alineacion. Donde no se
        // escribe —lo que lleva el backend, una fila que todavia no llego— no va
        // ninguno de los dos: ofrecerlos seria prometer algo que no pasa.
        cursor: editable ? type.cursor : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // El contexto de la celda va con el toque porque hay un tipo que abre
          // algo anclado a ella: una lista despliega sus opciones donde esta la
          // celda, y eso necesita saber que lugar de la pantalla ocupa. Es este
          // contexto y no el del `GestureDetector` a proposito: el primer render
          // que cuelga de el es la caja de la columna entera, que es de donde
          // tiene que colgar el desplegable.
          onTap: () => controller.tap(row, position, anchor: context),
          child: Container(
            alignment: type.alignment == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
            // Los tipos que se eligen dibujan su propio marco adentro (ver
            // [SelectCell]), asi que en vez del aire de un texto les toca el de
            // un marco: parejo por los cuatro lados, o arriba y abajo se apoya
            // contra la cuadricula y se confunde con ella.
            padding: type.picker ? style.framePadding : style.cellPadding,
            decoration: style.cell(
              row: row,
              selected: state != SheetCellState.idle,
              // El cursor le gana al mouse: la fila donde se esta parado se ve
              // como tal aunque el puntero este pasando por encima de ella.
              fill: inCursorRow
                ? SheetRowFill.selected
                : hovered
                  ? SheetRowFill.over
                  : SheetRowFill.plain
            ),
            child: content
          )
        )
      )
    );
  }
}
