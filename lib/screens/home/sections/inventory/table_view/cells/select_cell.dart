import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import '../sheet_style.dart';

/// La celda de un campo de tipo lista.
///
/// Es la unica celda de la planilla que se ve como un **control** y no como un
/// dato, y tiene que serlo: no se escribe, se toca y se despliega
/// ([SheetController.pickOption]). Una celda que abre algo y se ve igual que una
/// de texto no tiene como avisarlo, asi que lleva adentro el marco de un boton
/// de desplegable —un [Surface] relleno y su flecha—, despegado de los bordes de
/// la celda para que se lea como algo **dentro** de ella y no como la celda
/// misma.
///
/// El relleno sale de [SheetStyle.frameFill] y depende de que fila sea: con la
/// cebra la planilla usa sus dos superficies fila por medio, asi que el marco se
/// lleva la que su fila no esta usando. Con un color fijo desapareceria en la
/// mitad de la planilla.
///
/// El marco esta siempre y no solo en la celda elegida: es lo que dice que esa
/// columna se elige, y eso hay que saberlo **antes** de tocarla. Es una caja por
/// fila, que es lo que cuesta que una columna se explique sola.
///
/// El valor se muestra tal como se guardo, este o no entre las opciones del
/// campo. Un `SELECT` se guarda como texto (es la opcion misma, no un indice a
/// ella), asi que sacar una opcion de la lista no borra lo que ya se habia
/// cargado con ella: se sigue leyendo lo que se capturo, que es el dato que
/// alguien puso, y la lista solo manda sobre lo que se elige de ahora en mas.
class SelectCell extends StatelessWidget {
  const SelectCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.row
  });

  /// La opcion que tiene cargada la celda (o lo que se acaba de elegir en el
  /// borrador de la fila). Vacia mientras no se haya elegido ninguna.
  final String value;

  /// Estilo del valor. Lo decide la celda, que sabe si el campo se escribe.
  final TextStyle style;

  final TextAlign alignment;

  /// En que fila de la planilla esta. Decide de que banda de la cebra es su
  /// fondo, y con eso el relleno del marco (ver [SheetStyle.frameFill]).
  final int row;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);

    return Surface(
      // El marco ocupa la celda entera menos el aire que le deja
      // [SheetStyle.framePadding]. Sin las medidas se encogeria hasta el texto,
      // porque la celda le da su alto pero lo ofrece suelto.
      width: double.infinity,
      height: double.infinity,
      radius: sheet.frameRadius,
      color: sheet.frameFill(row: row),
      padding: EdgeInsets.only(left: AppSize.spaceXS),
      child: Row(children: [
        Expanded(child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment,
          style: style
        )),
        Icon(
          CI.arrow_down,
          size: AppSize.text * 1.4,
          color: sheet.scheme.text.secondary
        )
      ])
    );
  }
}
