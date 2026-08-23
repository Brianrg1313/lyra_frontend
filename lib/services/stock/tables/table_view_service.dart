import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/stock/tables/table_ready_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga de la estructura de una tabla
/// (`GET /tables/structure/<table_id>`).
enum TableStructureStatus { idle, loading, ready, error }

/// Estado de la ultima lectura de registros (`POST /tables/records/`).
enum TableViewStatus { idle, loading, ready, empty, error }

/// Nombre del campo del formulario con el que viaja una foto de producto. Lo
/// decide el backend: es el que lee su multipart, y con cualquier otro la
/// peticion llega sin archivo.
const String _kImageField = "FILE";

/// Estado de una tabla abierta: su estructura y sus registros, leidos de a
/// tramos a medida que se los mira.
///
/// Abrir una tabla son **dos fases**, y en ese orden:
///
/// 1. **La estructura** (`GET /tables/structure/<table_id>`): la cabecera de la
///    tabla, sus campos y **cuantos registros tiene**. Se pide **una sola vez**
///    por tabla abierta y es lo que permite dibujar la planilla entera —la fila
///    de campos, las columnas y el largo de la tabla— antes de que llegue el
///    primer registro. Lo unico que la vuelve a pedir es algo que la cambie:
///    agregar una columna ([addField]), renombrarla o cambiarle el tipo
///    ([editField]), eliminarla ([deleteField]) o agregar un registro ([add]).
///    Esas relecturas pasan con la planilla ya dibujada, asi que **no vuelven a
///    [TableStructureStatus.loading]**: se avisan en [isReloading] y la pantalla
///    no se desmonta ni pierde donde estaba parada.
/// 2. **Los registros** (`POST /tables/records/`): se leen de a paginas, pero
///    no como paginas: la planilla es una sola lista tan larga como diga
///    [records], y cada tramo se pide cuando esta por entrar en pantalla
///    ([ensureRange]). No hay botones de paginado ni un final que corte la
///    tabla; bajando se sigue de largo.
///
///    La lectura es un POST y no un GET porque es una busqueda: las
///    condiciones, el orden y la paginacion viajan en el cuerpo (aca se manda la
///    tabla, la pagina y, si se esta buscando, el texto del buscador).
///
/// **La busqueda del header es parte de esa segunda fase** ([search]). Lo que se
/// escribe viaja en cada lectura de registros (`MATCH`) y vuelven las filas que
/// lo mencionan en cualquiera de sus columnas, contadas y paginadas igual que la
/// tabla entera: la planilla no esconde nada de lo que tiene, mide y pide sobre
/// el resultado. Esconderlo seria buscar en los tramos que se miraron y no en la
/// tabla, que es una respuesta distinta —y casi siempre incompleta— en cuanto la
/// tabla pasa de unas pocas paginas.
///
/// Sin estructura no hay segunda fase: si falla, no se piden registros, porque
/// no habria columnas contra las cuales leerlos ni un largo que darle a la
/// planilla.
///
/// Los registros se guardan por **indice absoluto** dentro de la tabla, no por
/// pagina: asi la fila 900 esta siempre en el lugar 900 aunque se haya llegado
/// hasta ella saltando con la barra de desplazamiento, y las filas en blanco del
/// final —las que se escriben— quedan ancladas detras del ultimo registro sin
/// correrse cada vez que entra un tramo nuevo.
///
/// Lo leido **no se guarda para siempre**: una tabla puede tener cientos de
/// miles de registros y recorrerla entera la dejaria entera en memoria. Se
/// mantiene un presupuesto de paginas ([_maxCachedPages]) y, al pasarse, se
/// olvida la mas lejana a la que se acaba de leer; si se vuelve a ella, se pide
/// de nuevo. El presupuesto es holgado a proposito: cubre de sobra cualquier
/// ida y vuelta razonable, y solo se activa recorriendo la tabla de punta a
/// punta.
///
/// La tabla tambien puede cambiar **sin que nadie de esta pantalla la toque**:
/// al terminar una importacion el backend le pone el tipo a sus columnas, le
/// agrega la de imagen y reescribe los valores que ya estaban guardados, todo
/// eso mucho despues de haber contestado. Cuando cae, avisa por socket
/// (`table/ready`, ver [TableReadyModel]) y este servicio vuelve a leer la
/// tabla donde este: es la misma relectura que un cambio de columna hecho a
/// mano, asi que no desmonta la planilla ni pierde donde estaba parada.
///
/// A diferencia de `TablesService` —que cachea el listado de tablas de la
/// empresa y vive en el scope de la app—, este servicio es efimero: lo posee la
/// propia pantalla de la tabla y se descarta al salir.
class TableViewService extends ChangeNotifier {
  TableViewService() {
    _unlisten = ConnectionService().on(TableReadyModel.event, _onReady);
  }

  TableStructureStatus _structureStatus = TableStructureStatus.idle;
  TableStructureModel _structure = const TableStructureModel();

  TableViewStatus _status = TableViewStatus.idle;

  /// `true` mientras se este releyendo la estructura de una tabla que **ya esta
  /// dibujada** (se agrego una columna, se le cambio el tipo, se guardo una
  /// fila). No es lo mismo que cargarla: eso se ve en [structureStatus] y tapa
  /// la pantalla; esto se avisa en la barra de arriba y no toca la planilla.
  bool _reloading = false;

  /// `true` mientras haya una lectura de estructura en el aire. Evita que dos se
  /// pisen; se lleva aparte de [structureStatus] porque una relectura no cambia
  /// ese estado.
  bool _reading = false;

  /// `true` cuando una relectura de estructura no llego. La planilla sigue
  /// mostrando la de antes —es la unica que hay— pero puede estar vieja: el
  /// cambio de columna que la disparo si salio. Es lo que hace que el reintento
  /// de la barra vuelva a pedirla en vez de limitarse a los tramos.
  bool _staleStructure = false;

  /// Registros leidos, por indice absoluto dentro de la tabla. Es ralo a
  /// proposito: de una tabla de miles de filas solo estan las que se miraron.
  final Map<int, TableRowModel> _rows = {};

  /// La contabilidad de la lectura por tramos: que se leyo, que esta en camino y
  /// donde termina la tabla.
  TablePaging _paging = TablePaging();

