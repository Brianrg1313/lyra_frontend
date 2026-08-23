import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/country_model.dart';

/// La bandera de un pais, del tamano de un renglon.
///
/// El icono no viene con la app: es un archivo de la plataforma y llega como un
/// id en el catalogo de paises, asi que se baja de donde `/init` dijo (ver
/// [CountryModel.flagUrl]). Eso es lo que deja habilitar una region nueva sin
/// publicar una version: la bandera llega con la fila.
///
/// Un pais sin bandera cargada —o una que no se pueda bajar, o el catalogo sin
/// base todavia— deja su hueco vacio y no un cartel roto: la lista se sigue
/// leyendo por el nombre, que es el dato. El hueco se ocupa igual para que las
/// opciones de la lista queden alineadas entre si.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.country, this.size});

  final CountryModel country;

  /// Alto de la bandera. Por defecto la altura de un renglon de texto.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final height = size ?? AppSize.text;

    // Casi todas las banderas son 4:3. El ancho se reserva completo aunque la
    // imagen no baje: sin eso, la lista se acomoda distinto en cada fila.
    final width = height * 4 / 3;
    final url = country.flagUrl(width.round());

    return SizedBox(
      width: width,
      height: height,
      child: url.isEmpty ? null : ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.gap / 2),
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const SizedBox.shrink()
        )
      )
    );
  }
}
