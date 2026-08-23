import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';

import '../sheet_style.dart';

/// La celda de un campo de tipo precio, fuera de edicion.
///
/// Un precio no es un numero: es un numero **en una moneda**, y la moneda no
/// esta en el dato sino en la empresa que lo cobra (ver
/// [BusinessService.currencyCode]) —y como se escribe esa moneda tampoco esta
/// aca, sino en el catalogo de plataforma ([CurrencyCatalogService])—. Por eso
/// esta celda es la unica que mira fuera de la planilla, y por eso es un widget
/// aparte: las dos suscripciones viven aca y no en [SheetCellView], donde las
/// pagarian tambien las celdas de texto —que son casi todas— para no usarlas
/// nunca.
///
/// Lo que se escribe son dos cosas de distinto peso y se pintan como tales: el
/// importe con el color del dato y el simbolo en gris, del lado que corresponda
/// (`$22,23`, `22,23€`). Asi la columna se lee como una columna de numeros
/// —que es como se compara un precio con otro— y el simbolo queda de fondo,
/// repetido en cada fila y sin robarle la vista al valor.
///
/// Un valor que no es un importe se muestra tal como se guardo y sin simbolo:
/// mientras el dato no sea un numero, ponerle moneda seria afirmar algo que no
/// se sabe.
class PriceCell extends StatelessWidget {
  const PriceCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment
  });

  /// El precio tal como esta guardado (o tal como se acaba de escribir en el
  /// borrador de la fila).
  final String value;

  /// Estilo del importe. Lo decide la celda, que sabe si el campo se escribe.
  final TextStyle style;

  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    // Dos suscripciones y no una: la empresa dice **en que moneda** cobra y el
    // catalogo dice **como se escribe**. Cambiar de empresa avisa lo primero y
    // releer el catalogo lo segundo, y la celda tiene que repintarse con
    // cualquiera de los dos.
    final code = context.select<BusinessService, String>(
      (business) => business.currencyCode
    );

    final currency = context.select<CurrencyCatalogService, CurrencyModel>(
      (catalog) => catalog.resolve(code)
    );

    final amount = currency.amount(value);

    // Lo que no es un importe (una celda vacia, un "consultar") se muestra tal
    // como se guardo: ponerle moneda seria afirmar algo que no se sabe.
    if (amount == null) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      );
    }

    // El hueco entre el simbolo y el importe va con el simbolo (y no como un
    // espacio suelto) para que se pinte con su mismo estilo: lo decide la
    // moneda, no la celda.
    final symbol = TextSpan(
      text: currency.leading
        ? "${currency.symbol}${currency.gap}"
        : "${currency.gap}${currency.symbol}",
      style: SheetTheme.of(context).symbol
    );

    return Text.rich(
      TextSpan(children: [
        if (currency.leading) symbol,
        TextSpan(text: amount),
        if (!currency.leading) symbol
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      style: style
    );
  }
}
