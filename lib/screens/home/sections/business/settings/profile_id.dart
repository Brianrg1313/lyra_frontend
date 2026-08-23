import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

import 'profile_field.dart';

/// El identificador de la empresa: tapado, con que destaparlo y con que
/// copiarlo.
///
/// Es el unico dato del perfil que no se lee, se **usa**: es lo que se pega en
/// un soporte o en una integracion para nombrar a esta empresa. No es un
/// secreto —por si solo no autoriza nada— pero tampoco es para tenerlo escrito
/// a la vista mientras se comparte la pantalla, asi que se muestra tapado.
///
/// Se copia sin destaparlo, que es lo que se hace con el casi siempre: el boton
/// copia el identificador entero aunque en pantalla se vean puntos. Destaparlo
/// es para lo otro, comparar de un vistazo que es el que se estaba buscando.
///
/// El valor y sus dos botones van juntos dentro de una caja ([Surface.over]) y
/// no sueltos en la fila como el resto de los datos: esto no es un dato que se
/// lee de corrido, es un valor que se manipula —se destapa, se copia, se pega
/// afuera—, y la caja dice hasta donde llega. Ademas junta los botones con lo
/// que operan: destapar y copiar no valen para la fila, valen para esos
/// caracteres, y cruzados al otro extremo del renglon parecian dos acciones
/// mas de la ficha.
///
/// La caja mide lo que miden el identificador y sus botones, no el ancho de la
/// columna: estirada de lado a lado con los botones colgando del borde derecho
/// se leia como una barra de la ficha y no como el envoltorio de un valor.
class BusinessProfileId extends StatefulWidget {
  const BusinessProfileId({super.key, required this.id});

  final String id;

  @override
  State<BusinessProfileId> createState() => _BusinessProfileIdState();
}

class _BusinessProfileIdState extends State<BusinessProfileId> {
  /// Se destapa a pedido y **no queda destapado**: el estado es de esta fila,
  /// asi que volver a la pestana lo muestra tapado de nuevo.
  bool _visible = false;

  /// Cuantos caracteres quedan a la vista al taparlo. Es el primer bloque del
  /// uuid: alcanza para reconocer cual es sin dejarlo escrito entero.
  static const int _shown = 8;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: CI.key,
    label: S.of(context).business_profile_id,
    description: S.of(context).business_profile_id_note,
    child: _box(context)
  );

  /// El identificador y lo que se hace con el, en una sola caja del ancho de su
  /// contenido.
  ///
  /// [Align] es lo que la deja medir su texto: dentro de la columna de la ficha
  /// el ancho que llega es el de la ficha entera, y una fila lo tomaria todo.
  Widget _box(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Surface.over(
      padding: EdgeInsets.only(
        left: AppSize.spaceXS,
        right: AppSize.gap,
        top: AppSize.gap,
        bottom: AppSize.gap
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // El identificador se recorta antes que los botones si la ficha se
          // pone muy angosta: `Flexible` y no `Expanded`, que se llevaria el
          // ancho que sobra aunque el texto no lo necesite.
          Flexible(child: TextMedium(
            _visible ? widget.id : _masked,
            lines: 2,
            ellipsis: true,
            // Tapado no hay nada que seleccionar: lo que se copiaria son los
            // puntos.
            selectable: _visible
          )),
          SizedBox(width: AppSize.gap),
          ProfileAction(
            icon: _visible ? CI.eye_hidden : CI.eye,
            message: _visible
              ? S.of(context).business_profile_id_hide
              : S.of(context).business_profile_id_show,
            action: () => setState(() => _visible = !_visible)
          ),
          SizedBox(width: AppSize.gap),
          ProfileAction(
            icon: CI.copy,
            message: S.of(context).business_profile_id_copy,
            action: _copy
          )
        ]
      )
    )
  );

  /// El identificador con todo tapado menos el primer bloque.
  ///
  /// Los guiones se dejan: conservan la forma del uuid, asi que lo que se ve
  /// sigue leyendose como un identificador y no como un renglon de puntos.
  String get _masked {
    if (widget.id.length <= _shown) return "•" * widget.id.length;

    final hidden = [
      for (final char in widget.id.substring(_shown).split(""))
        char == "-" ? "-" : "•"
    ].join();

    return "${widget.id.substring(0, _shown)}$hidden";
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.id));

    if (!mounted) return;

    FloatFlag.of(context).message(S.of(context).business_profile_id_copied);
  }
}
