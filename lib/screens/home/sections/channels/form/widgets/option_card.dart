import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Una opcion elegible del formulario de un canal: su icono, que es y una linea
/// de para que sirve.
///
/// Lo usan los cuatro selectores de la pagina (la red, el rol del agente, la
/// fuente de datos y las herramientas) porque los cuatro eligen lo mismo: una
/// cosa de un puñado, con el subtitulo haciendo el trabajo de explicar la
/// diferencia. Un desplegable no servia: obliga a abrirlo para ver que hay, y
/// lo que hay es justamente lo que se esta decidiendo.
///
/// Va dentro de [OptionGrid], que es quien decide cuantas entran por fila. Por
/// eso la tarjeta es **chica y de alto fijo** ([height]): dos lineas de texto y
/// nada mas. Lo que no entra se corta con puntos suspensivos, y esta bien que
/// se corte —el subtitulo desempata entre dos opciones, no las documenta.
///
/// [enabled] en `false` es la otra razon por la que existe. Hay opciones que
/// **todavia no estan hechas** —el calendario de servicios, la base de
/// conocimiento, las redes que no son de Meta— y se muestran igual, apagadas y
/// con su leyenda: quien esta armando un canal necesita saber que eso va a
/// existir para no armarlo dos veces. Una opcion apagada no responde al tap y
/// se lee de un vistazo como no disponible.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.action,
    this.subtitle,
    this.enabled = true,
    this.badge,
    this.multiple = false
  });

  /// Alto de todas las tarjetas, elegido para que entren el titulo y dos lineas
  /// de subtitulo. Es fijo a proposito: en una rejilla, tarjetas de distinto
  /// alto en la misma fila se leen como un error.
  static double get height => AppSize.action * 1.7;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// `true` si esta elegida. En las herramientas ([multiple]) puede haber
  /// varias a la vez; en el resto, una sola.
  final bool selected;

  /// `false` para lo que todavia no se puede elegir.
  final bool enabled;

  /// Leyenda corta ("Proximamente"), para decir **por que** una opcion esta
  /// apagada. Sin esto, una opcion gris parece un error. Ocupa el lugar de la
  /// marca de elegido, que en una opcion que no se puede elegir no dice nada.
  final String? badge;

  /// Cambia la marca: un tilde cuando se pueden elegir varias, un punto cuando
  /// es una sola. Es la unica pista de si elegir esta reemplaza a lo anterior.
  final bool multiple;

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = selected && enabled;

    // Apagada se dibuja con el color secundario en todo, no solo en el texto:
    // el icono y el borde tienen que irse con el, o la tarjeta sigue pareciendo
    // elegible.
    final tint = !enabled
      ? scheme.text.secondary
      : selected ? scheme.primary : scheme.icon;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: FeedbackButton(
        // Sin accion el widget deja de responder al tap y al teclado, que es
        // exactamente lo que tiene que pasar con una opcion no disponible.
        action: enabled ? action : null,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        color: scheme.surfaceOver,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? scheme.primary : Colors.transparent,
              width: 1.5
            ),
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          // El relleno va aca y no en el boton: son las dos unicas medidas de
          // la tarjeta, y juntas es donde se ve si sobra aire.
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.spaceXS,
            vertical: AppSize.gap * 1.5
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: AppSize.text * 1.2, color: tint),
                SizedBox(width: AppSize.gap),
                Expanded(child: TextMedium(
                  title,
                  ellipsis: true,
                  bold: active
                )),
                SizedBox(width: AppSize.gap),
                if (badge != null)
                  _Badge(text: badge!)
                else
                  _Mark(selected: active, multiple: multiple)
              ]),
              if (subtitle != null) ...[
                SizedBox(height: AppSize.gap),
                // Expanded y no un alto calculado: la tarjeta ya mide lo que
                // mide, y asi el texto se queda con lo que sobre sin empujar.
                Expanded(child: TextSmall(
                  subtitle!,
                  lines: 2,
                  ellipsis: true,
                  color: scheme.text.secondary
                ))
              ]
            ]
          )
        )
      )
    );
  }
}

/// La leyenda de una opcion apagada.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.3
      ),
      decoration: BoxDecoration(
        color: scheme.text.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(text, ellipsis: true, color: scheme.text.secondary)
    );
  }
}

/// La marca de elegido, a la derecha del titulo.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.multiple});

  final bool selected;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 1.2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: selected ? scheme.primary : scheme.line,
          width: 1.5
        ),
        // Cuadrado con puntas para varias, redondo para una sola: es la
        // convencion de siempre y se entiende sin leer nada.
        borderRadius: BorderRadius.circular(multiple ? AppSize.gap : size)
      ),
      child: selected
        ? Center(child: Icon(
            CI.check,
            size: size * 0.65,
            color: scheme.button.text
          ))
        : null
    );
  }
}
