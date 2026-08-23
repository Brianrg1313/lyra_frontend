import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Un bloque del formulario de una conexion: su titulo, una linea que explica
/// para que sirve y lo que se elige o se escribe debajo.
///
/// Son tres cosas distintas —como se llama la cuenta, de que servicio es y con
/// que credenciales se entra— y sin separarlas se lee como una lista de campos
/// sueltos. El subtitulo no es decorativo: ninguna de las tres se explica sola
/// con su titulo, y la de las credenciales menos que ninguna.
class FormBlock extends StatelessWidget {
  const FormBlock({
    super.key,
    required this.title,
    required this.child,
    this.subtitle
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSize.spaceM),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextMedium(title, bold: true, ellipsis: true),
        if (subtitle != null) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            subtitle!,
            lines: 2,
            ellipsis: true,
            color: ThemeColor.of(context).text.secondary
          )
        ],
        SizedBox(height: AppSize.spaceXS),
        child
      ]
    )
  );
}