  /// Las paginas que estan guardadas en [_rows], en el orden en que llegaron.
  final List<int> _cached = [];

  /// Tabla que se esta viendo. Se fija al abrir y no cambia mientras la
  /// pantalla siga viva.
  String? _tableId;

  /// Baja del oyente de `table/ready`. El servicio muere con la pantalla, asi
  /// que sin esto quedaria escuchando una tabla que ya nadie mira.
  void Function()? _unlisten;

  /// `true` mientras se esta guardando un item nuevo. Evita reentrar en [add] si
  /// se dispara dos veces; la pantalla maneja su propio estado de carga del
  /// boton.
  bool _saving = false;

  /// Lo que se escribio en el buscador del header, o vacio si no se esta
  /// buscando. Viaja en cada lectura de registros (`MATCH`) y por lo tanto **la
  /// planilla filtrada la filtra el backend**: no es que se escondan las filas
  /// que se tienen, es que las que se piden ya vienen filtradas. Es la unica
  /// forma que funciona igual en una tabla de diez filas que en una de
  /// quinientas mil, donde lo que hay en memoria es un puñado de tramos.
  String _query = "";

  /// Cuantas filas coinciden con [query]. Lo dice cada pagina filtrada (`total`)
  /// y es lo que mide la planilla mientras se busca, en lugar de los registros
  /// que tiene la tabla.
  int _matches = 0;

  /// Que lectura es la de ahora. Cambiar la busqueda tira lo leido y vuelve a
  /// empezar, asi que un tramo que ya estaba viajando llegaria con las filas de
  /// la busqueda anterior y se guardaria en el lugar de las de esta: lo que se
  /// escribio se compara al volver y el tramo viejo se descarta.
  int _generation = 0;

  /// De a cuantos registros se lee cada tramo. Se manda en la peticion en vez
  /// de dejar el que el backend pone por defecto, para que las dos puntas
  /// cuenten las filas igual: [TablePaging] traduce una fila a su pagina
  /// suponiendo que todas las paginas miden lo mismo.
  static const int _pageSize = 50;

  /// Cuantas paginas se guardan a la vez. Con [_pageSize] son diez mil filas en
  /// memoria: mucho mas de lo que se puede mirar, y un techo fijo aunque la
  /// tabla tenga cientos de miles de registros.
  static const int _maxCachedPages = 200;

  TableStructureStatus get structureStatus => _structureStatus;
  TableStructureModel get structure => _structure;

  /// Las columnas de la tabla. Salen de la estructura, no de los registros: son
  /// las mismas se este mirando el tramo que se este mirando.
  List<TableFieldModel> get fields => _structure.fields;

  TableViewStatus get status => _status;

  /// `true` mientras se este trayendo algun tramo.
  bool get isLoadingRows => _paging.isReading;

  /// `true` mientras se este releyendo la estructura de una tabla ya dibujada.
  /// Lo muestra la barra de arriba: es la unica señal de que el cambio de
  /// columna todavia esta viajando, porque la planilla no se mueve.
  bool get isReloading => _reloading;

  /// Lo que se esta buscando, o vacio si no se esta buscando nada.
  String get query => _query;

  /// `true` mientras la planilla este filtrada por una busqueda.
  bool get isSearching => _query.isNotEmpty;

  /// Cuantas filas de registros tiene la planilla.
  ///
  /// Lo dice la estructura, asi que se sabe antes de leer un solo registro: la
  /// planilla nace con su largo definitivo y las filas que todavia no llegaron
  /// se ven vacias hasta que entran en pantalla. Si la estructura no lo trae, se
  /// cae en lo unico que se puede saber —hasta donde se leyo— y la tabla crece a
  /// medida que se baja.
  ///
  /// Buscando son las que coinciden y no las que tiene la tabla: la planilla
  /// mide lo que devolvio la busqueda, que es lo que la hace desplazarse y pedir
  /// tramos sobre el resultado igual que sobre la tabla entera. Hasta que llegue
  /// la primera pagina filtrada son cero, que es lo unico honesto que se puede
  /// decir: cuantas coinciden lo sabe el backend, no la estructura.
  int get records => isSearching
    ? _matches
    : _structure.records > 0 ? _structure.records : _paging.known;

  /// El registro de la fila [index], o `null` si esa fila todavia no se leyo.
  TableRowModel? rowAt(int index) => _rows[index];

  /// Se asegura de que esten pedidos los tramos que cubren las filas de [first]
  /// a [last].
  ///
  /// La llama la planilla cuando se desplaza, con el rango que se ve mas unas
  /// cuantas filas de mas abajo: asi el tramo siguiente se pide antes de que se
  /// lo necesite y las filas entran ya cargadas en vez de aparecer en blanco.
  ///
  /// Se recorre de pagina en pagina y no de fila en fila: el rango visible puede
  /// ser de cientos de filas y todas caen en dos o tres paginas.
  ///
  /// Las paginas se piden fuera del frame: esto corre mientras se dibuja o se
  /// desplaza, y avisar de la carga ahi mismo repintaria en medio del build.
  void ensureRange(int first, int last) {
    if (_structureStatus != TableStructureStatus.ready) return;

    final from = math.max(0, first);
    if (last < from) return;

    // Todavia no se sabe de a cuantos registros se lee: la primera pagina es la
    // que lo revela, y hasta que llegue no se puede traducir ninguna otra fila.
    if (_paging.size <= 0) {
      _requestRow(0);
      return;
    }

    for (int index = from; index <= last; index += _paging.size) {
      _requestRow(index);
    }

    // La ultima fila del rango puede caer en una pagina que el salto anterior
    // se paso de largo.
    _requestRow(last);
  }

  void _requestRow(int index) {
    if (_rows.containsKey(index)) return;

    final page = _paging.request(index);
    if (page <= 0) return;

    scheduleMicrotask(() => _loadPage(page));
  }

