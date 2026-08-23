import 'package:flutter/material.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';

import 'date_cell.dart';
import 'image_cell.dart';
import 'price_cell.dart';
import 'select_cell.dart';
import 'sku_cell.dart';

export 'date_cell.dart';
export 'image_cell.dart';
export 'price_cell.dart';
export 'select_cell.dart';
export 'sku_cell.dart';

/// Con que se muestra el valor de una celda que no se esta editando.
///
/// La planilla tiene una sola celda ([SheetCellView]) y ella resuelve todo lo
/// que es igual para todas: el ancho, el borde, el cursor, cuando se abre el
/// editor. Lo unico que cambia segun el tipo del campo es **como se ve el
/// dato**, y eso es lo que se reparte aca: un precio lleva el simbolo de la
/// moneda, una fecha se escribe como fecha, un booleano se ve como un tilde.
///
/// El caso general no gasta un widget: la enorme mayoria de las celdas de una
/// planilla son texto y devuelven el [Text] pelado, sin una capa intermedia que
/// se pagaria cientos de miles de veces. Solo los tipos que de verdad hacen
/// algo distinto —los de esta carpeta— tienen widget propio, y ahi el widget se
/// justifica solo: es lo que les permite escuchar lo suyo (la moneda de la
/// empresa, en [PriceCell]) sin que lo escuche la grilla entera.
///
/// En edicion no pasa por aca: ahi manda el [CellEditor], que es uno solo para
/// toda la planilla y se mueve con el cursor. Una lista tampoco tiene editor —se
/// elige en un desplegable, no se escribe— asi que pasa por aca siempre, tanto
/// cuando es la celda del cursor como cuando no.
abstract final class SheetCells {
  static Widget value({
    required TableFieldType type,
    required String value,
    required TextStyle style,
    required TextAlign alignment,
    required int row,
    required int column,
    required String columnKey,
    dynamic raw,
    bool editable = true,
    VoidCallback? onGenerateSku
  }) => switch (type) {
    TableFieldType.price => PriceCell(
      value: value,
      style: style,
      alignment: alignment
    ),
    // [row] lo miran las dos que se pintan como un control —la lista siempre,
    // el SKU vacio mientras ofrece generarse—: las dos tienen que despegarse
    // del fondo de su fila, y con la cebra ese fondo depende de en que banda
    // caiga la fila (ver [SheetStyle.frameFill]).
    TableFieldType.select => SelectCell(
      value: value,
      style: style,
      alignment: alignment,
      row: row
    ),
    // La unica que no muestra el dato sino **lo que el dato senala**: la celda
    // guarda ids de archivo y lo que se dibuja es la foto. Por eso es la unica
    // que recibe [raw] y no el texto: una galeria es una lista, y el texto de
    // una lista (`[a, b]`) no es ninguna imagen.
    TableFieldType.image => ImageCell(
      raw: raw ?? value,
      row: row,
      column: column
    ),
    // Las dos formas de fecha se leen igual de seguido, asi que el formato es de
    // la columna y no de la celda: por eso mira [columnKey] y no [column].
    TableFieldType.date || TableFieldType.datetime => DateCell(
      value: value,
      style: style,
      alignment: alignment,
      row: row,
      columnKey: columnKey
    ),
    TableFieldType.sku => SkuCell(
      value: value,
      style: style,
      alignment: alignment,
      row: row,
      editable: editable,
      onGenerate: onGenerateSku
    ),
    _ => Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      style: style
    )
  };
}
