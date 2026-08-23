import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form/select_input.dart' show SelectOption;
import 'package:core/form/select_menu.dart';
import 'package:core/widgets/tables/linked_scroll.dart';

// SERVICES
import 'package:app/services/files/image_file.dart';
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/sku_generator.dart';
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/modals/image_viewer/_image_viewer.dart';

import 'field_edit.dart';
import 'free_column.dart';
import 'sheet_columns.dart';
import 'sheet_cursor.dart';
import 'sheet_dates.dart';
import 'sheet_drafts.dart';
import 'sheet_drag.dart';
import 'sheet_hover.dart';
import 'sheet_keys.dart';
import 'sheet_metrics.dart';
import 'sheet_widths.dart';

/// Franja de los costados de la planilla en la que, arrastrando una columna, la
/// banda empieza a correrse sola.
const double _kEdgeMargin = 48;

/// Cuanto se corre como mucho en cada frame de ese desplazamiento.
const double _kEdgeStep = 24;

/// A partir de cuantas opciones el desplegable de una celda de lista trae
/// buscador.
///
/// Por debajo de eso la lista se recorre de un vistazo y el buscador seria una
/// fila de mas entre la celda y lo que se quiere tocar; por encima, es lo que
/// convierte elegir en escribir tres letras.
const int _kOptionSearchFrom = 10;

// Las acciones del desplegable de una celda de imagen. Son valores internos —no
// se guardan ni viajan a ningun lado— y estan nombrados para que el `switch` que
// los reparte se lea.
const String _kImageView = "view";
const String _kImageUpload = "upload";
const String _kImageLibrary = "library";
const String _kImageRemove = "remove";

/// El cerebro de la planilla: todo lo que se puede *hacer* sobre ella.
///
/// No es un [Listenable] a proposito. Si lo fuera, cualquier widget que quisiera
/// llamar a una accion tendria que suscribirse a el, y con eso volveriamos al
/// punto de partida: un solo aviso que repinta la pantalla entera. Aca los
/// widgets lo leen (`context.read`) para pedirle cosas, y escuchan a los
/// pedacitos de estado que si notifican y que son chicos a proposito:
/// [cursor], [columns], [drafts] y los anchos de [widths], uno por columna.
///
/// El reparto es: este objeto decide **que pasa**, los notificadores dicen
/// **quien se entera** y los widgets solo dibujan.
class SheetController {
  SheetController({
    required this.service,
    required this.metrics,
    required this.widths,
    required BuildContext Function() context
  }) : _context = context {
    columns = SheetColumns(service);
    _onColumns();

    _vertical = LinkedScrollGroup([vGutter, vBody]);

    columns.addListener(_onColumns);
    drafts.addListener(_onRows);
    service.addListener(_onRows);
    vBody.addListener(_prefetch);

    _onRows();
  }

  /// El estado de la tabla abierta: la estructura y los registros. Lo posee la
  /// pantalla, no este controlador, que solo lo usa.
  final TableViewService service;

  /// La geometria de la planilla. Es inmutable y pura.
  final SheetMetrics metrics;

  /// El ancho de cada columna, con un notificador por columna.
  final SheetWidths widths;

  /// El contexto de la pantalla. Hace falta para lo que sale de la planilla
  /// —pedir confirmacion, mostrar una bandera de error, traducir— y se pide
  /// como funcion porque el controlador vive mas que cualquier `build`.
  final BuildContext Function() _context;

  final SheetCursor cursor = SheetCursor();
  final SheetDrafts drafts = SheetDrafts();

  /// La fila que tiene el mouse encima. No la mira nada de lo que hace la
  /// planilla —no cambia lo que pasa al tocar ni al escribir—: es solo con que
  /// se pinta esa fila.
  final SheetHover hover = SheetHover();

  /// En que formato se esta leyendo cada columna de fechas. Como [hover], no
  /// cambia lo que la planilla hace: es solo con que se escribe esa columna.
  final SheetDates dates = SheetDates();

  /// La columna que se esta arrastrando de lugar, mientras dura. No lo escucha
  /// la grilla: solo el fantasma que se dibuja encima.
  final SheetDrag drag = SheetDrag();

  late final SheetColumns columns;

  // Bandas de la planilla: la de numeros de fila (congelada a la izquierda) y la
  // de datos. Se desplazan juntas en vertical; la horizontal es solo de la banda
  // de datos, para que los numeros de fila no se vayan de pantalla.
  final ScrollController vGutter = ScrollController();
  final ScrollController vBody = ScrollController();
  final ScrollController horizontal = ScrollController();

  // Se guarda la referencia para mantener vivos los listeners que sincronizan
  // las dos bandas verticales.
  // ignore: unused_field
  late final LinkedScrollGroup _vertical;

  /// Foco de la planilla entera. Atiende las teclas de navegacion cuando el
  /// cursor esta en una celda que no se escribe (un campo que lleva el backend,
  /// una fila que todavia no llego), donde no hay editor que las reciba, para
  /// que se pueda seguir recorriendo la grilla.
  final FocusNode grid = FocusNode();

  /// Filas ocupadas: registros + borradores + las que se ganaron bajando con el
  /// teclado. Es lo unico que escucha el cuerpo de la planilla; las filas en
  /// blanco que sobran las pone el `build`, que es el que sabe cuantas entran en
  /// pantalla.
  final ValueNotifier<int> usedRows = ValueNotifier(0);

  /// La celda cuya foto se esta subiendo, mientras dura, o `null` si no hay
  /// ninguna.
  ///
  /// Es una sola —no se pueden empezar dos subidas sin cerrar el desplegable de
  /// la primera— y por eso es un valor y no una lista. Lo escucha cada celda de
  /// imagen, que es lo unico que hay que repintar: la fila no cambia de tamano
  /// ni de contenido mientras la foto viaja, solo ese cuadradito muestra su
  /// cargando (ver [ImageCell]).
  final ValueNotifier<SheetCell?> uploading = ValueNotifier(null);

  // Editor de la celda activa. Se crea uno nuevo por celda (no se reusa el
  // mismo [FocusNode] entre dos posiciones del arbol) y el anterior se libera
  // despues del frame, cuando su [TextField] ya se desmonto.
  TextEditingController? editor;
  FocusNode? focus;

  /// Lo que tenia la celda al abrirse. Es a lo que vuelve con Escape, porque
  /// cada tecla ya se volco al borrador (o al titulo de la columna) y sin esto
  /// no habria nada que deshacer.
  String _initial = "";

  /// Escrituras de columna encoladas (altas, renombres y bajas). Cada una
  /// recarga la tabla y el servicio ignora una recarga mientras hay otra en
  /// curso, asi que dos cambios seguidos se mandan uno detras del otro y no a
  /// la vez.
  Future<void> _columnQueue = Future.value();

  /// Altas de fila encoladas. Es la misma razon que la cola de las columnas:
  /// cada alta relee la tabla y el servicio ignora un alta mientras hay otra en
  /// curso, asi que dos filas escritas una detras de la otra —que es lo normal
  /// cargando— se mandan en fila y no a la vez.
  Future<void> _rowQueue = Future.value();