  /// Abre una tabla: primero su estructura y, con ella, el primer tramo de
  /// registros. Reinicia el estado, porque este servicio no cachea entre tablas:
  /// vive y muere con la pantalla.
  ///
  /// [query] es lo que hubiera en el buscador del header al abrirla. Normalmente
  /// esta vacio —el header se vacia al cambiar de pantalla— pero una tabla que
  /// se monta con algo escrito tiene que abrirse ya filtrada: si no, el buscador
  /// diria una cosa y la planilla mostraria otra.
  Future<void> open(String tableId, {String query = ""}) {
    _tableId = tableId;
    _structure = const TableStructureModel();
    _structureStatus = TableStructureStatus.idle;
    _reloading = false;
    _staleStructure = false;
    _rows.clear();
    // Otra tabla, otro tamaño de pagina: la contabilidad arranca de cero y no se
    // reusa la de la anterior.
    _paging = TablePaging();
    _status = TableViewStatus.idle;
    _query = query.trim();
    _matches = 0;
    _generation++;

    return _load();
  }

  /// Busca [query] en la tabla: la planilla pasa a mostrar solo las filas que lo
  /// mencionan, en cualquiera de sus columnas.
  ///
  /// La llama la pantalla con lo que se escribio en el buscador del header, que
  /// es uno solo para todo el home y busca sobre la seccion que se este mirando
  /// (ver `HomeService.searchQuery`). Vaciar el buscador vuelve a la tabla
  /// entera, que es la busqueda vacia.
  ///
  /// **Filtra el backend, no la planilla.** De una tabla de cientos de miles de
  /// filas en memoria hay unos tramos, asi que esconder las que no coinciden
  /// buscaria en lo que se miro y no en la tabla: lo que se manda es el texto
  /// (`MATCH`) y lo que vuelve son las filas que coinciden, contadas y paginadas
  /// como cualquier otra lectura. Por eso buscar tira lo leido y vuelve a
  /// empezar por la primera fila: las de antes eran de otra planilla.
  ///
  /// Con la tabla todavia sin dibujar no se pide nada: la lectura que ya esta en
  /// curso pide su primer tramo al terminar la estructura, y para entonces esto
  /// ya dejo escrito con que texto pedirlo.
  Future<void> search(String query) {
    final next = query.trim();
    if (next == _query) return Future.value();

    _query = next;
    _matches = 0;
    _generation++;
    _reset();
    notifyListeners();

    if (_structureStatus != TableStructureStatus.ready) return Future.value();

    final page = _paging.request(0);
    return page > 0 ? _loadPage(page) : Future.value();
  }

  /// Reintenta lo que fallo. Si falto la estructura, se vuelve a pedir entera;
  /// si fallo un tramo de registros, alcanza con volver a pintar: la planilla
  /// pide sola las filas que se ven y la que no llego se vuelve a pedir ahi.
  ///
  /// Una estructura vieja ([_staleStructure]) cuenta como estructura que falto,
  /// aunque haya una dibujada: el cambio de columna que la dejo asi si salio, y
  /// sin volver a pedirla la planilla no lo muestra nunca.
  Future<void> retry() {
    if (_structureStatus != TableStructureStatus.ready || _staleStructure) {
      return _load();
    }

    _paging.retry();
    _status = _rows.isEmpty ? TableViewStatus.idle : TableViewStatus.ready;
    notifyListeners();

    return Future.value();
  }

