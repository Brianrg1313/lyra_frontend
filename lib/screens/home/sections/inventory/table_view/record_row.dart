import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'cell.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_drafts.dart';
import 'state/sheet_hover.dart';

/// Una fila del cuerpo de la planilla.
///
/// Es la que escucha **su** tramo de registros, y por eso la suscripcion vive
/// aca y no en cada celda: cuando entra una pagina llega la fila entera, asi que
/// reconstruirla entera es la granularidad correcta, y son unas pocas decenas de
/// comparadores por pagina en vez de varios cientos.
///
/// Un registro cuyo tramo todavia no llego es un registro igual —la fila existe,
/// su lugar esta reservado— asi que se ve vacio y no editable hasta que entre.
/// Por eso lo que manda es cuantos registros tiene la tabla y no que haya datos.
///
/// De las columnas no sabe nada mas que su forma: cuantas son, con que clave se
/// recuerda el ancho de cada una y de que lugar de la fila sale su valor. El
/// tipo lo pregunta cada celda, asi que cambiarle el tipo a un campo no pasa por
/// esta fila.
class RecordRow extends StatelessWidget {
  const RecordRow({
    super.key,
    required this.index,
    required this.shape
  });

  final int index;

  /// La forma de la planilla: una columna por clave, en orden.
  final SheetShape shape;

  @override
  Widget build(BuildContext context) {
    // Los registros y el largo de la tabla viajan juntos: si cambia cuantos hay,
    // las filas que se escriben se corren de lugar y esta puede pasar de ser un
    // borrador a ser un registro.
    final (records, saved) = context
      .select<TableViewService, (int, TableRowModel?)>(
        (service) => (service.records, service.rowAt(index))
      );

    final record = index < records;

    // Se pregunta siempre, aunque la fila sea un registro y no vaya a haber
    // borrador: las suscripciones tienen que ser las mismas en cada construccion
    // para no depender de en que orden se registraron. Sobre un registro esto no
    // cuesta nada, porque el indice cae en negativo y no hay nada que buscar.
    final draft = context.select<SheetDrafts, SheetDraft?>(
      (drafts) => record ? null : drafts.at(index - records)
    );

    // Quien avisa por donde pasa el mouse es la fila y no cada celda: es un
    // aviso por fila en vez de uno por celda, y ademas es lo unico que sabe que
    // moverse **dentro** de la fila —de una columna a la de al lado— no es
    // cambiar de fila. El resaltado lo pinta despues cada celda, que es la que
    // sabe de que color es su fondo (ver [SheetStyle.cell]).
    final hover = context.read<SheetHover>();

    return MouseRegion(
      onEnter: (_) => hover.enter(index),
      onExit: (_) => hover.leave(index),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (position, key) in shape.keys.indexed)
            SheetCellView(
              row: index,
              position: position,
              slot: shape.slots[position],
              widthKey: key,
              record: record,
              saved: saved,
              draft: draft
            )
        ]
      )
    );
  }
}