  /// La fila que ya quedo guardada pero que sigue dibujada, y cuantos registros
  /// tenia la tabla cuando se la mando.
  ///
  /// Las dos mitades de la planilla se separan por la cantidad de registros
  /// ([draftIndex]), asi que el borrador no se puede sacar antes de que la
  /// tabla cuente el registro nuevo: entre una cosa y la otra las filas de
  /// abajo se correrian de lugar, y ese es justo el rato que se pasa
  /// escribiendo la fila siguiente. Ver [_dropPersisted].
  SheetDraft? _persisted;
  int _persistedAt = 0;

  /// Filas en blanco extra que se ganaron bajando con el teclado mas alla del
  /// final de la planilla.
  int _extraRows = 0;

  /// Donde cae, en la pantalla, el borde izquierdo de la primera columna. Es lo
  /// unico que hace falta para llevar el puntero a las coordenadas del contenido
  /// (`contenido = pantalla - origen`), que son en las que estan los bordes de
  /// las columnas y en las que se dibuja el fantasma. Se resuelve una vez al
  /// empezar a arrastrar y se corrige cuando la banda se desplaza sola.
  double _dragOrigin = 0;

  /// Ultima posicion del puntero en la pantalla. La necesita el desplazamiento
  /// automatico: mientras la banda se corre bajo un puntero quieto, la columna
  /// igual cambia de vecinas.
  double _dragPointer = 0;

  /// Corre la planilla mientras se arrastra una columna contra un borde.
  Timer? _dragScroll;

  /// La columna cuyo ancho se esta arrastrando, y el ancho que tenia al empezar:
  /// es lo que se compara al soltar para saber si hay algo que guardar, y a lo
  /// que vuelve si el guardado no sale.
  int _resizing = -1;
  double _resizedFrom = 0;

  /// Cuantas filas tiene el cuerpo ahora mismo. Lo deja el `build`, que es quien
  /// sabe cuantas entran en pantalla, y lo leen el teclado y la lectura por
  /// tramos.
  int _rows = 0;

  bool _disposed = false;
  bool _prefetchScheduled = false;

  int get rows => _rows;

  /// Le avisa cuantas filas quedaron dibujadas. Se llama desde el `build`, por
  /// eso es una asignacion pelada: no notifica a nadie.
  void setRows(int rows) => _rows = rows;

  // ---- Cursor y edicion ----------------------------------------------------

  /// Toque en una celda: si se puede escribir abre el editor; si no (un campo
  /// que lleva el backend, una fila que todavia no llego, una columna que se
  /// esta creando) solo la selecciona, como una planilla en la que se puede
  /// recorrer todo aunque no todo se escriba.
  ///
  /// Los campos que se **eligen** en vez de escribirse (una lista) abren su
  /// desplegable en lugar del editor, anclado a la celda: para eso hace falta
  /// [anchor], que es el contexto de la celda tocada. Sin el —un toque que no lo
  /// pasa— la celda queda elegida y nada mas, que es lo mismo que hace el
  /// teclado.
  void tap(int row, int column, {BuildContext? anchor}) {
    final cell = SheetCell(row, column);

    if (!canEdit(row, column)) {
      select(cell);
      return;
    }

    // La fila de los campos siempre se escribe: ahi lo que hay es el titulo de
    // la columna, no un dato de su tipo.
    if (row != kFieldsRow && isPicker(column)) {
      if (typeAt(column) == TableFieldType.image) {
        pickImage(cell, anchor);
      } else {
        pickOption(cell, anchor);
      }
      return;
    }

    open(cell);
  }

  /// Si esa columna se toca en vez de escribirse: una lista o una imagen, cuyas
  /// celdas despliegan algo y no abren editor de texto.
  bool isPicker(int column) => typeAt(column).picker;

  /// El tipo de esa columna. Una columna libre —que todavia no es un campo— no
  /// tiene tipo y cae en texto, como cualquier codigo desconocido.
  TableFieldType typeAt(int column) =>
    TableFieldType.from(columns.typeOf(column));

  /// Deja la celda seleccionada pero sin editor (una celda que no se escribe).
  /// El foco pasa a la planilla para que las teclas de navegacion sigan
  /// llegando, ya que no hay editor que las reciba.
  void select(SheetCell cell) {
    close();
    _leaveRow(cell.row);
    cursor.move(cell);

    grid.requestFocus();
    reveal(cell);
  }

  /// Abre el editor en [cell] con lo que esa celda ya tuviera escrito.
  ///
  /// Se crea un [TextEditingController] y un [FocusNode] nuevos por celda en vez
  /// de reusar los mismos: el [TextField] cambia de lugar en el arbol y un
  /// [FocusNode] no se puede compartir entre dos posiciones. Los anteriores se
  /// liberan despues del frame, cuando su widget ya se desmonto.
  void open(SheetCell cell) {
    // Tocar la celda que ya se esta editando (un doble click, por ejemplo)
    // no debe recrear el editor: `cursor.move` no avisa si la celda y el
    // estado no cambian, asi que cerrar y reabrir dejaria el `TextField`
    // montado usando un `FocusNode` que este metodo ya mando a disponer.
    if (cursor.editing && cursor.cell == cell) return;

    close();
    _leaveRow(cell.row);

    final text = valueOf(cell);
    _initial = text;

    final node = FocusNode(onKeyEvent: handleKey);
    node.addListener(() => _onFocus(node));

    editor = TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: text.length);
    focus = node;

