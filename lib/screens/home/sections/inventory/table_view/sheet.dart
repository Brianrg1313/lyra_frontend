import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'body.dart';
import 'column_drag.dart';
import 'fields_row.dart';
import 'gutter.dart';
import 'sheet_style.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';

/// La planilla: la banda congelada de numeros de fila y, al lado, la de datos
/// con la fila de campos arriba y los registros debajo.
///
/// Ocupa todo lo que le den: no hay pie debajo, asi que la ultima fila visible
/// llega hasta el borde y se sigue bajando desde ahi.
///
/// Este widget solo se rehace cuando cambia **la forma** de la grilla: una
/// columna que se agrega, se elimina o se arrastra a otro lugar, o el tamaño de
/// la ventana. Nada mas. Renombrar una columna o cambiarle el tipo **no pasa por
/// aca**, aunque los dos releen la estructura entera: lo que se escucha es
/// [SheetColumns.shape], que sigue siendo la misma, y el titulo y el tipo se los
/// pregunta cada celda por su cuenta.
///
/// Arrastrar una columna tampoco pasa por aca **mientras dura**: lo que se mueve
/// con el puntero es el fantasma de [ColumnDrag], dibujado encima. La grilla se
/// entera una sola vez, al soltar.
///
/// El resto (el cursor, los anchos, los tramos de registros que van entrando, lo
/// que se escribe) lo escuchan las celdas y las filas, cada una lo suyo.
class Sheet extends StatelessWidget {
  const Sheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();

    // La forma conserva su instancia mientras las columnas no cambien de
    // cantidad, de lugar ni de lado del que leen, asi que alcanza con
    // compararla por identidad.
    final shape = context.select<SheetColumns, SheetShape>(
      (columns) => columns.shape
    );

    final style = SheetStyle(
      scheme: ThemeColor.of(context),
      rowHeight: controller.metrics.rowHeight,
      gutterWidth: controller.metrics.gutterWidth
    );

    return SheetTheme(
      style: style,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Cuantas filas se ven de una: es lo que decide cuantas filas en
          // blanco sobran, para que la planilla llegue siempre hasta abajo.
          final visible = controller.metrics.visibleRows(constraints.maxHeight);
          final available = math.max(
            0.0,
            constraints.maxWidth - style.gutterWidth
          );

          // Se apagan las scrollbars automaticas de cada banda para mostrar solo
          // una vertical (la de la planilla entera) y una horizontal.
          return Focus(
            focusNode: controller.grid,
            onKeyEvent: controller.handleKey,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false
              ),
              child: Scrollbar(
                controller: controller.vBody,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SheetGutter(visible: visible),
                    Expanded(child: Scrollbar(
                      controller: controller.horizontal,
                      notificationPredicate: (n) =>
                        n.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: controller.horizontal,
                        scrollDirection: Axis.horizontal,
                        child: ValueListenableBuilder<double>(
                          valueListenable: controller.widths.total,
                          builder: (context, total, child) => SizedBox(
                            width: math.max(total, available),
                            child: child
                          ),
                          // El arrastre de una columna se dibuja encima de la
                          // grilla y en sus mismas coordenadas. No recibe
                          // toques: el arrastre lo lleva la celda de la que se
                          // agarro la columna.
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FieldsRow(shape: shape),
                                  Expanded(child: SheetBody(
                                    shape: shape,
                                    visible: visible
                                  ))
                                ]
                              ),
                              const IgnorePointer(child: ColumnDrag())
                            ]
                          )
                        )
                      )
                    ))
                  ]
                )
              )
            )
          );
        }
      )
    );
  }
}
