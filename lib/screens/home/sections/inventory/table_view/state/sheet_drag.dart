import 'package:flutter/foundation.dart';

import 'sheet_order.dart';

/// El arrastre de una columna, mientras dura.
///
/// Es lo que mas seguido cambia de toda la planilla —un evento de puntero por
/// frame, como el arrastre de un ancho— asi que **no puede tocar la grilla**.
/// Lo que se mueve es un fantasma dibujado encima de las celdas; las columnas no
/// se enteran de nada hasta que se suelta, y ahi se reordenan de una vez.
///
/// Por eso son tres notificadores y no uno:
///
/// - [active] avisa cuando el arrastre empieza y termina. Son dos avisos por
///   arrastre y es lo unico que monta y desmonta el fantasma.
/// - [x] se mueve con el puntero, y lo escucha solo el fantasma.
/// - [edge] cambia cuando la columna pasa el medio de una vecina, que es lo
///   unico que mueve la linea.
///
/// Con un solo notificador, cada frame del arrastre repintaria las tres cosas; y
/// si el estado viviera en las columnas, repintaria la planilla entera.
///
/// Todo lo demas ([source], [label], [width], [edges]) se fija al empezar y no
/// cambia: los anchos no se pueden arrastrar mientras se mueve una columna, asi
/// que la geometria se calcula **una vez** y de ahi en mas cada evento del
/// puntero es una resta y una busqueda sobre una lista de `double`.
///
/// Las coordenadas son las **del contenido** de la banda desplazable (el 0 es el
/// borde izquierdo de la primera columna, no el de la pantalla), que son las
/// mismas en las que estan [edges] y en las que se dibuja el fantasma. Quien
/// traduce el puntero a esas coordenadas es el controlador, que es el que sabe
/// donde esta parada la banda.
class SheetDrag {
  /// Columna que se esta arrastrando, o `-1` si no hay arrastre.
  int source = -1;

  /// Titulo de esa columna, para el fantasma.
  String label = "";

  /// Ancho de esa columna.
  double width = 0;

  /// En que parte de la celda se la agarro. Es lo que hace que el fantasma no
  /// salte bajo el puntero al empezar a moverlo.
  double grab = 0;

  /// Bordes izquierdos de todas las columnas, mas el final de la ultima.
  List<double> edges = const [];

  /// Cuantas de esas columnas son campos de la tabla: detras estan las libres,
  /// y ahi no se puede soltar nada.
  int fields = 0;

  /// Si hay una columna en el aire.
  final ValueNotifier<bool> active = ValueNotifier(false);

  /// Borde izquierdo del fantasma.
  final ValueNotifier<double> x = ValueNotifier(0);

  /// Borde donde caeria la columna si se la soltara ahora.
  final ValueNotifier<int> edge = ValueNotifier(-1);

  /// Donde esta el borde [index], para dibujar la linea.
  double edgeAt(int index) =>
    index >= 0 && index < edges.length ? edges[index] : 0;

  /// Donde empieza la columna que se esta arrastrando, para marcarla.
  double get from => edgeAt(source);

  void start({
    required int source,
    required String label,
    required double grab,
    required List<double> edges,
    required int fields
  }) {
    this.source = source;
    this.label = label;
    this.grab = grab;
    this.edges = edges;
    this.fields = fields;
    width = edges[source + 1] - edges[source];

    edge.value = source;
    x.value = edges[source];
    active.value = true;
  }

  /// El puntero esta en [pointer] (en coordenadas del contenido).
  ///
  /// El borde donde caeria se calcula desde el **medio del fantasma** y no desde
  /// el puntero: es el fantasma lo que se ve moverse, asi que es lo que tiene
  /// que decidir cuando salta la linea. Agarrar una columna ancha de una punta y
  /// mirar la del puntero se leeria como que la linea va atrasada.
  void moveTo(double pointer) {
    final left = pointer - grab;
    x.value = left;

    final at = dropEdgeAt(edges, left + width / 2, columns: fields);
    if (at == edge.value) return;

    edge.value = at;
  }

  /// Termina el arrastre y devuelve que columna se solto y en que borde, o
  /// `(-1, -1)` si no habia ninguna en el aire.
  (int, int) stop() {
    if (!active.value) return (-1, -1);

    final moved = (source, edge.value);

    active.value = false;
    source = -1;
    label = "";
    width = 0;
    grab = 0;
    edges = const [];
    fields = 0;

    return moved;
  }

  void dispose() {
    active.dispose();
    x.dispose();
    edge.dispose();
  }
}
