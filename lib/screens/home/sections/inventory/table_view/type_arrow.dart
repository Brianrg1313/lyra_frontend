import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_structure_model.dart';

import 'sheet_style.dart';
import 'state/sheet_controller.dart';

/// Flecha del borde derecho de la celda de un campo: despliega los tipos y
/// cambia el de esa columna.
///
/// Va donde se la espera, pegada al titulo de la columna, como en una planilla.
///
/// El [Builder] no es de adorno: el desplegable se ancla a la flecha, asi que
/// hace falta un contexto que este en su lugar del arbol y no en el de la celda
/// entera.
///
/// No lleva tooltip propio: el de la celda ya dice de que tipo es la columna, y
/// dos tooltips anidados se muestran los dos a la vez.
class TypeArrow extends StatelessWidget {
  const TypeArrow({super.key, required this.field});

  final TableFieldModel field;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();
    final style = SheetTheme.of(context);

    return Builder(
      builder: (context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          // El tap de la flecha gana sobre el de la celda: es el hijo, y en el
          // arena de gestos el mas profundo se queda con el toque.
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.pickType(context, field),
          child: Padding(
            padding: EdgeInsets.only(left: AppSize.gap),
            child: Icon(
              CI.arrow_down,
              size: AppSize.text * 1.4,
              color: style.scheme.text.secondary
            )
          )
        )
      )
    );
  }
}
