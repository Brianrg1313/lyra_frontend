import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'sheet_style.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_drag.dart';

/// Lo que se ve mientras una columna esta en el aire: la que se lleva, el
/// fantasma que sigue al puntero y la linea que marca donde va a caer.
///
/// Se dibuja **encima** de la planilla y en sus mismas coordenadas (las del
/// contenido de la banda desplazable), asi que no hay que corregir nada por el
/// desplazamiento: si la banda se corre, esto se corre con ella.
///
/// Y no es un detalle de presentacion: es lo que permite que arrastrar una
/// columna no toque la grilla. Las celdas se enteran del cambio recien al
/// soltar; hasta entonces lo unico que se mueve en pantalla son estas tres
/// cosas, y cada una escucha su propio notificador:
///
/// - Que haya un arrastre lo escucha este widget, y son dos avisos por arrastre.
/// - El fantasma escucha donde esta el puntero, que cambia cada frame, y su
///   contenido va como `child`: se mueve sin volver a construirse.
/// - La linea escucha en que borde caeria, que cambia solo al pasar el medio de
///   una vecina.
///
/// La banda que marca la columna que se esta llevando no escucha nada: se fija
/// al empezar y no se mueve hasta que se suelta.
class ColumnDrag extends StatelessWidget {
  const ColumnDrag({super.key});

  /// Ancho de la linea que marca el borde donde va a caer.
  static const double _line = 2;

  @override
  Widget build(BuildContext context) {
    final drag = context.read<SheetController>().drag;
    final style = SheetTheme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: drag.active,
      builder: (context, active, _) => active
        ? _Ghost(drag: drag, style: style)
        : const SizedBox.shrink()
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({required this.drag, required this.style});

  final SheetDrag drag;
  final SheetStyle style;

  @override
  Widget build(BuildContext context) => Stack(children: [
    // De donde se la esta sacando: la columna sigue en su lugar hasta que se
    // suelte, apenas velada para que se vea que es la que viaja.
    Positioned(
      left: drag.from,
      top: 0,
      bottom: 0,
      width: drag.width,
      child: ColoredBox(color: style.accent.withValues(alpha: 0.08))
    ),

    // Donde va a caer.
    ValueListenableBuilder<int>(
      valueListenable: drag.edge,
      builder: (context, edge, child) => Positioned(
        left: drag.edgeAt(edge) - ColumnDrag._line / 2,
        top: 0,
        bottom: 0,
        width: ColumnDrag._line,
        child: child!
      ),
      child: ColoredBox(color: style.accent)
    ),

    // El titulo de la columna siguiendo al puntero, como el encabezado que se
    // arranco de la fila de campos.
    ValueListenableBuilder<double>(
      valueListenable: drag.x,
      builder: (context, x, child) => Positioned(
        left: x,
        top: 0,
        height: style.rowHeight,
        width: drag.width,
        child: child!
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.headerFill.withValues(alpha: 0.95),
          border: Border.all(color: style.accent)
        ),
        child: Padding(
          padding: style.cellPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              drag.label,
              overflow: TextOverflow.ellipsis,
              style: style.title
            )
          )
        )
      )
    )
  ]);
}