    cursor.move(cell, editing: true);
    reveal(cell);
  }

  /// Cierra el editor guardando en el borrador lo que se haya escrito. No toca
  /// el cursor: la celda sigue seleccionada.
  ///
  /// **Salir de la celda es lo que manda el cambio**, y por eso nada de esto va
  /// en [commit], que corre en cada tecla: se escribe entera y recien al salir
  /// viaja. En la fila de los campos eso es el alta de una columna libre con
  /// titulo, el renombre de un campo o su baja si quedo sin titulo
  /// ([finishField]); en una fila ya guardada, la correccion de esa celda
  /// ([finishRecord]).
  ///
  /// Las filas en blanco de abajo son las unicas que no mandan nada al salir de
  /// la **celda**: se juntan como borrador y se guardan enteras al salir de la
  /// **fila** ([_leaveRow]), porque hasta que no se guardan no son un registro
  /// al que escribirle una celda suelta.
  void close({bool commit = true}) {
    final cell = cursor.cell;
    final editing = cursor.editing;

    if (commit) {
      _normalizeDate(cell);
      this.commit();
    }

    final closing = editor;
    final closingFocus = focus;
    editor = null;
    focus = null;
    cursor.stopEditing();

    if (commit && editing && cell != null) {
      if (cell.row == kFieldsRow) {
        finishField(cell.column, closing?.text ?? "");
      } else if (cell.row < service.records) {
        finishRecord(cell, closing?.text ?? "");
      }
    }

    if (closing == null && closingFocus == null) return;

    // El [TextField] todavia esta montado en este frame: liberar su controlador
    // y su foco ahora lo dejaria usando objetos muertos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      closing?.dispose();
      closingFocus?.dispose();
    });
  }

  /// Deja escrita la fecha de la celda como la guarda la tabla.
  ///
  /// Es lo que permite escribirla como a uno le salga —`12 2 26`, `12/02/2026`,
  /// `2026.02.12`— y que en la tabla quede una sola forma (ver
  /// [ProductDate.normalize]). Corre al salir de la celda y no en [commit], que
  /// se ejecuta en cada tecla: normalizar mientras se tipea le reescribiria a
  /// uno lo que esta escribiendo a mitad de camino.
  ///
  /// Lo que no es una fecha se queda tal cual. La celda tampoco lo tira: se
  /// sigue viendo lo que alguien puso (ver [DateCell]).
  void _normalizeDate(SheetCell? cell) {
    final editor = this.editor;

    if (cell == null || editor == null || cell.row == kFieldsRow) return;
    if (!typeAt(cell.column).isDate) return;

    final text = ProductDate.normalize(editor.text);
    if (text != editor.text) editor.text = text;
  }

  /// Cada tecla se vuelca al borrador (o al titulo de la columna), no recien al
  /// salir de la celda: asi la fila ofrece guardarse —el tilde de su numero, el
  /// boton de la barra— desde la primera letra, y escribir el titulo de la
  /// ultima columna libre hace aparecer la siguiente mientras se tipea.
  ///
  /// Quien decide si eso repinta algo es cada notificador, y ninguno avisa por
  /// una letra que no cambia nada en pantalla.
  void onChanged(String text) => commit();

  /// Vuelca el texto del editor donde corresponda.
  void commit() {
    final cell = cursor.cell;
    final text = editor?.text;
    if (!cursor.editing || cell == null || text == null) return;

    // El titulo de una columna libre vive en las columnas libres hasta que el
    // campo se crea.
    if (cell.row == kFieldsRow) {
      columns.writeFree(cell.column, text);
      return;
    }

    final index = draftIndex(cell.row);
    if (index < 0) return;

    // Se guarda por el lugar del campo en la estructura y no por donde se lo ve,
    // que es lo mismo que hacen los registros leidos: asi arrastrar una columna
    // de lugar se lleva con ella lo que se estaba escribiendo, sin tocar ni un
    // borrador.
    drafts.write(index, columns.slotAt(cell.column), text);
  }

  /// Deshace lo escrito en la celda y cierra el editor: la celda vuelve a lo que
  /// tenia al abrirse. Una columna libre que se estaba titulando no se crea, y
  /// si le queda el titulo de antes es porque ya lo tenia.
  void cancel() {
    final editor = this.editor;

    if (editor != null) {
      editor.text = _initial;
      commit();
    }

    close(commit: false);
  }

  /// Deja la planilla como recien abierta: sin cursor, sin las filas de mas que
  /// se hubieran ganado bajando con el teclado y arriba de todo.
  ///
  /// Lo llama la pantalla al cambiar la busqueda, que es cuando las filas pasan a
  /// ser otras: dejar el cursor donde estaba lo dejaria sobre la fila que ahora
  /// ocupa ese lugar —que no es la que se estaba mirando— y dejar el
  /// desplazamiento, en medio de un resultado mas corto que lo que se habia
  /// bajado.
  ///
  /// No cierra ningun editor: para escribir en el buscador hubo que salir de la
  /// planilla, y eso ya lo cerro y dejo la fila guardada ([_onFocus]).
  void reset() {
    cursor.clear();

    _extraRows = 0;
    _onRows();

    if (vBody.hasClients) vBody.jumpTo(0);
  }

  /// Perder el foco (tocar fuera de la planilla, abrir un modal) confirma lo
  /// escrito y cierra el editor, como al salir de una celda. Y como ahi no se
  /// va a otra fila sino a ninguna, la fila que se estaba escribiendo tambien se
  /// deja: si tenia algo cargado, se guarda.
  void _onFocus(FocusNode node) {
    // Salir de la pantalla con una celda abierta libera su [FocusNode], y eso
    // tambien avisa que perdio el foco: sin esta guarda se tocaria una pantalla
    // que ya no esta.
    if (_disposed) return;
    if (!identical(node, focus) || node.hasFocus) return;

    close();
    _leaveRow(null);
  }

  /// Teclas de la planilla. Las atiende el [FocusNode] del editor, que las ve
  /// antes que el propio [TextField] (asi Tab no cambia de widget y Enter no
  /// dispara el submit) y, cuando no hay editor abierto, el foco de la grilla,
  /// que es su ancestro y recibe lo que el editor deja pasar.
  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Sin celda elegida no hay nada que mover: las teclas siguen su camino (el
    // Tab vuelve a recorrer la pantalla, el Escape cierra lo que haya abierto).
    final cell = cursor.cell;
    if (cell == null) return KeyEventResult.ignored;

    final intent = SheetKeyIntent.of(
      event.logicalKey,
      shift: HardwareKeyboard.instance.isShiftPressed,
      editing: cursor.editing
    );

    if (intent == null) return KeyEventResult.ignored;

    if (intent == SheetKeyIntent.cancel) {
      cancel();
      return KeyEventResult.handled;
    }

    final move = intent.move!;
    _move(cell, rows: move.rows, columns: move.columns, wrap: move.wrap);

    return KeyEventResult.handled;
  }

  /// Mueve el cursor, arrastrando el editor. Pasarse de la ultima fila agrega
  /// otra en blanco: la planilla no se termina.
  ///
  /// Salvo buscando, que es lo unico que si se termina: lo que se ve son las
  /// filas que coinciden y debajo no hay donde escribir (ver [_onRows]), asi que
  /// bajar de la ultima se queda en la ultima.
  void _move(
    SheetCell from, {
    required int rows,
    required int columns,
    required bool wrap
  }) {
    final last = this.columns.length - 1;
    if (last < 0) return;

    final target = sheetDestination(
      from: from,
      rows: rows,
      columns: columns,
      wrap: wrap,
      lastColumn: last
    );

    if (service.isSearching && target.row >= _rows) return;

    if (target.row >= _rows) {
      _extraRows += target.row - _rows + 1;
      _rows = target.row + 1;
      _onRows();
    }

    // Lo que no se escribe (un campo que lleva el backend, una fila que todavia
    // no llego) se selecciona igual, y desde ahi se sigue navegando. Una lista
    // tampoco abre editor: se recorre con las flechas como cualquier celda y se
    // despliega tocandola, que es de donde sale el ancla del desplegable.
    if (!canEdit(target.row, target.column) ||
        (target.row != kFieldsRow && isPicker(target.column))) {
      select(target);
      return;
    }

    open(target);
  }

  /// Trae a la vista la celda [cell]. Se hace despues del frame porque la fila
  /// puede ser una que recien se agrego y todavia no tiene extent.
  void reveal(SheetCell cell) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;

      if (vBody.hasClients) {
        final to = metrics.revealRow(
          row: cell.row,
          offset: vBody.offset,
          viewport: vBody.position.viewportDimension,
          maxExtent: vBody.position.maxScrollExtent
        );

        if (to != null) vBody.jumpTo(to);
      }

      if (horizontal.hasClients && cell.column < columns.length) {
        final to = metrics.revealColumn(
          left: widths.offsetOf(cell.column),
          width: widths.widthAt(cell.column),
          offset: horizontal.offset,
          viewport: horizontal.position.viewportDimension,
          maxExtent: horizontal.position.maxScrollExtent
        );

        if (to != null) horizontal.jumpTo(to);
      }
    });
  }

  /// Si la celda se puede escribir.
  ///
  /// En la fila de los campos lo decide [SheetColumns.canEditAt]. En el cuerpo
  /// se escriben las dos mitades de la planilla —los registros y las filas en
  /// blanco de abajo—, siempre que la columna ya sea un campo con un tipo que se
  /// carga a mano.
  ///
  /// Lo unico que distingue a un registro es que tiene que **haber llegado**:
  /// una fila cuyo tramo todavia no entro existe y ocupa su lugar, pero no se
  /// sabe ni que tiene cargado ni cual es, asi que se la puede recorrer y
  /// todavia no escribir.
  bool canEdit(int row, int column) {
    final sheet = columns.at(column);
    if (sheet == null) return false;

    if (row == kFieldsRow) return columns.canEditAt(column);

    // Una columna libre no tiene donde guardar hasta que se cree, y lo que lleva
    // el backend (contador, stock) no se escribe a mano.
    if (!sheet.isField || !TableFieldType.from(sheet.type).editable) {
      return false;
    }

    // Sin el id del registro no hay a que fila de la tabla mandarle el cambio.
    if (row < service.records) return service.rowAt(row)?.id.isNotEmpty ?? false;

    // Una fila que se esta guardando esta por dejar de ser un borrador: lo que
    // se le escriba encima se perderia al llegar el registro. Se la puede
    // recorrer, como cualquier fila que todavia no se escribe.
    return !(drafts.at(draftIndex(row))?.saving ?? false);
  }

  /// Lo que la celda ya tiene escrito: el titulo del campo o de la columna
  /// libre, si es la fila de los campos; el valor guardado, si es un registro; o
  /// lo que se haya cargado en la fila-borrador.
  String valueOf(SheetCell cell) {
    if (cell.row == kFieldsRow) return columns.nameOf(cell.column);

    final slot = columns.slotAt(cell.column);
    final index = draftIndex(cell.row);

    // Un registro se abre con lo que tiene cargado: editarlo es corregir ese
    // valor, no escribir sobre una celda en blanco.
    if (index < 0) return service.rowAt(cell.row)?.at(slot)?.toString() ?? "";

    return drafts.textAt(index, slot);
  }

  /// Indice del borrador que le toca a esa fila del cuerpo, o negativo si esa
  /// fila es un registro de la tabla.
  ///
  /// Las filas que se escriben empiezan detras del ultimo registro, y cuantos
  /// hay lo dice la estructura desde el principio: por eso una fila en blanco no
  /// se corre de lugar cuando entra un tramo nuevo de registros, aunque se lo
  /// este leyendo mientras se escribe en ella.
  int draftIndex(int row) => row - service.records;

  // ---- Ancho de las columnas -----------------------------------------------

  /// Empieza a arrastrar el ancho de una columna: se anota el que tenia, que es
  /// a lo que vuelve si el guardado no sale.
  void startResize(int index) {
    _resizing = index;
    _resizedFrom = widths.valueOf(columns.keyOf(index));
  }

  /// Arrastra el ancho de una columna. Solo se entera esa columna.
  void resize(int index, double delta) =>
    widths.resize(columns.keyOf(index), delta);

  /// Suelta el borde: el ancho con el que quedo la columna se guarda.
  ///
  /// Se manda **al soltar** y no en cada evento del arrastre, que son decenas
  /// por segundo. Si no cambio nada —un toque en el borde, o una columna que ya
  /// estaba en el minimo— no viaja nada, y tampoco viaja el de una columna libre
  /// del final: todavia no es un campo, no hay donde guardarle el ancho (lo
  /// tendra recien cuando se la cree y se la vuelva a arrastrar).
  void endResize(int index) {
    final from = _resizedFrom;
    final resizing = _resizing;

    _resizing = -1;
    if (resizing != index) return;

    final field = columns.fieldAt(index);
    if (field == null || field.id.isEmpty) return;

    final width = widths.valueOf(field.id);
    if (width == from) return;

    _columnQueue = _columnQueue.then((_) => _sendWidth(field, width, from));
  }

  /// Manda el ancho nuevo. Va por la misma cola que las altas, los renombres y
  /// las bajas: cada uno de esos relee la estructura, y mandar el ancho mientras
  /// una relectura esta en el aire lo escribiria contra un nombre viejo (la
  /// edicion de un campo manda tambien su nombre, que el backend pide siempre).
  ///
  /// Si no sale, la columna vuelve al ancho que tenia. El error ya lo mostro el
  /// servicio.
  Future<void> _sendWidth(
    TableFieldModel field,
    double width,
    double before
  ) async {
    if (_disposed) return;

    final saved = await service.resizeField(_context(), field, width: width);
    if (_disposed || saved) return;

    widths.restore(field.id, before);
  }

  // ---- Arrastre de columnas ------------------------------------------------

  /// Empieza a arrastrar de lugar la columna [index], agarrandola de su celda de
  /// campo.
  ///
  /// Solo se arrastran los campos de la tabla, y solo mientras no tengan un
  /// cambio en camino: una columna libre del final no tiene posicion que
  /// guardar, y una que se esta creando o eliminando todavia no se sabe donde
  /// va a quedar.
  ///
  /// Lo que se estuviera escribiendo se cierra antes: la celda esta por cambiar
  /// de lugar y el editor no puede seguirla.
  void startColumnDrag(int index, DragStartDetails details) {
    close();

    final column = columns.at(index);
    if (column == null || !column.isField || columns.busyAt(index)) return;

    // La geometria de la planilla se resuelve **una vez**: de aca en mas, cada
    // evento del puntero es una resta y una busqueda sobre esta lista.
    final edges = widths.edges();
    if (index + 1 >= edges.length) return;

    drag.start(
      source: index,
      label: columns.nameOf(index),
      grab: details.localPosition.dx,
      edges: edges,
      fields: columns.fieldCount
    );

    // Donde esta el 0 del contenido: el puntero cayo en `edges[index]` mas lo
    // que se corrio dentro de la celda.
    _dragOrigin =
      details.globalPosition.dx - edges[index] - details.localPosition.dx;
    _dragPointer = details.globalPosition.dx;
  }

  void updateColumnDrag(DragUpdateDetails details) {
    if (!drag.active.value) return;

    _dragPointer = details.globalPosition.dx;
    drag.moveTo(_dragPointer - _dragOrigin);

    _edgeScroll();
  }

  /// Suelta la columna donde quedo la linea.
  ///
  /// El orden nuevo se aplica **ya**, sin esperar al backend: la planilla se
  /// reordena sola (que no cuesta mas que rehacer la grilla, porque los
  /// registros no se mueven de donde estan) y las posiciones viajan detras.
  void endColumnDrag() {
    _stopEdgeScroll();

    final (from, to) = drag.stop();
    if (from < 0) return;

    final before = columns.reorder(from, to);
    if (before == null) return;

    // La columna se fue a otro lugar y con ella el sentido de la celda elegida:
    // el cursor apunta a una posicion que ahora es otra columna.
    cursor.clear();

    _columnQueue = _columnQueue.then((_) => _sendOrder(before));
  }

  /// El arrastre se corto sin soltar (se perdio el puntero, se abrio algo
  /// encima): la columna se queda donde estaba.
  void cancelColumnDrag() {
    _stopEdgeScroll();
    drag.stop();
  }

  /// Manda el orden nuevo. Va por la misma cola que las altas, los renombres y
  /// las bajas: cada uno de esos relee la estructura, y mandar las posiciones
  /// mientras una relectura esta en el aire las escribiria contra nombres
  /// viejos.
  ///
  /// Si no sale, la planilla vuelve al orden que tenia. El error ya lo mostro el
  /// servicio.
  Future<void> _sendOrder(List<String> before) async {
    if (_disposed) return;

    final saved = await service.reorderFields(_context(), columns.ordered);
    if (_disposed || saved) return;

    columns.restoreOrder(before);
  }

  /// Corre la planilla cuando la columna arrastrada llega a un borde, para poder
  /// llevarla mas alla de lo que se ve.
  ///
  /// El puntero puede quedarse quieto contra el borde, asi que el
  /// desplazamiento no lo puede disparar el evento: se prende un tic mientras
  /// haga falta y se apaga en cuanto la columna vuelve al medio.
  void _edgeScroll() {
    if (_edgeOvershoot() == 0) {
      _stopEdgeScroll();
      return;
    }

    _dragScroll ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _edgeStep()
    );
  }

  /// Cuanto se metio el puntero en el margen de un costado, con signo: negativo
  /// contra el izquierdo, positivo contra el derecho, `0` en el medio.
  ///
  /// Es lo que decide si hay que correr la planilla y a que velocidad: rozar el
  /// borde la corre despacio y apoyarse contra el va rapido, como en cualquier
  /// planilla.
  double _edgeOvershoot() {
    if (!horizontal.hasClients) return 0;

    final left = _dragOrigin + horizontal.offset;
    final right = left + horizontal.position.viewportDimension;

    if (_dragPointer < left + _kEdgeMargin) {
      return _dragPointer - left - _kEdgeMargin;
    }

    if (_dragPointer > right - _kEdgeMargin) {
      return _dragPointer - right + _kEdgeMargin;
    }

    return 0;
  }

  /// Un tic: corre la planilla lo que toque y se apaga cuando ya no hay para
  /// donde ir (la columna volvio al medio, o la banda llego hasta el final).
  void _edgeStep() {
    final step = _disposed || !drag.active.value ? 0.0 : _edgeOvershoot();

    if (step == 0) {
      _stopEdgeScroll();
      return;
    }

    final to = (horizontal.offset + step.clamp(-_kEdgeStep, _kEdgeStep))
      .clamp(0.0, horizontal.position.maxScrollExtent);

    final moved = to - horizontal.offset;
    if (moved == 0) {
      _stopEdgeScroll();
      return;
    }

    horizontal.jumpTo(to);

    // El contenido se corrio bajo un puntero que no se movio: el mismo lugar de
    // la pantalla es ahora otro lugar del contenido, asi que el fantasma tiene
    // que seguir a la planilla y no al puntero.
    _dragOrigin -= moved;
    drag.moveTo(_dragPointer - _dragOrigin);
  }

  void _stopEdgeScroll() {
    _dragScroll?.cancel();
    _dragScroll = null;
  }

  // ---- Acciones ------------------------------------------------------------

  /// Se va el cursor de la fila en la que estaba, hacia [to] (o hacia ninguna,
  /// si lo que se perdio es el foco). Si la que deja es una de las filas en
  /// blanco de abajo y quedo con algo escrito, esa fila se guarda sola.
  ///
  /// **Salir de la fila es lo que crea el registro**, igual que salir de la
  /// celda es lo que manda la correccion de un registro ([close]) o el alta de
  /// una columna ([finishField]). No hay nada que confirmar: se escribe y se
  /// sigue.
  ///
  /// Es la fila y no la celda porque la fila se escribe de a varias columnas:
  /// recorrerla con Tab no manda nada y al dejarla viaja entera, que es **un**
  /// alta y no una por columna. Guardar celda por celda ademas convertiria la
  /// fila en un registro en medio de la carga, y a partir de ahi cada Tab seria
  /// una correccion sobre una fila recien creada.
  void _leaveRow(int? to) {
    final from = cursor.cell?.row;
    if (from == null || from == to || from == kFieldsRow) return;

    _queueDraft(drafts.at(draftIndex(from)));
  }

  /// Pone una fila-borrador en la cola de altas, si tiene algo que guardar y no
  /// se esta guardando ya.
  ///
  /// La cola es una sola para toda la planilla: dos altas en vuelo al mismo
  /// tiempo se pisarian la relectura con la que cada una se despide de su
  /// borrador (ver [_saveDraft]).
  void _queueDraft(SheetDraft? draft) {
    if (draft == null || !draft.hasData || draft.saving) return;

    _rowQueue = _rowQueue.then((_) => _saveDraft(draft)).catchError(
      // Lo que el servicio relanza (una sesion vencida) sigue su camino de
      // siempre —el manejador del zone, como cualquier escritura que no se
      // espera— pero no puede quedar en la cola: un solo error asi dejaria sin
      // guardar todas las filas que se escriban despues.
      (Object error, StackTrace stack) =>
        Zone.current.handleUncaughtError(error, stack)
    );
  }

  /// Manda una fila-borrador como item nuevo (`POST /products/manage/`).
  ///
  /// Arma el `DATA` del alta indexado por FIELD_ID, salteando las celdas vacias
  /// y las columnas sin id. Una fila escrita **solo** en columnas libres no
  /// tiene todavia donde guardarse: se queda como esta, sin avisar nada, y sale
  /// sola la proxima vez que se la deje, cuando esas columnas ya sean campos.
  ///
  /// Si no sale, el borrador queda intacto y la fila sigue siendo una fila en
  /// blanco escrita: se reintenta con solo volver a salir de ella. El error ya
  /// lo mostro el servicio.
  Future<void> _saveDraft(SheetDraft draft) async {
    if (_disposed || draft.saving) return;

    final fields = service.fields;
    final values = <String, dynamic>{};

    draft.values.forEach((index, text) {
      if (index < 0 || index >= fields.length) return;

      final field = fields[index];
      final value = text.trim();
      if (value.isEmpty || field.id.isEmpty) return;

      values[field.id] = value;
    });

    if (values.isEmpty) return;

    drafts.setSaving(draft, true);

    // El alta va sin relectura y la relectura se pide aca abajo, con la fila ya
    // anotada como persistida: asi el borrador se puede sacar en el mismo
    // instante en que la tabla empieza a contar el registro nuevo.
    final saved = await service.add(_context(), values, refresh: false);
    if (_disposed) return;

    if (!saved) {
      drafts.setSaving(draft, false);
      return;
    }

    // La fila ya es un registro del backend, pero la planilla todavia cuenta los
    // de antes: se la deja donde esta —y en spinner, para que no se la escriba
    // encima— hasta que la relectura traiga el registro nuevo.
    _persisted = draft;
    _persistedAt = service.records;

    await service.refresh();
    if (_disposed) return;

    // Si la cuenta no se movio (la relectura no llego, o la tabla no dice
    // cuantos registros tiene) nadie la va a sacar de [_onRows]: se la saca
    // aca, que si no queda repetida sobre el registro que acaba de aparecer.
    _dropPersisted(force: true);
  }

  /// Saca de la planilla la fila que ya quedo persistida, ahora que la tabla la
  /// cuenta como registro.
  ///
  /// Las dos cosas —que suba la cuenta de registros y que se vaya el borrador—
  /// tienen que pasar **juntas**: las filas de abajo se ubican restando la una
  /// del otro ([draftIndex]), asi que si una se adelanta, por un rato cada fila
  /// en blanco muestra el borrador de la de al lado. Ese rato es el que dura
  /// una relectura entera, o sea justo el que se pasa escribiendo la fila
  /// siguiente.
  ///
  /// Por eso esto cuelga de [_onRows], que corre **dentro** del aviso del
  /// servicio y antes de que se rehaga una sola celda: cuando la planilla mira,
  /// las dos cosas ya pasaron.
  void _dropPersisted({bool force = false}) {
    final draft = _persisted;
    if (draft == null) return;
    if (!force && service.records <= _persistedAt) return;

    _persisted = null;
    drafts.remove(draft);
  }

  /// Manda la correccion de una celda de un registro que se acaba de dejar.
  ///
  /// Se compara con lo que la celda tenia al abrirse: recorrer una fila con Tab
  /// sin tocar nada no manda nada, que es lo que permite navegar una tabla
  /// entera sin escribirle encima. Ese "antes" es [_initial] —lo que el editor
  /// encontro al abrirse— salvo que se pase otro en [before], que es lo que hace
  /// la celda que no tiene editor: una lista se elige de un desplegable, asi que
  /// lo que tenia se lee en el momento de elegir.
  ///
  /// No se encola ni se espera: cada celda es una escritura independiente
  /// —campos distintos de filas distintas— y ninguna vuelve a leer la tabla, asi
  /// que no hay nada que se pisen entre ellas. El cambio ya se ve en la
  /// planilla; si no sale, el servicio devuelve la celda a lo que tenia y avisa.
  void finishRecord(SheetCell cell, String text, {String? before}) {
    if (text == (before ?? _initial)) return;

    // Detras de los campos estan las columnas libres: ahi no hay donde guardar.
    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    unawaited(service.editRecord(
      _context(),
      row: cell.row,
      slot: columns.slotAt(cell.column),
      fieldId: field.id,
      value: text.trim()
    ));
  }

  /// Lleva a cabo lo que decide [FieldEdit] para la celda de campo que se acaba
  /// de dejar: crear la columna, renombrar el campo o eliminarlo.
  void finishField(int column, String text) {
    if (column < 0) return;

    // Detras de los campos estan las columnas libres: ahi todavia no hay campo.
    final field = columns.fieldAt(column);

    switch (FieldEdit.of(
      isField: field != null,
      current: field?.name ?? "",
      text: text
    )) {
      case FieldEdit.none:
        return;
      case FieldEdit.create:
        _createColumn(column);
      case FieldEdit.rename:
        _renameColumn(field!, text.trim());
      case FieldEdit.delete:
        _confirmDelete(field!);
    }
  }

  /// Manda el titulo nuevo de un campo. Va por la misma cola que las altas:
  /// cada cambio recarga la tabla, asi que dos seguidos se mandan uno detras
  /// del otro.
  ///
  /// Hasta que vuelva, la celda muestra el titulo nuevo apagado: es lo que el
  /// usuario acaba de escribir, y volver por un instante al viejo se leeria como
  /// que el cambio se perdio. Si falla, la estructura que llega trae el de antes
  /// y la celda vuelve sola a el; el error ya lo mostro el servicio.
  void _renameColumn(TableFieldModel field, String name) {
    columns.startRename(field.id, name);

    _columnQueue = _columnQueue.then((_) async {
      if (_disposed) return;

      await service.editField(_context(), field, name: name);
      if (_disposed) return;

      columns.endRename(field.id);
    });
  }

  /// Pregunta antes de eliminar el campo al que se le vacio el titulo y, si se
  /// confirma, lo manda.
  ///
  /// Es lo unico de la planilla que se pregunta: agregar una columna o
  /// renombrarla se deshace escribiendo de nuevo, pero la baja se lleva la
  /// columna **y todo lo cargado en ella**, y eso no vuelve. Cancelar no toca
  /// nada: la celda sigue mostrando el campo tal como estaba, porque el titulo
  /// vaciado nunca salio del editor.
  Future<void> _confirmDelete(TableFieldModel field) async {
    final context = _context();

    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).table_field_delete_title,
      message: S.of(context).table_field_delete_message(field.name),
      confirmText: S.of(context).table_field_delete_confirm,
      cancelText: S.of(context).cancel
    );

    if (_disposed || !confirmed) return;

    columns.startDelete(field.id);

    _columnQueue = _columnQueue.then((_) async {
      if (_disposed) return;

      final deleted = await service.deleteField(_context(), field);
      if (_disposed) return;

      columns.endDelete(field.id);

      // La columna ya no esta: el cursor apuntaba a un lugar que ahora es otra
      // columna.
      if (deleted) cursor.clear();
    });
  }

  /// Crea el campo de la columna libre que quedo con titulo. Es lo unico que
  /// hace falta para agregar una columna: escribir su titulo y salir de la
  /// celda, sin formularios de por medio.
  ///
  /// El tipo es `TEXT`, el que sirve para todo: la planilla no pregunta y el
  /// backend siempre puede leer lo que se cargue ahi.
  void _createColumn(int column) {
    final free = columns.freeAt(column);
    if (free == null || free.creating || free.name.isEmpty) return;

    columns.startCreate(free);
    _columnQueue = _columnQueue.then((_) => _sendColumn(free));
  }

  /// Manda el alta del campo. Al volver bien, la columna deja de ser libre: la
  /// recarga del servicio ya la trae como campo de la tabla, en el mismo lugar
  /// donde se la escribio.
  ///
  /// No se avisa nada al terminar: el alta se confirma sola al aparecer la
  /// columna, como en una planilla. Si fallo, la columna sigue siendo libre y
  /// con su titulo puesto, y se reintenta volviendo a salir de la celda.
  Future<void> _sendColumn(FreeColumn free) async {
    if (_disposed) return;

    final created = await service.addField(
      _context(),
      name: free.name,
      description: "",
      type: TableFieldType.text.value
    );
    if (_disposed) return;

    columns.endCreate(free, created: created);
  }

  /// Abre el desplegable de tipos de una columna, anclado a la flecha de su
  /// celda de campo ([anchor] es el contexto de la flecha, que es lo que da su
  /// posicion en pantalla).
  ///
  /// Es el desplegable de siempre ([showSelectMenu]): no se estira mas alla de
  /// unas pocas opciones —los tipos son muchos y llenaban la pantalla— y trae
  /// buscador, que con esta lista es lo que hace que elegir sea escribir tres
  /// letras en vez de recorrerla entera.
  ///
  /// Elegir un tipo lo manda; elegir el que ya tenia, o cerrar el desplegable
  /// sin elegir, no hace nada. El error, si lo hay, ya lo mostro el servicio.
  Future<void> pickType(BuildContext anchor, TableFieldModel field) async {
    final current = TableFieldType.from(field.type);

    final picked = await showSelectMenu(
      context: anchor,
      options: TableFieldType.options(anchor),
      selected: current.value,
      searchPlaceholder: S.of(anchor).table_field_type_placeholder,
      emptyText: S.of(anchor).table_field_type_empty,
      maxOptions: 4
    );

    if (_disposed || picked == null || picked.value == current.value) return;

    await service.editField(_context(), field, type: picked.value);
  }

  /// Abre el desplegable de una celda de lista, anclado a la celda ([anchor] es
  /// su contexto).
  ///
  /// Es la version de [open] para los campos que se eligen: la celda queda
  /// elegida como cualquier otra y en vez del editor se despliegan **las
  /// opciones de esa columna**, que le pertenecen al campo y no a la empresa
  /// (ver [TableFieldModel.options]).
  ///
  /// El desplegable trae buscador recien pasadas [_kOptionSearchFrom] opciones:
  /// con una lista corta el buscador es una fila de mas entre la celda y lo que
  /// se quiere tocar, y con una larga es lo que hace que elegir sea escribir
  /// tres letras. Y trae siempre la fila de crear una opcion nueva, que es lo
  /// que permite armar la lista mientras se carga la tabla en vez de tener que
  /// definirla de antemano: la opcion que falta se escribe ahi mismo, se guarda
  /// en el campo y queda elegida en la celda de una sola pasada.
  ///
  /// Elegir la misma que ya tenia no manda nada, como salir de una celda de
  /// texto sin tocarla.
  Future<void> pickOption(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    if (anchor == null || !anchor.mounted) return;

    // Detras de los campos estan las columnas libres: ahi no hay campo del que
    // sacar opciones ni al que agregarselas.
    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    final current = valueOf(cell);

    final picked = await showSelectMenu(
      context: anchor,
      options: _optionsOf(anchor, field, current),
      selected: current,
      searchPlaceholder: field.options.length > _kOptionSearchFrom
        ? S.of(anchor).table_field_option_search
        : null,
      emptyText: S.of(anchor).table_field_option_empty,
      // Cuelga de una celda, que mide una fila: con la medida de siempre —la de
      // un campo de formulario— cinco opciones taparian media planilla.
      dense: true,
      createText: S.of(anchor).table_field_option_create,
      createPlaceholder: S.of(anchor).table_field_option_placeholder,
      onCreate: (name) => _createOption(field, name)
    );

    if (_disposed || picked == null) return;

    _writeOption(cell, picked.value);
  }

  /// Las opciones que se ofrecen en el desplegable de una celda.
  ///
  /// Son las del campo y, arriba de todas, la de vaciar la celda —pero solo si
  /// hay algo que vaciar—. Sin ella una celda de lista no tendria vuelta atras:
  /// no hay editor donde borrar el texto, asi que una opcion elegida por error
  /// quedaria puesta para siempre.
  List<SelectOption> _optionsOf(
    BuildContext context,
    TableFieldModel field,
    String current
  ) => [
    if (current.isNotEmpty) SelectOption(
      value: "",
      placeholder: S.of(context).table_field_option_none,
      icon: Icons.remove
    ),
    for (final option in field.options)
      SelectOption(value: option, placeholder: option)
  ];

  /// Agrega una opcion a la lista del campo desde el propio desplegable.
  ///
  /// Una opcion es una propiedad de la columna, asi que se guarda como se guarda
  /// cualquier otra: mandando el campo con la lista que tiene que quedar. Eso
  /// vuelve a leer la estructura —es la que acaba de cambiar— y con ella llega
  /// la lista nueva, asi que la proxima vez que se despliegue esa columna la
  /// opcion ya esta.
  ///
  /// Escribir una que ya estaba no crea nada ni falla: se devuelve la que hay,
  /// que es lo que quiso decir quien la escribio. Dos opciones que solo se
  /// distinguen en mayusculas o tildes son la misma ([sameFieldOption]), porque
  /// serian indistinguibles en la lista.
  ///
  /// Devuelve `null` si no se pudo guardar; el error ya lo mostro el servicio y
  /// la fila del desplegable queda abierta con lo escrito para reintentar.
  Future<SelectOption?> _createOption(
    TableFieldModel field,
    String name
  ) async {
    final existing = fieldOptionLike(field.options, name);
    if (existing != null) {
      return SelectOption(value: existing, placeholder: existing);
    }

    final options = fieldOptionsWith(field.options, name);
    if (options == null) return null;

    final saved = await service.editField(_context(), field, options: options);
    if (_disposed || !saved) return null;

    final created = name.trim();
    return SelectOption(value: created, placeholder: created);
  }

  // ---- Imagenes ------------------------------------------------------------

  /// Abre el desplegable de una celda de imagen, anclado a la celda ([anchor] es
  /// su contexto).
  ///
  /// Es el equivalente de [pickOption] para las fotos, y por eso es un
  /// desplegable y no un editor: una imagen no se escribe. Lo que se elige no es
  /// un valor sino **que hacer con ella** —verla, cargar una, eliminarla— porque
  /// el dato de la celda no es algo que alguien pueda tipear.
  ///
  /// Las opciones dependen de lo que la celda tenga: ver y eliminar solo
  /// aparecen si hay una foto, porque ofrecerlas sobre una celda vacia es
  /// ofrecer dos cosas que no hacen nada. Elegir una de una biblioteca todavia
  /// no esta —el backend ya lo acepta (`FILE_ID`), falta de que lista elegirla—
  /// asi que se muestra anunciada y no hace nada al tocarla.
  ///
  /// Una fila que todavia no es un registro no puede tener fotos: la foto se
  /// sube **contra un producto**, y el producto todavia no existe. Se avisa en
  /// vez de abrir un desplegable donde todo estaria apagado.
  Future<void> pickImage(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    if (anchor == null || !anchor.mounted) return;

    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    if (draftIndex(cell.row) >= 0) {
      FloatFlag.of(anchor).error(
        message: S.of(anchor).product_table_view_image_unsaved
      );
      return;
    }

    final slot = columns.slotAt(cell.column);
    final images = ProductImage.from(service.rowAt(cell.row)?.at(slot));
    final cover = images.isEmpty ? null : images.first;

    final picked = await showSelectMenu(
      context: anchor,
      options: [
        if (cover != null) SelectOption(
          value: _kImageView,
          placeholder: S.of(anchor).product_table_view_image_view,
          icon: CI.eye
        ),
        SelectOption(
          value: _kImageUpload,
          placeholder: S.of(anchor).product_table_view_image_upload,
          icon: CI.add_image
        ),
        SelectOption(
          value: _kImageLibrary,
          placeholder: S.of(anchor).product_table_view_image_library,
          subtitle: S.of(anchor).coming_soon,
          icon: CI.image
        ),
        if (cover != null) SelectOption(
          value: _kImageRemove,
          placeholder: S.of(anchor).product_table_view_image_remove,
          icon: CI.trash
        )
      ],
      // Cuelga de una celda, que mide una fila: con la medida de siempre —la de
      // un campo de formulario— cuatro opciones taparian media planilla.
      dense: true
    );

    if (_disposed || picked == null || !anchor.mounted) return;

    switch (picked.value) {
      case _kImageView:
        await showImageViewer(anchor, url: cover!.url);
      case _kImageUpload:
        await _uploadImage(cell, anchor, slot);
      case _kImageRemove:
        await _removeImage(cell, anchor, slot, cover!);
      // La biblioteca todavia no esta: la opcion se ve anunciada y no hace nada.
      default:
        break;
    }
  }

  /// Elige una foto del disco y la sube a la celda.
  ///
  /// El peso se mide **antes** de subir nada: el limite es el del multipart del
  /// backend, asi que pasarse es un rechazo del otro lado y avisarlo aca ahorra
  /// el viaje entero.
  ///
  /// No se recorta, al reves que el logo de una empresa: un logo se dibuja
  /// siempre cuadrado y hay que decidir que mitad de una foto apaisada se ve,
  /// pero una foto de producto se guarda como es y la celda ya la encuadra sola
  /// (ver [ImageCell]). Lo que se sube es lo que se eligio.
  Future<void> _uploadImage(
    SheetCell cell,
    BuildContext anchor,
    int slot
  ) async {
    final bytes = await pickImageBytes(
      label: S.of(anchor).product_table_view_image_files
    );

    if (bytes == null || _disposed) return;

    if (bytes.length > kImageMaxBytes) {
      if (anchor.mounted) {
        FloatFlag.of(anchor).error(
          message: S.of(anchor).product_table_view_image_large
        );
      }
      return;
    }

    // La subida viaja como multipart y eso pide un archivo, no un bloque de
    // memoria: se deja en la carpeta temporal el tiempo que dura y se borra pase
    // lo que pase.
    final file = await writeTempImage(bytes, name: "product");

    uploading.value = cell;

    try {
      await service.addImage(
        _context(),
        row: cell.row,
        slot: slot,
        file: file
      );
    } finally {
      await discardTempImage(file);
      if (!_disposed) uploading.value = null;
    }
  }

  /// Saca la portada de la celda.
  ///
  /// Son dos bajas distintas segun de quien sea la foto, y hay que distinguirlo:
  /// la que guarda esta plataforma se baja contra el backend, que ademas borra
  /// los bytes cuando ningun otro producto los muestra; una direccion que llego
  /// en una importacion no es un archivo nuestro —no hay nada que borrar— asi
  /// que se vacia la celda, que es lo que esa columna guarda.
  Future<void> _removeImage(
    SheetCell cell,
    BuildContext anchor,
    int slot,
    ProductImage cover
  ) async {
    if (!cover.isStored) {
      _writeOption(cell, "");
      return;
    }

    await service.removeImage(
      _context(),
      row: cell.row,
      slot: slot,
      fileId: cover.id
    );
  }

  /// Guarda la opcion elegida en la celda, por el mismo camino que el texto que
  /// se escribe: al borrador si la fila todavia se esta armando, y como
  /// correccion del registro si ya es una fila de la tabla.
  void _writeOption(SheetCell cell, String value) {
    final index = draftIndex(cell.row);

    if (index >= 0) {
      drafts.choose(index, columns.slotAt(cell.column), value);
      return;
    }

    finishRecord(cell, value, before: valueOf(cell));
  }

  /// Arma un SKU al azar y lo guarda en [cell].
  ///
  /// En un registro es una correccion mas, como elegir una opcion de una lista
  /// ([_writeOption]). En una de las filas en blanco de abajo, ademas, **la da
  /// de alta en el acto**: no espera a que el cursor se vaya de la fila, que es
  /// lo que crea el registro cuando la fila se escribe a mano ([_leaveRow]).
  ///
  /// Es la excepcion a esa regla y tiene por que serlo. Tocar el boton es un
  /// gesto completo —no queda nada a medio escribir despues de el, como si
  /// quedaria despues de una letra— y encima se toca sin entrar en la fila: el
  /// boton se come el toque de la celda, asi que el cursor nunca estuvo ahi y
  /// nunca va a salir de ahi. Sin esto la fila se queda con su codigo puesto y
  /// sin registro hasta que alguien la toque por otro motivo, que es
  /// exactamente lo que pasaba.
  void generateSku(SheetCell cell) {
    final index = draftIndex(cell.row);

    _writeOption(cell, nextSku());

    if (index < 0) return;

    // El editor puede estar abierto en otra celda de esta misma fila. Se cierra
    // antes del alta para que lo tipeado entre al borrador —y viaje con el—, y
    // no quede editando una fila que en un instante va a ser un registro: al
    // cerrarse ahi mandaria de nuevo, ya como correccion, lo que acaba de
    // guardarse.
    if (cursor.editing && cursor.cell?.row == cell.row) close();

    _queueDraft(drafts.at(index));
  }

  void back(BuildContext context) => Navis.push(context, "/home/inventory");

  // ---- Reacciones ----------------------------------------------------------

  /// Gano o perdio una columna: los anchos tienen que saber cual es la lista de
  /// ahora para poder sumar el ancho total de la planilla, y las columnas que
  /// aparecen se abren con el ancho que tuvieran guardado.
  void _onColumns() {
    widths.setKeys(columns.keys);

    // El ancho viene con el campo, asi que la tabla se dibuja como la dejo el
    // ultimo que la acomodo desde el primer frame. Solo lo adopta la primera vez
    // que ve cada columna: lo que se arrastre despues manda sobre lo que traiga
    // una estructura releida (ver [SheetWidths.adopt]).
    for (final field in columns.ordered) {
      if (field.id.isEmpty) continue;
      widths.adopt(field.id, field.width);
    }
  }

  /// Cambio la cantidad de filas ocupadas. Es lo unico que el servicio le manda
  /// al cuerpo de la planilla: los tramos de registros que van entrando los
  /// escucha cada fila por su cuenta.
  ///
  /// Es tambien donde se despide la fila que se acaba de guardar: el aviso que
  /// trae un registro mas es el mismo que tiene que llevarse su borrador (ver
  /// [_dropPersisted]).
  /// Buscando, la planilla mide **exactamente** las filas que coinciden: ni
  /// borradores ni filas de mas.
  ///
  /// Una planilla filtrada no es donde se carga: la fila que se escribiera abajo
  /// no seria de la busqueda —nace vacia, no menciona lo que se busco— asi que
  /// al guardarse se iria de la pantalla en la que se la escribio. Y el lugar
  /// donde se la escribio tampoco es un lugar de la tabla: las filas de una
  /// busqueda estan salteadas, la de abajo de todo no es la ultima de la tabla.
  /// Para cargar se vacia el buscador, que devuelve la planilla entera con sus
  /// filas en blanco al final.
  void _onRows() {
    _dropPersisted();

    usedRows.value = service.isSearching
      ? service.records
      : service.records + drafts.length + _extraRows;

    _schedulePrefetch();
  }

  /// Pide los tramos de las filas que se estan por mirar.
  ///
  /// Antes esto lo disparaba el `build` de cada fila, o sea que construir la
  /// pantalla pedia datos. Ahora lo dispara el desplazamiento, que es lo que
  /// realmente cambia lo que se ve: con `itemExtent` la primera y la ultima fila
  /// visibles salen de una division, sin construir nada.
  void _prefetch() {
    if (_disposed || !vBody.hasClients) return;

    final (first, last) = metrics.rangeAt(
      offset: vBody.offset,
      viewport: vBody.position.viewportDimension,
      rows: _rows
    );

    if (last < first) return;

    service.ensureRange(first, last + metrics.prefetch);
  }

  /// El primer tramo (y el de despues de cada recarga) se pide cuando la banda
  /// ya tiene medidas, no antes.
  void _schedulePrefetch() {
    if (_prefetchScheduled) return;

    _prefetchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchScheduled = false;
      _prefetch();
    });
  }

  void dispose() {
    _disposed = true;

    _stopEdgeScroll();
    vBody.removeListener(_prefetch);
    columns.removeListener(_onColumns);
    drafts.removeListener(_onRows);
    service.removeListener(_onRows);

    editor?.dispose();
    focus?.dispose();
    grid.dispose();
    vGutter.dispose();
    vBody.dispose();
    horizontal.dispose();

    usedRows.dispose();
    uploading.dispose();
    widths.dispose();
    drag.dispose();

    columns.dispose();
    drafts.dispose();
    cursor.dispose();
    hover.dispose();
    dates.dispose();
  }
}
