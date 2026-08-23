import 'dart:math';

/// Letras y numeros con los que se arma un SKU generado, sin los que se
/// confunden entre si al leerlos (0/O, 1/I/L).
const String _kSkuAlphabet = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";

const int _kSkuLength = 12;

/// Un SKU nuevo, al azar, para el boton de la celda vacia.
///
/// No pide nada al backend: alcanza con que sea improbable que se repita, que
/// es lo que da un alfabeto de 31 simbolos en 12 posiciones (del orden de
/// 10^17 combinaciones). Es largo a proposito: un codigo corto se repite entre
/// catalogos y obliga a rehacerlo, y este se copia y se pega —no se dicta—, asi
/// que lo que se gana en unicidad no se paga en comodidad. [random] se recibe
/// para que un test pueda fijar la secuencia; sin el, cada llamada arma el
/// suyo.
String nextSku({Random? random}) {
  final source = random ?? Random();

  return List.generate(
    _kSkuLength,
    (_) => _kSkuAlphabet[source.nextInt(_kSkuAlphabet.length)]
  ).join();
}
