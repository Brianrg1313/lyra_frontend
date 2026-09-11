import 'dart:math';

/// Letters and numbers with which a generated SKU is built, without the ones that
/// get confused with each other when read (0/O, 1/I/L).
const String _kSkuAlphabet = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";

const int _kSkuLength = 12;

/// A new, random SKU, for the empty cell button.
///
/// It asks nothing of the backend: it is enough that it is unlikely to repeat, which
/// is what an alphabet of 31 symbols in 12 positions gives (on the order of
/// 10^17 combinations). It is long on purpose: a short code repeats across
/// catalogs and forces redoing it, and this one is copied and pasted —not dictated—, so
/// what is gained in uniqueness is not paid in convenience. [random] is received
/// so a test can fix the sequence; without it, each call builds its
/// own.
String nextSku({Random? random}) {
  final source = random ?? Random();

  return List.generate(
    _kSkuLength,
    (_) => _kSkuAlphabet[source.nextInt(_kSkuAlphabet.length)]
  ).join();
}
