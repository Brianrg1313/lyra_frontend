import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import 'option_card.dart';

/// Acomoda las opciones de un bloque en las columnas que entren en el ancho que
/// hay.
///
/// Una debajo de otra, cada opcion se estira de punta a punta para decir tres
/// palabras: el 90% de la tarjeta queda vacio y las cuatro decisiones del
/// formulario se vuelven una lista que hay que recorrer scrolleando. En
/// horizontal el problema es todo el tiempo, porque el ancho es justamente lo
/// que sobra.
///
/// Las columnas no se fijan de antemano sino que salen de [minWidth]: entran
/// las que entren sin bajar de ese ancho, y el sobrante se reparte entre ellas
/// para que la fila cierre justo. Asi el mismo bloque da cuatro columnas a
/// pantalla completa y dos cuando esta en media, sin que nadie declare
/// tamanos por dispositivo.
///
/// Todas las tarjetas miden lo mismo de alto ([OptionCard.height]): en una
/// rejilla, una tarjeta mas alta que su vecina —porque su descripcion ocupaba
/// dos lineas en vez de una— se lee como un error de alineacion.
class OptionGrid extends StatelessWidget {
  const OptionGrid({super.key, required this.children, this.minWidth});

  final List<Widget> children;

  /// Lo mas angosta que puede quedar una tarjeta antes de sacar una columna.
  /// Por debajo de esto el titulo empieza a cortarse, que es peor que tener una
  /// columna menos.
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final gap = AppSize.gap;
      final available = constraints.maxWidth;

      // Sin ancho conocido (dentro de algo que scrollea en horizontal) no hay
      // rejilla posible: se apilan, que es lo unico que siempre funciona.
      if (!available.isFinite) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: child
            )
          ]
        );
      }

      final minimum = minWidth ?? AppSize.action * 4.5;

      // Nunca menos de una columna, y nunca mas que opciones hay: tres opciones
      // en un ancho de cinco columnas son tres tarjetas, no cinco huecos.
      final columns = ((available + gap) / (minimum + gap))
        .floor()
        .clamp(1, children.length);

      // El sobrante se reparte, pero hasta ahi: una sola opcion —la red, cuando
      // se esta editando y ya no se puede cambiar— estirada de punta a punta es
      // el mismo problema que se vino a arreglar.
      //
      // Al piso, porque la suma de las tarjetas y sus separaciones tiene que
      // entrar en la fila: un pelo de mas por el redondeo del punto flotante y
      // la ultima se cae al renglon siguiente.
      final width = math.min(
        (available - gap * (columns - 1)) / columns,
        minimum * 2
      ).floorToDouble();

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child)
        ]
      );
    });
  }
}
