import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// Estado a pantalla completa: un icono, un mensaje y, si hay algo que hacer al
/// respecto, un boton.
///
/// Lo usan las secciones del home para lo mismo —no cargo, no hay nada todavia,
/// la busqueda no encontro nada— y por eso vive aca arriba y no dentro de una
/// de ellas: era el mismo widget escrito una vez por seccion.
class SectionMessage extends StatelessWidget {
  const SectionMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.actionIcon
  });

  final IconData icon;
  final String title;

  /// Segunda linea, mas apagada. Sin ella el mensaje es solo el titulo.
  final String? subtitle;

  /// Que hacer. Sin [action] o sin [actionLabel] no se dibuja el boton: hay
  /// estados que solo informan (una busqueda sin resultados no tiene accion).
  final void Function()? action;
  final String? actionLabel;

  /// Icono del boton. Va donde la accion agrega algo (crear una tabla), no
  /// donde solo reintenta.
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.action, color: scheme.text.secondary),
          SizedBox(height: AppSize.spaceS),
          TextMedium(title, bold: true, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              subtitle!,
              textAlign: TextAlign.center,
              color: scheme.text.secondary
            )
          ],
          if (action != null && actionLabel != null) ...[
            SizedBox(height: AppSize.spaceM),
            SizedBox(
              width: AppSize.action * 4,
              child: Button(
                title: actionLabel!,
                leftIcon: actionIcon == null
                  ? null
                  : Icon(actionIcon, color: scheme.button.text),
                action: action!
              )
            )
          ]
        ]
      )
    );
  }
}
