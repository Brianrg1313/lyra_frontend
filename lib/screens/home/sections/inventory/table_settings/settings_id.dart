import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

import 'settings_block.dart';

/// El identificador de la tabla: tapado, con que destaparlo y con que
/// copiarlo.
///
/// Es el unico dato de la ficha que no se lee, se **usa**: es lo que se pega
/// en un soporte o en una integracion para nombrar a esta tabla. No es un
/// secreto —por si solo no autoriza nada, la peticion viaja igual atada a la
/// empresa— pero tampoco es para tenerlo escrito a la vista mientras se
/// comparte la pantalla, asi que se muestra tapado.
///
/// Se copia sin destaparlo, que es lo que se hace con el casi siempre: el
/// boton copia el identificador entero aunque en pantalla se vean puntos.
/// Destaparlo es para lo otro, comparar de un vistazo que es el que se estaba
/// buscando.
///
/// El valor y sus dos botones van juntos dentro de una caja y no sueltos en la
/// fila como el resto de los datos: esto no es un dato que se lee de corrido,
/// es un valor que se manipula —se destapa, se copia, se pega afuera—, y la
/// caja dice hasta donde llega. Ademas junta los botones con lo que operan:
/// destapar y copiar no valen para la fila, valen para esos caracteres.
///
/// La caja va del color de la pagina y no del de la tarjeta, como las tres
/// cifras de arriba: adentro de un bloque que ya es una superficie, otra del
/// mismo color no se veria.
///
/// Es hermano del identificador de la empresa (`BusinessProfileId`) y no el
/// mismo widget: son dos secciones distintas y lo unico que comparten es la
/// forma de mostrar un uuid.
class TableSettingsId extends StatefulWidget {
  const TableSettingsId({super.key, required this.id});

  final String id;

  @override
  State<TableSettingsId> createState() => _TableSettingsIdState();
}

class _TableSettingsIdState extends State<TableSettingsId> {
  /// Se destapa a pedido y **no queda destapado**: el estado es de esta fila,
  /// asi que volver a la pantalla lo muestra tapado de nuevo.
  bool _visible = false;

  /// Cuantos caracteres quedan a la vista al taparlo. Es el primer bloque del
  /// uuid: alcanza para reconocer cual es sin dejarlo escrito entero.
  static const int _shown = 8;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // `Align` es lo que la deja medir su texto: dentro de la columna del
    // bloque el ancho que llega es el de la tarjeta entera, y una fila lo
    // tomaria todo.
    return Align(
      alignment: Alignment.centerLeft,
      child: Surface(
        color: scheme.surface,
        radius: AppSize.cornerInset(AppSize.spaceS),
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
            SettingsAction(
              icon: _visible ? CI.eye_hidden : CI.eye,
              message: _visible
                ? S.of(context).table_settings_id_hide
                : S.of(context).table_settings_id_show,
              action: () => setState(() => _visible = !_visible)
            ),
            SizedBox(width: AppSize.gap),
            SettingsAction(
              icon: CI.copy,
              message: S.of(context).table_settings_id_copy,
              action: _copy
            )
          ]
        )
      )
    );
  }

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

    FloatFlag.of(context).message(S.of(context).table_settings_id_copied);
  }
}
