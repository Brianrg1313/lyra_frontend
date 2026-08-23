import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import '../sheet_style.dart';

/// La celda de un campo de tipo SKU, fuera de edicion.
///
/// Se distingue de una celda de texto en dos cosas.
///
/// La primera es el color: el codigo va en gris ([SheetStyle.code]) y no con el
/// del dato. Un SKU no es algo que se lea ni que se compare de un vistazo con el
/// de la fila de al lado —es la etiqueta con la que se encuentra el producto— y
/// en una planilla llena, en negro, es la columna que mas ruido hace: son las
/// cadenas mas largas y las menos legibles de todas.
///
/// La segunda es que, mientras esta vacia y se puede escribir, lleva a la
/// derecha un boton que arma un codigo al azar ([SheetController.generateSku])
/// sin pasar por el editor. Una vez que la celda tiene algo cargado el boton se
/// va: es solo para no dejar la primera carga en blanco, no una forma de
/// reemplazar lo que ya se escribio.
///
/// Es un boton y no un icono suelto —marco relleno, redondeado, con respuesta
/// al pasarle el mouse—, y eso es lo que lo hace tocable a la vista. Pero sin
/// etiqueta: una celda de planilla es angosta y un texto adentro se come la
/// columna. Lo que hace lo dice el icono de destello, que es el de "generar" y
/// no el de recargar que estaba antes, y el globo de ayuda al pasar por encima,
/// como la fila de campos.
///
/// Va contra el borde derecho por lo mismo que la flecha de una lista: es un
/// control, no el dato, y de ese lado no le pisa el lugar al codigo cuando
/// aparezca.
///
/// El relleno sale de [SheetStyle.frameFill] y depende de que fila sea, por lo
/// mismo que en [SelectCell]: con la cebra la planilla usa sus dos superficies
/// fila por medio, asi que el boton se lleva la que su fila no esta usando y se
/// ve en las dos bandas.
class SkuCell extends StatelessWidget {
  const SkuCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.row,
    required this.editable,
    required this.onGenerate
  });

  /// El SKU tal como esta guardado (o tal como se acaba de escribir en el
  /// borrador de la fila).
  final String value;

  final TextStyle style;

  final TextAlign alignment;

  /// En que fila de la planilla esta. Decide de que banda de la cebra es su
  /// fondo, y con eso el relleno del boton (ver [SheetStyle.frameFill]).
  final int row;

  /// Si la celda se puede escribir. Sin esto el boton apareceria tambien en un
  /// campo que lleva el backend o en una fila cuyo registro todavia no llego.
  final bool editable;

  /// Arma un SKU nuevo y lo guarda en esta celda. `null` cuando no aplica (ver
  /// [editable]), que es lo mismo que no mostrar el boton.
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);

    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      // El codigo va en gris y no con el color del dato: no es algo que se lea,
      // es la etiqueta con la que se encuentra el producto (ver
      // [SheetStyle.code]). Es asi siempre, se pueda escribir la celda o no: el
      // gris no dice que este apagada, dice que eso es un codigo.
      style: sheet.code
    );

    if (value.isNotEmpty || !editable || onGenerate == null) return text;

    // Poco mas alto que una letra: tiene que leerse como un boton sin pesar
    // como uno de barra, que en una fila de planilla no entra.
    final size = AppSize.text * 1.8;

    return Row(children: [
      Expanded(child: text),
      Tooltip(
        // El icono dice que hay algo para generar; esto, que el codigo sale de
        // la nada y que se puede pedir otro. No es el titulo del boton: es lo
        // que un icono solo no alcanza a contar.
        message: S.of(context).product_table_view_sku_generate_hint,
        child: FeedbackButton(
          message: S.of(context).product_table_view_sku_generate,
          width: size,
          height: size,
          radius: sheet.frameRadius,
          color: sheet.frameFill(row: row),
          action: onGenerate,
          child: Center(child: Icon(
            CI.ia,
            size: AppSize.text,
            color: sheet.scheme.text.primary
          ))
        )
      )
    ]);
  }
}
