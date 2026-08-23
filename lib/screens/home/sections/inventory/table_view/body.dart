import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

import 'record_row.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';

/// El cuerpo de la planilla: los registros y, debajo, las filas en blanco que se
/// escriben.
///
/// `itemExtent` no es una optimizacion opcional, es lo que hace posible la
/// pantalla: con filas de alto fijo la lista sabe cuanto mide sin construir
/// ninguna, asi que una tabla de cientos de miles de registros se abre y se
/// recorre igual de rapido que una de diez. Sin el, medir el alto obligaria a
/// construirlas todas.
///
/// `addAutomaticKeepAlives` va apagado por lo mismo: las filas no tienen estado
/// que preservar (lo que se escribe vive en los borradores, no en el widget), y
/// a esta escala ni la contabilidad de mantenerlas vivas vale la pena.
class SheetBody extends StatelessWidget {
  const SheetBody({
    super.key,
    required this.shape,
    required this.visible
  });

  /// La forma de la planilla: una columna por clave, en orden.
  final SheetShape shape;

  /// Cuantas filas entran en pantalla. Lo mide el layout de la planilla, y es lo
  /// que asegura que siempre haya filas en blanco hasta abajo de todo.
  final int visible;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();

    // Buscando no hay filas en blanco debajo: lo que se ve son las que
    // coinciden y ahi se termina (ver [SheetMetrics.bodyRows]). Es lo unico que
    // el cuerpo le pregunta al servicio, y solo cambia al empezar o al dejar de
    // buscar.
    final searching = context.select<TableViewService, bool>(
      (service) => service.isSearching
    );

    return ValueListenableBuilder<int>(
      valueListenable: controller.usedRows,
      builder: (context, used, _) {
        final rows = controller.metrics.bodyRows(
          used: used,
          visible: visible,
          blanks: !searching
        );

        // El teclado y la lectura por tramos necesitan saber hasta donde llega
        // la planilla. Es una asignacion pelada, no avisa a nadie: quien la lee
        // lo hace despues del frame.
        controller.setRows(rows);

        return ListView.builder(
          controller: controller.vBody,
          padding: EdgeInsets.zero,
          itemExtent: controller.metrics.rowHeight,
          itemCount: rows,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) => RecordRow(index: index, shape: shape)
        );
      }
    );
  }
}
