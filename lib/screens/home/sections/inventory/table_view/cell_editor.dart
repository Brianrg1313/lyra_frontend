import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/inventory/table_field_type.dart';

import 'sheet_style.dart';
import 'state/sheet_controller.dart';

/// El editor de la celda activa.
///
/// Es el **unico** [TextField] de la planilla: se mueve con el cursor, y su
/// [FocusNode] es el que atiende las teclas de navegacion (las ve antes que el
/// propio campo de texto, asi Tab no cambia de widget y Enter no dispara el
/// submit).
///
/// El controlador y el foco no son suyos: los crea y los libera
/// [SheetController], que es quien sabe cuando se abre y se cierra una celda.
/// Por eso este widget se lee con `context.read` y no escucha nada: cuando hay
/// que moverlo, la celda que lo contiene ya se esta reconstruyendo.
class CellEditor extends StatelessWidget {
  const CellEditor({super.key, required this.type, required this.alignment});

  /// Tipo del campo, que decide con que teclado se escribe.
  final TableFieldType type;

  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();
    final style = SheetTheme.of(context);

    return TextField(
      controller: controller.editor,
      focusNode: controller.focus,
      autofocus: true,
      textAlign: alignment,
      keyboardType: type.keyboard,
      onChanged: controller.onChanged,
      // Una fecha se tipea con el teclado numerico, donde la barra no esta: el
      // espacio la escribe por uno (ver [DateSeparatorFormatter]).
      inputFormatters: type.isDate ? const [DateSeparatorFormatter()] : null,
      // Se escribe con la letra con la que se lee. Es casi siempre la del dato,
      // salvo en un codigo, que va en gris (ver [SkuCell]): con la de siempre,
      // entrar en la celda le cambiaria el color al texto que ya estaba puesto.
      style: type == TableFieldType.sku ? style.code : style.value,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero
      )
    );
  }
}
