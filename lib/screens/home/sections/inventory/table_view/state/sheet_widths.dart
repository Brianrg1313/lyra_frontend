import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// El ancho de cada columna de la planilla.
///
/// Cada columna tiene **su propio** [ValueNotifier] en vez de haber un mapa con
/// un solo `notifyListeners`, y esa es toda la gracia: arrastrar el borde de una
/// columna dispara pointer events a la velocidad de la pantalla, y con un aviso
/// global cada uno de esos frames volveria a construir todas las celdas
/// visibles. Asi solo se entera la columna que se esta arrastrando; sus celdas
/// cambian de ancho, el `Row` que las contiene vuelve a acomodarse y las
/// columnas hermanas no se reconstruyen, solo se corren.
///
/// Los anchos no son de esta sesion: cada campo trae el suyo en la estructura y
/// se adoptan al abrir la tabla ([adopt]), asi que todos ven las columnas de la
/// misma medida. Lo que se arrastra viaja al backend al soltar, y ahi esta el
/// motivo de [_pinned]: desde que una columna se toco en esta pantalla, el ancho
/// que manda es el de aca. Una relectura de la estructura —agregar una columna,
/// renombrar otra— llega con el ancho que estaba guardado cuando salio la
/// peticion, que puede ser mas viejo que el que se acaba de arrastrar.
class SheetWidths {
  SheetWidths({
    required this.defaultWidth,
    required this.minWidth,
    this.maxWidth = 1200
  });

  /// Ancho de una columna que todavia no se redimensiono.
  final double defaultWidth;

  /// Ancho minimo al que se puede arrastrar una columna, para que no se pueda
  /// colapsar hasta desaparecer.
  final double minWidth;

  /// Ancho maximo al que se puede arrastrar una columna. Es la otra punta de lo
  /// mismo: una columna de miles de pixeles tapa la planilla entera, y ademas el
  /// ancho se guarda, asi que dejarlo sin techo dejaria una tabla que se abre
  /// asi para todos.
  final double maxWidth;

  final Map<String, ValueNotifier<double>> _widths = {};

  /// Columnas cuyo ancho ya decide esta pantalla: las que se arrastraron y las
  /// que ya adoptaron el guardado. Es lo que hace que [adopt] no pise un
  /// arrastre con el ancho que traiga una estructura releida.
  final Set<String> _pinned = {};

  /// Suma de los anchos de todas las columnas. Lo escucha solo el `SizedBox` que
  /// le da ancho a la banda desplazable.
  final ValueNotifier<double> total = ValueNotifier(0);

  /// Las columnas actuales, en orden, por su clave de ancho.
  List<String> _keys = const [];

  /// El ancho de esa columna, como algo a lo que suscribirse.
  ValueNotifier<double> of(String key) =>
    _widths.putIfAbsent(key, () => ValueNotifier(defaultWidth));

  /// El ancho de esa columna, sin suscribirse. Lo usan los calculos de
  /// geometria (traer una celda a la vista), que corren fuera del build.
  double valueOf(String key) => _widths[key]?.value ?? defaultWidth;

  double widthAt(int index) =>
    index >= 0 && index < _keys.length ? valueOf(_keys[index]) : 0;

  /// Cuanto hay a la izquierda de la columna [index].
  double offsetOf(int index) {
    double left = 0;
    for (int i = 0; i < index && i < _keys.length; i++) {
      left += valueOf(_keys[i]);
    }
    return left;
  }

  int get length => _keys.length;

  /// Los bordes izquierdos de todas las columnas, mas el final de la ultima (un
  /// valor mas que columnas hay).
  ///
  /// Es la geometria horizontal entera de la planilla resuelta de una pasada, y
  /// existe para el arrastre de una columna: sin esto, cada evento del puntero
  /// —uno por frame— tendria que sumar los anchos de nuevo para saber sobre que
  /// vecina esta. Se calcula una sola vez al empezar a arrastrar, que es cuando
  /// se sabe que los anchos no se van a mover: no se puede arrastrar un ancho y
  /// una columna a la vez.
  List<double> edges() {
    final edges = List<double>.filled(_keys.length + 1, 0);

    for (int index = 0; index < _keys.length; index++) {
      edges[index + 1] = edges[index] + valueOf(_keys[index]);
    }

    return edges;
  }

  /// Le avisa cuales son las columnas de ahora. Lo llama el controlador cada vez
  /// que la planilla gana o pierde una.
  void setKeys(List<String> keys) {
    _keys = keys;
    _recount();
  }

  /// Arrastra el ancho de una columna.
  void resize(String key, double delta) {
    // Desde que se la arrastra, el ancho de esta columna lo manda la pantalla:
    // el que traiga una estructura releida ya no la toca.
    _pinned.add(key);

    // Ya en un extremo, seguir arrastrando hacia ese lado no cambia nada: sin
    // esta guarda cada frame del arrastre avisaria igual.
    if (!_write(key, valueOf(key) + delta)) return;

    _recount();
  }

  /// Adopta el ancho con el que quedo guardada la columna, la primera vez que se
  /// la ve.
  ///
  /// Es lo que hace que la tabla se abra como la dejo el ultimo que la acomodo,
  /// y **solo la primera vez**: una estructura se relee por cualquier cambio de
  /// columna, y la que llega puede traer un ancho anterior al que se acaba de
  /// arrastrar. Un [width] que no sea un ancho (`0`, negativo) se ignora: esa
  /// columna nunca se redimensiono y le toca el de siempre.
  void adopt(String key, double width) {
    if (width <= 0 || !_pinned.add(key)) return;
    if (!_write(key, width)) return;

    _recount();
  }

  /// Devuelve la columna al ancho que tenia, despues de un arrastre que el
  /// backend no acepto. Es el equivalente de `SheetColumns.restoreOrder` para el
  /// ancho: lo que se ve se aplica al instante y el guardado viaja detras, asi
  /// que si no sale hay que deshacerlo.
  void restore(String key, double width) {
    if (!_write(key, width)) return;
    _recount();
  }

  /// Deja la columna en [width], acotado a lo que se puede medir. Devuelve
  /// `false` si con eso no cambio nada, que es lo que evita avisar de mas.
  bool _write(String key, double width) {
    final notifier = of(key);
    final value = math.min(maxWidth, math.max(minWidth, width));

    if (value == notifier.value) return false;

    notifier.value = value;
    return true;
  }

  void _recount() {
    double sum = 0;
    for (final key in _keys) {
      sum += valueOf(key);
    }
    total.value = sum;
  }

  void dispose() {
    for (final notifier in _widths.values) {
      notifier.dispose();
    }
    _widths.clear();
    _pinned.clear();
    total.dispose();
  }
}
