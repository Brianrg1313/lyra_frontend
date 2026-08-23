import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

import 'sheet_style.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_cursor.dart';
import 'state/sheet_drafts.dart';
import 'state/sheet_hover.dart';

/// La columna congelada de la izquierda: arriba la esquina (el numero de la fila
/// de campos, que es la 1) y debajo el numero de cada fila, que en la que se
/// esta guardando deja lugar a un spinner.
class SheetGutter extends StatelessWidget {
  const SheetGutter({super.key, required this.visible});

  final int visible;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();
    final style = SheetTheme.of(context);

    // La banda de numeros enumera exactamente las filas del cuerpo, asi que
    // cuenta igual que el: buscando no hay filas en blanco que numerar.
    final searching = context.select<TableViewService, bool>(
      (service) => service.isSearching
    );

    return SizedBox(
      width: style.gutterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // La esquina lleva el alto de fila a mano: es la unica celda que no
          // esta dentro de un `itemExtent`, y sin el se encogeria al alto de su
          // texto, corriendo hacia arriba toda la banda de numeros respecto de
          // las filas que enumera.
          SizedBox(
            height: style.rowHeight,
            child: DecoratedBox(
              decoration: style.gutter(),
              child: Center(child: Text("1", style: style.number))
            )
          ),
          Expanded(child: ValueListenableBuilder<int>(
            valueListenable: controller.usedRows,
            builder: (context, used, _) => ListView.builder(
              controller: controller.vGutter,
              padding: EdgeInsets.zero,
              itemExtent: style.rowHeight,
              itemCount: controller.metrics.bodyRows(
                used: used,
                visible: visible,
                blanks: !searching
              ),
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) => GutterCell(index: index)
            )
          ))
        ]
      )
    );
  }
}

/// El numero de una fila, o el spinner de la que se esta guardando.
///
/// Escucha dos cosas chicas: si el cursor esta en su fila (para resaltarla) y si
/// el borrador de esa fila esta viajando. **No hay ningun boton**: una fila
/// escrita se guarda sola al salir de ella (ver [SheetController]), y lo unico
/// que esta banda tiene que mostrar es que el alta va en camino.
class GutterCell extends StatelessWidget {
  const GutterCell({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final style = SheetTheme.of(context);

    final records = context.select<TableViewService, int>(
      (service) => service.records
    );

    // La suscripcion se pide siempre, aunque la fila sea un registro y no pueda
    // tener borrador: tiene que ser la misma en cada construccion para no
    // depender de en que orden se registraron.
    final saving = context.select<SheetDrafts, bool>(
      (drafts) => index >= records
        && (drafts.at(index - records)?.saving ?? false)
    );

    final selected = context.select<SheetCursor, bool>(
      (cursor) => cursor.isRow(index)
    );

    final hovered = context.select<SheetHover, bool>(
      (hover) => hover.at(index)
    );

    // El numero se resalta con su fila —si no, el resaltado se cortaria justo
    // donde empieza— y ademas la enciende: pasar el mouse por el numero es estar
    // sobre esa fila, aunque la banda de numeros sea otra lista.
    return MouseRegion(
      onEnter: (_) => context.read<SheetHover>().enter(index),
      onExit: (_) => context.read<SheetHover>().leave(index),
      child: DecoratedBox(
        decoration: style.gutter(fill: selected
          ? SheetRowFill.selected
          : hovered
            ? SheetRowFill.over
            : SheetRowFill.plain),
        child: Center(child: saving
          ? SizedBox(
              width: AppSize.text,
              height: AppSize.text,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: style.accent
              )
            )
          // La fila de campos es la 1, asi que el primer registro es la fila 2.
          : Text("${index + 2}", style: style.number))
      )
    );
  }
}
