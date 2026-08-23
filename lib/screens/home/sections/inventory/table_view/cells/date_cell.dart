import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_date.dart';

import '../sheet_style.dart';
import '../state/sheet_dates.dart';

/// La celda de un campo de tipo fecha, fuera de edicion.
///
/// Una fecha guardada es `2026-02-12`, que es como viaja y como se compara, pero
/// no como se lee: una columna de guiones y ceros hay que descifrarla numero por
/// numero. Aca se muestra escrita —`Feb 12, 2026`, en el idioma de la app— que
/// es la forma en la que el mes se reconoce sin leerlo.
///
/// A la derecha lleva el boton que la pasa a la **fecha completa**: el dia en
/// cifras y, si se cargo una, su hora (`2026-02-12 12:30 PM`). Las dos lecturas
/// hacen falta y ninguna reemplaza a la otra: la escrita es la de entender de un
/// vistazo, la completa es la de comparar dos filas, copiar la fecha a otro lado
/// o controlar a que hora paso algo.
///
/// El boton cambia **la columna entera** y no su celda (ver [SheetDates]): una
/// columna de fechas se lee como una tira, y con cada fila en un formato
/// distinto dos fechas dejarian de compararse de un vistazo.
///
/// Lo que no es una fecha se muestra tal como se cargo, sin boton: mientras el
/// dato no sea una fecha, escribirlo como una seria afirmar algo que no se sabe.
/// Es tambien lo que hace que una tabla recien importada —con la columna llena
/// de vaya a saber que— no pierda ni un dato por no haberse entendido.
class DateCell extends StatelessWidget {
  const DateCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.row,
    required this.columnKey
  });

  /// La fecha tal como esta guardada (o tal como se acaba de escribir en el
  /// borrador de la fila).
  final String value;

  final TextStyle style;

  final TextAlign alignment;

  /// En que fila de la planilla esta. Decide de que banda de la cebra es su
  /// fondo, y con eso el relleno del boton (ver [SheetStyle.frameFill]).
  final int row;

  /// Clave de su columna: la misma con la que se recuerda su ancho. Es con lo
  /// que la celda pregunta —y cambia— como se esta leyendo esa columna.
  final String columnKey;

  @override
  Widget build(BuildContext context) {
    final date = ProductDate.parse(value);

    if (date == null) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      );
    }

    final sheet = SheetTheme.of(context);

    // Solo su columna: cambiar el formato de una no puede repintar las fechas de
    // las demas.
    final full = context.select<SheetDates, bool>(
      (dates) => dates.isFull(columnKey)
    );

    final locale = Localizations.localeOf(context).toString();

    // Poco mas alto que una letra, como el de generar un SKU: tiene que leerse
    // como un boton sin pesar como uno de barra, que en una fila de planilla no
    // entra.
    final size = AppSize.text * 1.8;

    return Row(children: [
      Expanded(child: Text(
        full ? date.full(locale) : date.short(locale),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      )),
      Tooltip(
        // El icono dice a que se pasa; esto, que lo que cambia es la columna y
        // no esta fila sola.
        message: full
          ? S.of(context).product_table_view_date_short_hint
          : S.of(context).product_table_view_date_full_hint,
        child: FeedbackButton(
          message: full
            ? S.of(context).product_table_view_date_short
            : S.of(context).product_table_view_date_full,
          width: size,
          height: size,
          radius: sheet.frameRadius,
          color: sheet.frameFill(row: row),
          action: () => context.read<SheetDates>().toggle(columnKey),
          child: Center(child: Icon(
            // El icono es el formato al que se va, no el que se esta mirando:
            // un boton dice lo que hace.
            full ? CI.calendar : Icons.schedule,
            size: AppSize.text,
            color: sheet.scheme.text.primary
          ))
        )
      )
    ]);
  }
}