  /// Alta de un item (una fila) contra `POST /products/manage/`.
  ///
  /// [values] son los datos capturados, indexados por FIELD_ID: es lo que va en
  /// el campo `DATA` del cuerpo, junto al `TABLE_ID` de la tabla abierta (que la
  /// pantalla no tiene que pasar, lo pone el servicio). La empresa dueña viaja
  /// en la cabecera `business_id`, como en el resto de las apis.
  ///
  /// Devuelve `true` si el alta salio bien. En ese caso los registros leidos
  /// quedan viejos —hay uno mas, y donde caiga lo decide el backend— asi que se
  /// descartan y se vuelve a leer la estructura, que es la que dice cuantos hay.
  /// Con [refresh] en `false` eso no se hace: lo usa el guardado en lote, que
  /// prefiere refrescar una sola vez al final ([refresh]) y no despues de cada
  /// fila.
  ///
  /// Ante un error muestra la bandera flotante y devuelve `false`, dejando el
  /// borrador intacto para reintentar.
  Future<bool> add(
    BuildContext context,
    Map<String, dynamic> values, {
    bool refresh = true
  }) async {
    if (_saving) return false;

    final tableId = _tableId;
    if (tableId == null) return false;

    _saving = true;
    notifyListeners();

    try {
      await api.post(
        path: "/products/manage/",
        version: "v1",
        data: createRecordRequest(tableId: tableId, values: values)
      );

      _saving = false;

      if (refresh) {
        await this.refresh();
      } else {
        notifyListeners();
      }

      return true;
    } catch (error) {
      if (kDebugMode) print("addProduct failed: $error");

      _saving = false;
      notifyListeners();

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Edicion de una celda de un registro contra `PUT /products/manage/`.
  ///
  /// Es lo que hace que la planilla se escriba entera y no solo en las filas de
  /// abajo: se toca una celda de una fila ya guardada, se escribe y al salir el
  /// cambio viaja. Va de a una celda ([slot] es el campo dentro de la fila y
  /// [fieldId] su FIELD_ID, la clave con la que se guarda) porque es lo que se
  /// edito: mandar la fila entera reescribiria campos que nadie miro.
  ///
  /// **El cambio se ve al instante y viaja detras**, como el orden de las
  /// columnas: la celda muestra lo que se acaba de escribir sin esperar al
  /// backend y sin volver a leer la tabla, que a esta escala es la diferencia
  /// entre corregir un precio y bajar la tabla de nuevo. Si no sale, la fila
  /// vuelve al valor que tenia y el error se muestra en la bandera flotante.
  ///
  /// Devuelve `false` si no habia a que registro escribirle: la fila todavia no
  /// se leyo, no vino con id o el campo no tiene FIELD_ID.
  Future<bool> editRecord(
    BuildContext context, {
    required int row,
    required int slot,
    required String fieldId,
    required String value
  }) async {
    final tableId = _tableId;
    final record = _rows[row];

    if (tableId == null || record == null) return false;
    if (record.id.isEmpty || fieldId.isEmpty || slot < 0) return false;

    final before = record.at(slot);

    _rows[row] = record.withValue(slot, value);
    notifyListeners();

    try {
      await api.put(
        path: "/products/manage/",
        version: "v1",
        data: editRecordRequest(
          tableId: tableId,
          id: record.id,
          values: {fieldId: value}
        )
      );

      return true;
    } catch (error) {
      if (kDebugMode) print("editRecord failed: $error");

      _restore(row, record.id, slot, before);

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Devuelve una celda al valor que tenia, despues de una edicion que no salio.
  ///
  /// Mientras el cambio viajaba la tabla se pudo releer, o ese tramo se pudo
  /// olvidar y volver a pedir: se comprueba que en esa fila siga estando el
  /// mismo registro antes de tocarla, porque escribirle a la de ahora seria
  /// pisar un dato bueno con uno viejo.
  void _restore(int row, String id, int slot, dynamic value) {
    final current = _rows[row];
    if (current == null || current.id != id) return;

    _rows[row] = current.withValue(slot, value);
    notifyListeners();
  }

  /// Agrega una foto a un producto contra `POST /inventory/images/`.
  ///
  /// La foto viaja como multipart en el campo `FILE`, con la tabla y el registro
  /// al lado, y el backend hace todo lo demas: la reencoda a WebP, la acota,
  /// renderiza la miniatura con la que se dibuja una celda y le saca los
  /// metadatos. Lo que se sube nunca son los bytes que se eligieron.
  ///
  /// **No es optimista**, al reves que [editRecord]: hasta que el backend no
  /// contesta no hay id que poner en la celda, asi que no hay nada que mostrar
  /// antes de tiempo. Lo que se ve mientras tanto es el cargando de la celda,
  /// que lo lleva la planilla ([SheetController.uploading]).
  ///
  /// La celda se queda con la galeria que devuelve la respuesta y no con el id
  /// que acaba de entrar: un producto puede tener varias fotos y la primera es
  /// la portada, asi que quien decide el orden —y cual es la portada— es el
  /// backend.
  ///
  /// Devuelve `false` si no habia a que registro subirsela (la fila todavia no
  /// se leyo o no vino con id) o si la subida no salio, y en ese caso el error
  /// se muestra en la bandera flotante.
  Future<bool> addImage(
    BuildContext context, {
    required int row,
    required int slot,
    required File file
  }) async {
    final tableId = _tableId;
    final record = _rows[row];

    if (tableId == null || record == null) return false;
    if (record.id.isEmpty || slot < 0) return false;

    try {
      final data = await api.file(
        path: "/inventory/images/",
        version: "v1",
        file: file,
        field: _kImageField,
        data: {"TABLE_ID": tableId, "PRODUCT_ID": record.id}
      );

      _writeImages(row, record.id, slot, data);

      return true;
    } catch (error) {
      if (kDebugMode) print("addImage failed: $error");

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Quita una foto de un producto contra
  /// `DELETE /inventory/images/<tabla>/<producto>/<archivo>`.
  ///
  /// **La celda se vacia al instante y la baja viaja detras**, como una edicion
  /// cualquiera: la foto se saca de la galeria que ya esta en pantalla y, si la
  /// baja no sale, la fila vuelve a la que tenia.
  ///
  /// Solo se baja asi lo que guarda esta plataforma. Una direccion que llego en
  /// una importacion es un dato de la empresa y no un archivo nuestro: esa se
  /// borra como se borra cualquier valor de una celda ([editRecord]).
  ///
  /// El backend borra los bytes solo cuando ningun otro producto los muestra, y
  /// quitar una foto que el producto no tiene le da lo mismo: es lo que se
  /// pidio, y ya es asi.
  Future<bool> removeImage(
    BuildContext context, {
    required int row,
    required int slot,
    required String fileId
  }) async {
    final tableId = _tableId;
    final record = _rows[row];

    if (tableId == null || record == null) return false;
    if (record.id.isEmpty || slot < 0 || fileId.isEmpty) return false;

    final before = record.at(slot);
    final left = [
      for (final image in ProductImage.from(before))
        if (image.id != fileId) image
    ];

    _rows[row] = record.withValue(slot, ProductImage.valuesOf(left));
    notifyListeners();

    try {
      await api.delete(
        path: "/inventory/images/$tableId/${record.id}/$fileId",
        version: "v1"
      );

      return true;
    } catch (error) {
      if (kDebugMode) print("removeImage failed: $error");

      _restore(row, record.id, slot, before);

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Deja en la celda la galeria que devolvio el backend.
  ///
  /// Se comprueba que en esa fila siga estando el mismo registro, por lo mismo
  /// que en [_restore]: una subida tarda, y mientras tanto la tabla se pudo
  /// releer o ese tramo se pudo volver a pedir.
  void _writeImages(int row, String id, int slot, dynamic data) {
    final current = _rows[row];
    if (current == null || current.id != id) return;

    _rows[row] = current.withValue(
      slot,
      ProductImage.valuesOf(ProductImage.fromResponse(data))
    );
    notifyListeners();
  }

  /// Vuelve a leer la tabla despues de **agregar un registro**: la estructura
  /// (que es la que sabe cuantos hay) y, con ella, los tramos que se esten
  /// viendo. Lo que ya se habia leido se descarta de entrada, porque un registro
  /// nuevo corre de lugar a todos los que van detras.
  Future<void> refresh() {
    _reset();
    return _load();
  }

  /// Vuelve a leer la tabla despues de **un cambio de columnas**.
  ///
  /// A diferencia de [refresh] no descarta nada por adelantado: los registros
  /// son los mismos y siguen en el mismo lugar, asi que quien decide que hacer
  /// con lo leido es la estructura que llega. Agregar una columna o renombrarla
  /// no lo toca ([fieldsGrewAtEnd]); eliminarla, o que los campos vuelvan en
  /// otro orden, solo lo corre de lugar ([fieldsRemap]). Volver a pedir las
  /// paginas es el ultimo recurso.
  Future<void> _reloadFields() => _load();

  /// El backend termino de preparar una tabla. Si es la que esta abierta, se la
  /// vuelve a leer.
  ///
  /// Cuanto se tira depende de si cambiaron los **valores** y no las columnas:
  /// al retipar una columna el backend reescribe lo que ya estaba guardado
  /// (`Products.recast`), asi que los registros en memoria quedaron viejos
  /// aunque los campos sean los mismos y haya que pedirlos de nuevo. Si no
  /// retipo nada —la tabla solo gano su columna de imagen— alcanza con la
  /// relectura barata, que conserva las paginas leidas.
  ///
  /// Con la tabla todavia sin dibujar no se hace nada: hay una lectura en curso
  /// o a punto de salir, y esa ya va a traer la estructura nueva.
  void _onReady(dynamic data) {
    if (_structureStatus != TableStructureStatus.ready) return;

    final report = TableReadyModel.fromEvent(data);
    if (report.isEmpty || report.id != _tableId) return;

    if (report.changedValues) {
      refresh();
    } else {
      _reloadFields();
    }
  }

  @override
  void dispose() {
    _unlisten?.call();
    _unlisten = null;
    super.dispose();
  }

  /// Alta de una columna (campo) contra `POST /tables/fields/`.
  ///
  /// Es una modificacion de la estructura de la tabla abierta, no de sus datos:
  /// el campo se agrega al final ([fields] da la [POSITION]) y la tabla no la
  /// tiene que pasar, la pone el servicio junto al `TABLE_ID`. El resto (nombre,
  /// descripcion, tipo) llega de la planilla.
  ///
  /// Devuelve `true` si el alta salio bien; en ese caso vuelve a leer la
  /// estructura —es la que acaba de cambiar— y con ella los registros, que ahora
  /// tienen una celda mas. Ante un error muestra la bandera flotante y devuelve
  /// `false`.
  Future<bool> addField(
    BuildContext context, {
    required String name,
    required String description,
    required String type
  }) async {
    final tableId = _tableId;
    if (tableId == null) return false;

    try {
      await api.post(
        path: "/tables/fields/",
        version: "v1",
        data: createFieldRequest(
          tableId: tableId,
          name: name,
          description: description,
          type: type,
          // La nueva columna va al final: su posicion es la cantidad actual.
          position: _structure.fields.length
        )
      );

      await _reloadFields();
      return true;
    } catch (error) {
      if (kDebugMode) print("addField failed: $error");

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Edicion de una columna contra `PUT /tables/fields/`: su nombre, su tipo,
  /// las opciones de su lista, o los tres.
  ///
  /// Es lo que hacen la celda del campo y su flecha: la columna nace como
  /// `TEXT` con el titulo que se le escribio —eso es todo lo que hace falta
  /// para crearla— y despues se corrige ahi mismo, sin formularios de por
  /// medio. Crear una opcion en el desplegable de una celda de lista pasa por
  /// el mismo camino: una opcion es una propiedad del campo, asi que se guarda
  /// mandando la lista que tiene que quedar ([options]).
  ///
  /// Solo viaja lo que se cambia; el nombre va siempre porque el backend lo
  /// pide, asi que cambiar solo el tipo manda el que el campo ya tenia. Lo que
  /// no se manda (descripcion, posicion) queda como estaba. Devuelve `true` si
  /// el cambio salio bien, y en ese caso vuelve a leer la estructura —que es la
  /// que acaba de cambiar— y con ella los registros, que ahora se leen y se
  /// alinean contra el tipo nuevo.
  Future<bool> editField(
    BuildContext context,
    TableFieldModel field, {
    String? name,
    String? type,
    List<String>? options
  }) async {
    // Sin FIELD_ID no hay campo que editar: es una columna que se vio pero que
    // el backend no identifico.
    if (field.id.isEmpty) return false;

    try {
      await api.put(
        path: "/tables/fields/",
        version: "v1",
        data: editFieldRequest(
          id: field.id,
          name: name ?? field.name,
          type: type,
          options: options
        )
      );

      await _reloadFields();
      return true;
    } catch (error) {
      if (kDebugMode) print("editField failed: $error");

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Guarda el orden de las columnas contra `PUT /tables/fields/`.
  ///
  /// [ordered] son los campos tal como tienen que quedar, y la posicion de cada
  /// uno es su lugar en esa lista.
  ///
  /// Se manda la de **todos** y no solo la de los que se movieron porque el
  /// backend no reacomoda a los vecinos: guarda la posicion que se le da y
  /// despues ordena por ella, asi que renumerar solo un tramo dejaria posiciones
  /// repetidas y el orden pasaria a depender de como las devuelva la base. Son
  /// tantas peticiones como columnas —unas pocas decenas como mucho—, van todas
  /// juntas y solo al soltar una columna, que no es algo que se haga seguido.
  ///
  /// **No vuelve a leer la estructura**, y ahi esta lo que hace que arrastrar una
  /// columna sea gratis: la planilla ya muestra el orden nuevo (lo aplico al
  /// soltar, sin esperar a nadie) y releerla solo traeria los mismos campos en
  /// el mismo orden, tirando de paso las paginas que se estan mirando. Lo que se
  /// acaba de guardar se nota recien la proxima vez que se abra la tabla, que es
  /// justamente cuando importa.
  ///
  /// Devuelve `true` si salieron todas. Si alguna falla, la planilla vuelve al
  /// orden de antes ([SheetColumns.restoreOrder]) y puede quedar alguna posicion
  /// a medio escribir del otro lado: el proximo arrastre que salga bien las
  /// renumera todas de nuevo y las empareja.
  Future<bool> reorderFields(
    BuildContext context,
    List<TableFieldModel> ordered
  ) async {
    if (ordered.length < 2) return true;

    try {
      await Future.wait([
        for (final (position, field) in ordered.indexed)
          if (field.id.isNotEmpty)
            api.put(
              path: "/tables/fields/",
              version: "v1",
              data: editFieldRequest(
                id: field.id,
                name: field.name,
                position: position
              )
            )
      ]);

      return true;
    } catch (error) {
      if (kDebugMode) print("reorderFields failed: $error");

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Guarda el ancho de una columna contra `PUT /tables/fields/`.
  ///
  /// El ancho es una propiedad **de la tabla**, no de quien la mira: se guarda
  /// con el campo y la estructura lo trae, asi que la tabla se abre igual para
  /// todos los de la empresa. Viaja al soltar el borde y no mientras se arrastra
  /// —un arrastre son decenas de eventos por segundo— y se manda entero, en
  /// pixeles logicos: la fraccion que deja un arrastre no significa nada del
  /// otro lado.
  ///
  /// **No vuelve a leer la estructura**, por el mismo motivo que el orden de las
  /// columnas ([reorderFields]): la planilla ya muestra el ancho nuevo y releer
  /// solo traeria los mismos campos, tirando de paso las paginas que se estan
  /// mirando.
  ///
  /// Devuelve `true` si salio. Si no, quien lo llamo devuelve la columna al
  /// ancho que tenia; el error ya lo mostro la bandera flotante.
  Future<bool> resizeField(
    BuildContext context,
    TableFieldModel field, {
    required double width
  }) async {
    if (field.id.isEmpty || width <= 0) return false;

    try {
      await api.put(
        path: "/tables/fields/",
        version: "v1",
        data: editFieldRequest(
          id: field.id,
          name: field.name,
          width: width.round()
        )
      );

      return true;
    } catch (error) {
      if (kDebugMode) print("resizeField failed: $error");

      if (!context.mounted) return false;

      // Un `action` es una instruccion de navegacion (sesion vencida, etc.): se
      // relanza tal cual para que la maneje quien corresponda.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Baja de una columna contra `DELETE /tables/fields/`.
  ///
  /// Se lleva la columna y todo lo que se haya cargado en ella, asi que quien
  /// la llama tiene que haberlo confirmado antes: el servicio no pregunta.
  ///
  /// Devuelve `true` si la baja salio bien, y en ese caso vuelve a leer la
  /// estructura —hay una columna menos— y con ella los registros, que ahora
  /// tienen una celda menos.
  Future<bool> deleteField(BuildContext context, TableFieldModel field) async {
    if (field.id.isEmpty) return false;

    try {
      await api.delete(
        path: "/tables/fields/",
        version: "v1",
        data: deleteFieldRequest(id: field.id)
      );

      await _reloadFields();
      return true;
    } catch (error) {
      if (kDebugMode) print("deleteField failed: $error");

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Olvida los registros leidos, sin tocar la estructura ni el tamaño de
  /// pagina, que no cambian.
  void _reset() {
    _rows.clear();
    _cached.clear();
    _paging.reset();
    _status = TableViewStatus.idle;
  }

  /// Deja el cache dentro del presupuesto.
  void _trimCache(int around) {
    while (true) {
      final page = pageToForget(
        _cached,
        around: around,
        budget: _maxCachedPages
      );
      if (page == null) return;

      _cached.remove(page);
      _forget(page);
    }
  }

  /// Olvida una pagina: sus filas y la marca de leida, para que se pueda volver
  /// a pedir si se vuelve a ella.
  void _forget(int page) {
    final start = _paging.startOf(page);

    for (int offset = 0; offset < _paging.size; offset++) {
      _rows.remove(start + offset);
    }

    _paging.forget(page);
  }

  /// Las dos fases, en orden: la estructura y, si vino, el primer tramo de
  /// registros. Es lo que corre al abrir la tabla, al reintentar y despues de
  /// cada cosa que la cambie.
  Future<void> _load() async {
    if (!await _loadStructure()) return;

    // El primer tramo se pide por el mismo camino que los demas: la fila 0
    // siempre esta en la pagina 1, que es ademas la que revela de a cuantos
    // registros se lee.
    final page = _paging.request(0);
    if (page > 0) await _loadPage(page);
  }

  /// Primera fase: la estructura de la tabla.
  ///
  /// Devuelve `true` si quedo cargada y se puede seguir con los registros. Una
  /// estructura que no llega deja la pantalla en error: sin columnas no hay nada
  /// que dibujar, ni siquiera la fila de campos.
  ///
  /// **Una tabla ya dibujada no vuelve nunca a la pantalla en blanco.** Releer la
  /// estructura —agregar una columna, cambiarle el tipo, eliminarla, guardar una
  /// fila— pasa con la planilla montada y el usuario mirando la fila que sea:
  /// pasar por [TableStructureStatus.loading] desmontaria la grilla, y con ella
  /// se irian el desplazamiento (habria que volver a bajar hasta donde se
  /// estaba) y la celda que se estaba escribiendo. Por eso una relectura se
  /// avisa aparte ([isReloading]), en la barra de arriba, y el estado se queda
  /// en `ready` de punta a punta.
  Future<bool> _loadStructure() async {
    if (_reading) return false;

    final tableId = _tableId;
    if (tableId == null) return false;

    // La tabla ya esta dibujada: esto es una relectura, no una carga.
    final reload = _structureStatus == TableStructureStatus.ready;

    _reading = true;
    _reloading = reload;
    if (!reload) _structureStatus = TableStructureStatus.loading;
    notifyListeners();

    final data = await api
        .get(path: "/tables/structure/$tableId", version: "v1")
        .catchError((error) {
      if (kDebugMode) print("loadTableStructure failed: $error");
      return null;
    });

    _reading = false;
    _reloading = false;

    if (data == null) {
      // Una relectura que falla deja lo que ya habia: la estructura vieja sigue
      // siendo la de la tabla y tirarla dejaria la pantalla en error por un
      // cambio de columna que no salio. El aviso va arriba, como el de un tramo
      // que no llego.
      if (reload) {
        _staleStructure = true;
        _status = TableViewStatus.error;
      } else {
        _structureStatus = TableStructureStatus.error;
      }

      notifyListeners();
      return false;
    }

    final before = [for (final field in _structure.fields) field.id];

    _structure = TableStructureModel.fromResponse(data);
    _structureStatus = TableStructureStatus.ready;

    // Se levanta el error que puso una relectura anterior que no habia llegado:
    // esta si llego, asi que la estructura ya no esta vieja.
    if (_staleStructure) {
      _staleStructure = false;
      _status = _rows.isEmpty ? TableViewStatus.idle : TableViewStatus.ready;
    }

    // Lo leido sirve tal cual si los campos de antes siguen donde estaban, que
    // es lo que pasa al renombrar una columna o al agregar una: no se toca nada
    // y se conservan las paginas que se tengan, que a esta escala es la
    // diferencia entre agregar una columna y volver a bajar la tabla entera.
    //
    // Si se movieron —el orden que se acaba de guardar, una columna que ya no
    // esta— las filas siguen teniendo los mismos valores, solo que en otro
    // lugar: se las reacomoda de una pasada y las paginas se salvan igual.
    // Volver a pedirlas es el ultimo recurso, para cuando no hay FIELD_ID con
    // que emparejar las dos listas.
    final after = [for (final field in _structure.fields) field.id];

    if (!fieldsGrewAtEnd(before, after)) {
      final remap = fieldsRemap(before, after);

      if (remap == null) {
        _reset();
      } else {
        _remapRows(remap);
      }
    }

    notifyListeners();

    return true;
  }

  /// Reacomoda los registros leidos a los campos de ahora, con el mapa que
  /// devuelve [fieldsRemap].
  ///
  /// Es una pasada sobre lo que hay en memoria, no sobre la tabla: a lo sumo son
  /// las [_maxCachedPages] paginas del presupuesto, y solo corre cuando los
  /// campos cambiaron de lugar.
  void _remapRows(List<int> remap) {
    for (final index in _rows.keys.toList(growable: false)) {
      final row = _rows[index]!;

      _rows[index] = TableRowModel(
        [for (final position in remap) position < 0 ? null : row.at(position)],
        // El registro sigue siendo el mismo: lo que se movio son sus columnas.
        id: row.id
      );
    }
  }

  /// Segunda fase: un tramo de registros (`POST /tables/records/`).
  ///
  /// Del cuerpo que admite esa busqueda aca se manda lo minimo: la tabla, que
  /// pagina, de a cuantas filas y —si se esta buscando— el texto que se escribio
  /// (`MATCH`). Sin `WHERE` ni `SORT`, que son condiciones por columna: la
  /// planilla no las tiene, muestra la tabla en el orden en que el backend la
  /// devuelve.
  ///
  /// `MATCH` no cambia en nada la forma de leer: la busqueda se pagina y se
  /// cuenta como la tabla entera, solo que sobre las filas que coinciden. Por eso
  /// buscar en una tabla de quinientas mil filas cuesta lo mismo que abrirla, y
  /// no hay un momento en el que la planilla tenga que tener todo.
  ///
  /// Cada pagina se guarda en su lugar dentro de la tabla, no al final de lo que
  /// haya: la fila que ocupa el indice 900 es la misma se haya llegado hasta ella
  /// bajando o de un salto.
  ///
  /// Las filas se reordenan contra la estructura ([TableViewModel.alignedTo]):
  /// las columnas ya las fijo la primera fase, y de aca solo salen los valores.
  Future<void> _loadPage(int page) async {
    final tableId = _tableId;

    if (tableId == null) {
      _paging.failed(page);
      return;
    }

    // Con que busqueda sale este tramo. Si cambia mientras viaja, lo que vuelva
    // ya no es de esta planilla.
    final generation = _generation;

    _status = TableViewStatus.loading;
    notifyListeners();

    final data = await api
        .post(
          path: "/tables/records/",
          version: "v1",
          data: {
            "TABLE_ID": tableId,
            "PAGE": page,
            "SIZE": _pageSize,
            if (_query.isNotEmpty) "MATCH": _query
          }
        )
        .catchError((error) {
      if (kDebugMode) print("loadTableRecords failed: $error");
      return null;
    });

    // Se busco otra cosa mientras esto viajaba: estas filas son las de la
    // busqueda anterior y sus indices, los de una planilla que ya no existe. No
    // se anota ni el fallo: esa contabilidad tambien se tiro.
    if (generation != _generation) return;

    if (data == null) {
      _paging.failed(page);
      _status = TableViewStatus.error;
      notifyListeners();
      return;
    }

    final rows = TableViewModel
      .fromResponse(data)
      .alignedTo(_structure.fields)
      .rows;

    // El tramo se guarda en su lugar dentro de la tabla, no al final de lo que
    // haya: la pagina dice donde empieza.
    final start = _paging.read(page, rows.length);
    for (final (offset, row) in rows.indexed) {
      _rows[start + offset] = row;
    }

    // Cuantas coinciden lo dice la respuesta, y es lo que mide la planilla
    // mientras se busca. Si no viene, queda lo unico que se sabe —hasta donde se
    // leyo— y la busqueda crece a medida que se baja, igual que una tabla cuya
    // estructura no dice cuantos registros tiene.
    if (isSearching) {
      _matches = _totalOf(data) ?? _paging.known;
    }

    _cached.remove(page);
    _cached.add(page);
    _trimCache(page);

    _status = _rows.isEmpty ? TableViewStatus.empty : TableViewStatus.ready;
    notifyListeners();
  }

  /// Cuantas filas coinciden, segun la respuesta de una pagina de registros, o
  /// `null` si no lo dice.
  static int? _totalOf(dynamic data) {
    if (data is! Map) return null;

    final total = data["total"] ?? data["TOTAL"];

    if (total is num) return total.toInt();
    return int.tryParse(total?.toString() ?? "");
  }
}

/// Si la estructura que acaba de llegar es la de antes con, a lo sumo, campos
/// nuevos **al final**.
///
/// Es lo que decide si los registros que ya se leyeron siguen sirviendo. Una
/// fila guardada es una lista de valores alineada a los campos de la estructura
/// (ver `TableViewModel.alignedTo`), asi que:
///
/// - Renombrar una columna o cambiarle el tipo no mueve ningun valor: los
///   FIELD_ID son los mismos y en el mismo orden.
/// - Agregar una columna al final solo deja las filas cortas, y esa celda se ve
///   vacia, que es exactamente lo que corresponde para un campo recien creado.
/// - Eliminar una columna, o que el backend devuelva los campos en otro orden,
///   corre todos los valores de lugar: ahi lo leido ya no se puede mostrar y hay
///   que volver a pedirlo.
///
/// Importa a partir de unos cuantos miles de registros: sin esto, tocar el
/// titulo de una columna tira las paginas que se estaban mirando y obliga a
/// bajar la tabla de nuevo.
bool fieldsGrewAtEnd(List<String> before, List<String> after) {
  if (after.length < before.length) return false;

  for (int index = 0; index < before.length; index++) {
    if (before[index] != after[index]) return false;
  }

  return true;
}

/// De que posicion vieja sale cada columna nueva, para reacomodar los registros
/// que ya se leyeron en vez de volver a pedirlos.
///
/// Es el rescate de lo que [fieldsGrewAtEnd] descarta. Una fila guardada es una
/// lista de valores alineada a los campos de entonces (ver
/// [TableViewModel.alignedTo]), asi que mover una columna de lugar —o
/// eliminarla— **no invalida lo leido**: los valores siguen ahi y lo unico que
/// cambio es por donde se los busca. Devolver ese mapa alcanza para dejar las
/// filas como si se las hubiera pedido con la estructura nueva.
///
/// Una columna que antes no estaba queda en `-1`, que se lee como celda vacia:
/// es lo que corresponde para un campo recien creado, donde todavia no hay nada
/// cargado.
///
/// Devuelve `null` cuando no se puede emparejar las dos listas y hay que volver
/// a leer: sin FIELD_ID no hay con que hacerlo, y con ids repetidos no se sabria
/// cual es cual. Tambien cuando no habia campos, porque ahi las filas leidas no
/// estan alineadas a ninguno.
///
/// Importa a partir de unos cuantos miles de registros: sin esto, arrastrar una
/// columna de lugar (o borrarla) tira las paginas que se estaban mirando y
/// obliga a bajar la tabla de nuevo.
List<int>? fieldsRemap(List<String> before, List<String> after) {
  if (before.isEmpty) return null;

  final position = <String, int>{};

  for (final (index, id) in before.indexed) {
    if (id.isEmpty) return null;
    if (position.containsKey(id)) return null;

    position[id] = index;
  }

  return [
    for (final id in after) id.isEmpty ? -1 : position[id] ?? -1
  ];
}

/// Cual de las paginas guardadas hay que descartar, o `null` si todavia entran
/// en el presupuesto.
///
/// Se descarta **la mas lejana** a [around], que es la que se acaba de leer, y
/// no la mas vieja: asi se mira una tabla —se baja, se sube un poco, se vuelve a
/// bajar— y lo que hay alrededor de donde se esta parado es lo que mas chances
/// tiene de volver a hacer falta. Descartar por antiguedad tiraria justo la
/// pagina de arriba cada vez que se baja una.
///
/// Vive aparte del servicio porque es la regla del cache y no tiene nada de red:
/// se prueba sola.
int? pageToForget(
  Iterable<int> cached, {
  required int around,
  required int budget
}) {
  if (cached.length <= budget) return null;

  int? farthest;
  int distance = -1;

  for (final page in cached) {
    final other = (page - around).abs();
    if (other <= distance) continue;

    distance = other;
    farthest = page;
  }

  return farthest;
}

/// La contabilidad de la lectura por tramos de una tabla: de a cuantos registros
/// se lee, que paginas se leyeron, cuales estan en camino, cuales fallaron y
/// donde termina la tabla.
///
/// Vive aparte del servicio porque es la regla del desplazamiento infinito y no
/// tiene nada de red: se prueba sola.
class TablePaging {
  /// Cuantos registros trae una pagina. No se sabe de antemano: lo dice la
  /// primera que llega, y con eso se traduce cualquier fila a su pagina.
  int _size = 0;

  /// Paginas leidas, en camino y fallidas.
  final Set<int> _read = {};
  final Set<int> _flight = {};
  final Set<int> _failed = {};

  /// Hasta que fila se leyo. Solo importa cuando la estructura no dice cuantos
  /// registros hay: ahi la tabla crece a medida que se la lee.
  int _known = 0;

  /// `true` cuando una pagina volvio corta o vacia: no hay mas registros debajo.
  bool _end = false;

  int get size => _size;
  int get known => _known;
  bool get atEnd => _end;

  /// `true` mientras haya algun tramo en camino.
  bool get isReading => _flight.isNotEmpty;

  /// Que pagina hay que pedir para tener la fila [index], o `0` si no hay nada
  /// que pedir: porque ya se leyo, porque ya esta en camino, porque fallo y no
  /// se reintenta sola, o porque esa fila esta pasado el final de la tabla.
  ///
  /// Pedirla la marca como en camino, asi la misma pagina no sale dos veces
  /// aunque se la pidan las cincuenta filas que se estan pintando. Quien la pide
  /// se compromete a cerrarla con [read] o con [failed].
  int request(int index) {
    if (index < 0) return 0;

    // Pasado el final no hay nada que pedir: esas filas son las que se escriben.
    if (_end && index >= _known) return 0;

    final page = pageOf(index);
    if (page <= 0) return 0;
    if (_read.contains(page)) return 0;
    if (_flight.contains(page) || _failed.contains(page)) return 0;

    _flight.add(page);
    return page;
  }

  /// En que pagina cae la fila [index]. Devuelve `0` mientras no se sepa de a
  /// cuantos registros se lee, salvo para la primera fila, que siempre esta en
  /// la pagina 1: es la que lo revela.
  int pageOf(int index) {
    if (_size > 0) return index ~/ _size + 1;
    return index == 0 ? 1 : 0;
  }

  /// Primera fila de la pagina [page].
  int startOf(int page) => _size > 0 ? (page - 1) * _size : 0;

  /// Anota que la pagina [page] llego con [rows] registros y devuelve el indice
  /// de la primera de sus filas.
  ///
  /// Una pagina corta —o vacia— es el final de la tabla: no hay mas que pedir
  /// por debajo de ella.
  int read(int page, int rows) {
    _flight.remove(page);
    _failed.remove(page);
    _read.add(page);

    if (_size == 0 && rows > 0) _size = rows;
    if (rows == 0 || rows < _size) _end = true;

    final start = startOf(page);
    _known = math.max(_known, start + rows);

    return start;
  }

  /// Anota que la pagina [page] no se pudo traer.
  ///
  /// No se reintenta sola: la planilla pide las filas que se ven en cada
  /// repintado y el error provoca uno, asi que sin esto una pagina que falla se
  /// pediria en un bucle. Se vuelve a intentar cuando el usuario lo pide
  /// ([retry]).
  void failed(int page) {
    _flight.remove(page);
    _failed.add(page);
  }

  /// Olvida los fallos para que las paginas que faltan se vuelvan a pedir.
  void retry() => _failed.clear();

  /// Olvida que la pagina [page] se leyo, para que se pueda volver a pedir.
  ///
  /// Lo usa el cache acotado al descartar una pagina lejana: sin esto la pagina
  /// quedaria marcada como leida y sus filas, ya borradas, no volverian nunca.
  /// No toca [_size] ni [_end]: de a cuantos se lee y donde termina la tabla no
  /// cambian porque se olvide un tramo.
  void forget(int page) {
    _read.remove(page);
    _failed.remove(page);
  }

  /// Olvida lo leido, no de a cuantos se lee: releer la tabla no cambia el
  /// tamaño de la pagina.
  void reset() {
    _read.clear();
    _flight.clear();
    _failed.clear();
    _known = 0;
    _end = false;
  }
}
