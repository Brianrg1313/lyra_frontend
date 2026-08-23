import 'package:flutter/material.dart';

import 'field_cell.dart';
import 'sheet_style.dart';
import 'state/sheet_columns.dart';

/// La fila 1 de la planilla: los campos de la tabla.
///
/// Los ya creados muestran el icono de su tipo y su nombre; las columnas libres
/// del final estan en blanco y esperan que se les escriba un titulo, que es lo
/// que las convierte en campo. Todas se redimensionan desde su borde derecho, y
/// las que ya son un campo se arrastran de lugar desde la celda misma.
///
/// No escucha nada, y ni siquiera sabe que columnas son: le llega la forma de la
/// planilla, asi que solo se rehace cuando gana, pierde o mueve una columna. El
/// titulo, el tipo, el cursor y el ancho los escucha cada celda por su cuenta.
class FieldsRow extends StatelessWidget {
  const FieldsRow({super.key, required this.shape});

  /// La forma de la planilla: una columna por clave, en orden.
  final SheetShape shape;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: SheetTheme.of(context).rowHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, key) in shape.keys.indexed)
          FieldCell(index: index, widthKey: key)
      ]
    )
  );
}
