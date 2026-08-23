import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Un bloque del formulario de un canal: su titulo, una linea que explica para
/// que sirve y lo que se elige debajo.
///
/// El formulario son cinco decisiones distintas —que red, que hace el agente,
/// de donde saca los datos, que puede procesar y con que credenciales entra— y
/// sin separarlas se lee como una lista de campos sueltos. El subtitulo no es
/// decorativo: casi ninguna de esas decisiones se explica sola con su titulo.
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
