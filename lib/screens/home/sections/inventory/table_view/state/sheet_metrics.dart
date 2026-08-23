import 'dart:math' as math;

/// La geometria de la planilla: cuanto mide una fila, cuantas hay, cuales se
/// ven y adonde hay que desplazarse para que una celda entre en pantalla.
///
/// Es aritmetica pura y por eso vive aparte: antes se calculaba dentro del
/// `build` y se guardaba en el `State` para que la leyera el teclado, lo que
/// ataba el manejo de teclas al orden en que se construia el arbol. Aca no
/// depende de nada del arbol y se prueba sola.
///
/// Todo esto solo cierra porque las dos bandas verticales tienen `itemExtent`:
/// con filas de alto fijo, pasar de una fila a un offset (y al reves) es una
/// multiplicacion, y una tabla de cientos de miles de registros mide su alto sin
/// tener que construir una sola fila.
class SheetMetrics {
  const SheetMetrics({
    required this.rowHeight,
    required this.gutterWidth,
    this.minBlankRows = 5,
    this.prefetch = 10
  });

  /// Alto de una fila y de la fila de campos. Es el mismo para las dos: la fila
  /// de campos es la fila 1 de la planilla, no un encabezado aparte.
  final double rowHeight;

  /// Ancho de la banda de numeros de fila.
  final double gutterWidth;

  /// Filas en blanco que siempre sobran al final, aunque la pantalla ya este
  /// llena: la planilla nunca termina en la ultima fila escrita.
  final int minBlankRows;

  /// Cuantas filas antes de llegar se pide el tramo siguiente de registros. Es
  /// el margen que tiene la lectura para llegar a tiempo: se pide cuando faltan
  /// [prefetch] filas por entrar, no cuando ya se las esta mirando.
  final int prefetch;

  /// Cuantas filas del cuerpo entran en [height]. Se descuenta la fila de
  /// campos, que esta congelada arriba y no se desplaza.
  int visibleRows(double height) => ((height - rowHeight) / rowHeight).ceil();

  /// Cuantas filas tiene el cuerpo.
  ///
  /// [used] son las filas ocupadas (registros, borradores y las que se ganaron
  /// bajando con el teclado) y a esas se les suman las que siempre sobran en
  /// blanco. Nunca menos de las que entran en pantalla, para que la planilla
  /// llegue siempre hasta abajo de todo.
  ///
  /// Con [blanks] en `false` el cuerpo mide exactamente lo ocupado: es la
  /// planilla filtrada por una busqueda, donde las filas en blanco no serian
  /// para escribir —lo que se escribiera ahi no seria de la busqueda— sino
  /// renglones vacios haciendo creer que el resultado sigue.
  int bodyRows({
    required int used,
    required int visible,
    bool blanks = true
  }) => blanks ? math.max(used + minBlankRows, visible) : used;

  /// Primera y ultima fila que se ven con la banda en [offset]. La ultima entra
  /// aunque se vea a medias, y ninguna de las dos se sale de [rows].
  (int, int) rangeAt({
    required double offset,
    required double viewport,
    required int rows
  }) {
    if (rows <= 0) return (0, -1);

    final first = math.max(0, offset ~/ rowHeight);
    final last = math.min(rows - 1, ((offset + viewport) / rowHeight).ceil());

    return (first, math.max(first, last));
  }

  /// Adonde hay que llevar la banda vertical para que se vea la fila [row], o
  /// `null` si ya se ve.
  double? revealRow({
    required int row,
    required double offset,
    required double viewport,
    required double maxExtent
  }) {
    // La fila de los campos esta congelada arriba: siempre se ve.
    if (row < 0) return null;

    final top = row * rowHeight;

    if (top < offset) return math.max(0, top);
    if (top + rowHeight > offset + viewport) {
      return math.min(top + rowHeight - viewport, maxExtent);
    }

    return null;
  }

  /// Adonde hay que llevar la banda horizontal para que se vea una columna que
  /// empieza en [left] y mide [width], o `null` si ya se ve.
  double? revealColumn({
    required double left,
    required double width,
    required double offset,
    required double viewport,
    required double maxExtent
  }) {
    if (left < offset) return math.max(0, left);
    if (left + width > offset + viewport) {
      return math.min(left + width - viewport, maxExtent);
    }

    return null;
  }
}
