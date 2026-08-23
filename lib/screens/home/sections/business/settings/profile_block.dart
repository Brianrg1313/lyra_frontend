import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Los datos de un grupo, uno debajo del otro y separados por una linea.
///
/// La separacion es mas ancha que la de una lista cualquiera porque cada dato
/// ya no es un renglon: son tres —nombre, explicacion y valor— y apretados uno
/// contra otro dejan de leerse como datos distintos.
class ProfileFieldList extends StatelessWidget {
  const ProfileFieldList({super.key, required this.fields});

  final List<Widget> fields;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < fields.length; i++) ...[
        if (i > 0) Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
        ),
        fields[i]
      ]
    ]
  );
}

/// Un grupo de datos con su titulo, sobre su propia superficie.
///
/// La superficie es un bloque **sobre** la hoja del cuerpo ([Surface.over]) y
/// no otra hoja: lo que separa es un grupo de datos del siguiente, no una
/// pantalla de otra.
class ProfileBlock extends StatelessWidget {
  const ProfileBlock({
    super.key,
    required this.title,
    required this.fields,
    this.action
  });

  final String title;
  final List<Widget> fields;

  /// Lo que se puede hacer con el grupo entero y no con un dato suyo (agregar
  /// un correo). Va en el titulo porque no pertenece a ninguna fila.
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: TextSmall(
          title,
          color: ThemeColor.of(context).text.secondary
        )),
        ?action
      ]),
      SizedBox(height: AppSize.spaceS),
      ProfileFieldList(fields: fields)
    ]
  );
}
