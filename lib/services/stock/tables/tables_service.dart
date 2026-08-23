import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_ready_model.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/toolkit.dart' show S;

/// Estado de la carga del listado de tablas (`GET /tables/list/`).
enum TablesStatus { idle, loading, ready, empty, error }

/// Como arranco una importacion ([TablesService.import]).
///
/// Es como **arranco** y no como termino porque una importacion ya no termina
/// dentro de la llamada: la tabla se crea en el acto y el resto —los tipos de
/// sus columnas, que los pone el backend, y sus filas, que se suben despues—
/// sigue en segundo plano (ver [TableImportStage]). De eso ya no se entera
/// quien la disparo sino el listado, que muestra en que anda cada tabla.
enum TableImportResult {
  /// La tabla se creo. Lo que falta sigue solo.
  started,

  /// El archivo elegido no es una planilla ni un CSV. No se subio nada.
  unsupported,

  /// No se creo nada. El error ya se mostro.
  failed
}

/// En que anda una importacion que sigue corriendo despues de que la tabla ya
/// existe ([TablesService.importStage]).
///
/// Las dos etapas son esperas de verdad —la primera de medio minuto largo, la
/// segunda lo que tarde en subir el archivo— y en las dos la tabla ya esta en
/// el listado, se puede abrir y esta a medio hacer: por eso se muestran en su
/// fila en vez de quedarse dentro del servicio.
enum TableImportStage {
  /// El backend le esta poniendo el tipo a las columnas del archivo y su
  /// columna de imagen. Hasta que avise ([TableReadyModel]) la tabla tiene
  /// todas sus columnas en `text` y ninguna fila.
  preparing,

  /// Las columnas ya estan tipadas: se estan subiendo las filas del archivo.
  loading
}

/// Nombre del campo del formulario con el que viaja el archivo en las dos
/// subidas de la importacion. Lo fija el backend (`multer().single("FILE")`):
/// con cualquier otro nombre el archivo no llega y la peticion se rechaza.
const String _kImportField = "FILE";

/// Cuanto se espera el aviso de que una tabla importada quedo lista antes de
/// subirle las filas igual.
///
/// No es lo que tarda el backend en prepararla —eso son unos treinta segundos—
/// sino el margen para que el aviso llegue: viaja por socket, y si la conexion
/// esta caida el evento se pierde y no llega nunca. Sin este tope la
/// importacion se quedaria esperando para siempre un archivo que ya esta
/// elegido y una tabla que ya existe.
const Duration _kReadyTimeout = Duration(minutes: 2);

/// Estado y comportamiento de las tablas de productos de la empresa activa.
///
/// Concentra las operaciones sobre las tablas: la lectura del listado, que
/// consume la seccion `inventory`, el alta de una tabla nueva y, sobre una que
/// ya existe, la edicion de su cabecera y su baja.
///
/// Las tres escrituras dejan la cache al dia sin volver a leer el listado, pero
/// no de la misma manera: el alta la invalida (`idle`), porque la tabla nueva
/// hay que ir a buscarla —el backend le puso el id, y si venia con plantilla,
/// tambien sus columnas—; la edicion y la baja corrigen la fila en memoria,
/// porque lo que cambio ya se sabe entero de este lado.
///
/// Se registra en el scope mas alto de la app (`initialBuilder`) con
/// `ChangeNotifierProvider` porque su estado —la cache del listado— debe
/// sobrevivir a la navegacion entre el listado y la pantalla de creacion.
///
/// La cache es por empresa: las tablas viajan atadas a la empresa activa (la
/// cabecera `business_id` que pone [useBusiness]), asi que al cambiar de empresa
/// el listado se recarga solo. Por eso [load] recibe el id de la empresa y no lo
/// deduce: mantiene al servicio desacoplado de `BusinessService`.
///
/// **Y ademas escucha.** La importacion es lo unico de aca que no termina
/// dentro de la llamada que la dispara: la tabla se crea en el acto y el
/// backend sigue preparandola por atras, asi que el servicio queda esperando su
/// aviso (`table/ready`, ver [TableReadyModel]) para subirle las filas y para
/// corregir el listado. Ese es tambien el motivo de que la escucha viva aca y
/// no en la pantalla: la importacion sobrevive a que se salga de la seccion.
class TablesService extends ChangeNotifier {
  TablesService() {
    // Se anota antes de que la conexion exista siquiera: el socket guarda los
    // oyentes y los engancha al abrirse, asi que no hay que esperar a nada ni
    // volver a anotarse despues de una reconexion.
    _unlisten = ConnectionService().on(TableReadyModel.event, _onReady);
  }

  TablesStatus _status = TablesStatus.idle;
  List<TableLiteModel> _tables = const [];

  /// Empresa para la que se cargo la cache actual. Si no coincide con la activa,
  /// [load] refresca aunque la cache este `ready`.
  String? _businessId;

  /// Baja del oyente de `table/ready`, para soltarlo al morir el servicio.
  void Function()? _unlisten;

  /// En que anda cada importacion que sigue corriendo, por id de tabla. Una
  /// tabla que no esta aca no tiene nada pendiente.
  final Map<String, TableImportStage> _importing = {};

  /// Importaciones esperando el aviso del backend, por id de tabla. Se completa
  /// cuando llega el evento de esa tabla, y se abandona por tiempo
  /// ([_kReadyTimeout]) si no llega nunca.
  final Map<String, Completer<TableReadyModel?>> _pending = {};

  TablesStatus get status => _status;
  List<TableLiteModel> get tables => List.unmodifiable(_tables);

  /// En que anda la importacion de la tabla [tableId], o `null` si no tiene
  /// ninguna corriendo. Lo mira cada fila del listado para avisar que esa tabla
  /// todavia se esta armando.
  TableImportStage? importStage(String tableId) => _importing[tableId];

  /// Carga las tablas de [businessId].
  ///
  /// Se cachea: una vez cargado, las siguientes visitas a la seccion no vuelven
  /// a pegarle al backend salvo que se pida [force], que cambie la empresa
  /// activa, o que un alta invalide la cache dejando el estado en `idle`.
  ///
  /// Un cambio de empresa manda siempre: no se lo frena ni una lectura en curso
  /// (que es de la empresa anterior) ni una cache `ready` (idem), y lo que
  /// hubiera cargado se suelta en el acto para que nadie llegue a leer las
  /// tablas de la otra empresa mientras llegan las de esta.
  ///
  /// Se lleva tambien las importaciones a medio hacer, que son de la empresa
  /// anterior: el socket se ata a una sola empresa por conexion, asi que
  /// cambiar de empresa deja al aviso que estaban esperando sin forma de
  /// llegar, y subirle las filas a esa tabla ya no seria posible —la peticion
  /// viaja con la empresa activa, que no es la dueña de la tabla—.
  Future<void> load(String businessId, {bool force = false}) async {
    final changed = _businessId != businessId;

    if (!changed) {
      if (_status == TablesStatus.loading) return;
      if (!force && _status == TablesStatus.ready) return;
    }

    if (changed) {
      _tables = const [];
      _abandon();
    }

    _businessId = businessId;
    _status = TablesStatus.loading;
    notifyListeners();

    final data = await api
        .get(path: "/tables/list/", version: "v1")
        .catchError((error) {
      if (kDebugMode) print("loadTables failed: $error");
      return null;
    });

    // Mientras la lectura viajaba se cambio de empresa: lo que llego es de la
    // anterior. Se descarta entero, tambien el error, porque la lectura que vale
    // es la que disparo el cambio y ya esta en camino.
    if (_businessId != businessId) return;

    if (data == null) {
      _status = TablesStatus.error;
      notifyListeners();
      return;
    }

    _tables = TableLiteModel.fromResponse(data);
    _status = _tables.isEmpty ? TablesStatus.empty : TablesStatus.ready;

    notifyListeners();
  }

  /// Alta de la estructura de una tabla contra `POST /tables/structure/`.
  ///
  /// La empresa dueña no viaja en [data]: va en la cabecera `business_id` que
  /// ponen las apis solas (ver `useBusiness` en `toolkit/api.dart`).
  ///
  /// Devuelve el identificador de la tabla creada. Ante un error muestra la
  /// bandera flotante y relanza, para que la pantalla apague su estado de carga.
  /// Al terminar bien invalida la cache del listado (`idle`) para que la proxima
  /// lectura traiga la tabla nueva.
  Future<String> create(BuildContext context, Map<String, dynamic> data) async {
    try {
      final response = await api.post(
        path: "/tables/structure/",
        version: "v1",
        data: data,
      );

      final id = _readId(response);

      // La tabla recien creada todavia no esta en la cache: se marca vencida
      // para que el listado la vuelva a pedir al abrirse.
      _status = TablesStatus.idle;

      return id;
    } catch (error) {
      // El error se registra siempre, incluso cuando se muestra al usuario: el
      // texto que llega a pantalla suele estar recortado y aca queda el crudo.
      if (kDebugMode) print("createTable failed: $error");

      if (context.mounted) _report(context, error);

      rethrow;
    }
  }

  /// Cambia el titulo y la descripcion de una tabla contra
  /// `PUT /tables/structure/`.
  ///
  /// La cache no se invalida: lo que cambio es lo unico que el listado muestra
  /// de esa tabla, asi que se reescribe la fila en memoria y el listado se
  /// repinta solo. Volver a pedir las tablas enteras para cambiar dos textos
  /// que ya se tienen seria una lectura de mas —y una espera de mas— por cada
  /// renombre.
  ///
  /// Las cantidades (columnas y registros) no se tocan: editar la cabecera no
  /// las cambia.
  ///
  /// Devuelve `true` si el cambio salio bien. Ante un error muestra la bandera
  /// flotante y devuelve `false`, con la fila como estaba.
  Future<bool> edit(
    BuildContext context,
    TableLiteModel table, {
    required String title,
    required String description
  }) async {
    if (table.id.isEmpty) return false;

    try {
      await api.put(
        path: "/tables/structure/",
        version: "v1",
        data: editTableRequest(
          id: table.id,
          title: title,
          description: description
        )
      );
    } catch (error) {
      if (kDebugMode) print("editTable failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    // La tabla puede haberse ido de la cache mientras el cambio viajaba (un
    // cambio de empresa, una recarga): entonces no hay fila que reescribir y lo
    // que se lea despues ya viene con el titulo nuevo.
    final index = _tables.indexWhere((current) => current.id == table.id);

    if (index >= 0) {
      _tables = List<TableLiteModel>.from(_tables)
        ..[index] = _tables[index].withText(
          title: title.trim(),
          description: description.trim()
        );

      notifyListeners();
    }

    return true;
  }

  /// Corrige el titulo y/o la descripcion de una fila del listado **sin
  /// escribir nada**.
  ///
  /// Es para los cambios que escribio otro: la pantalla de ajustes de una
  /// tabla edita contra su propio endpoint (`PUT /tables/details/`, ver
  /// `TableDetailService.edit`) porque es una edicion parcial, y despues avisa
  /// por aca para que el listado no siga mostrando el nombre viejo.
  ///
  /// Es lo mismo que hace [edit] con la cache despues de guardar, y por eso no
  /// invalida nada: lo que cambio es lo unico que el listado muestra de esa
  /// tabla, y ya se sabe entero de este lado.
  void applyText(String tableId, {String? title, String? description}) {
    if (tableId.isEmpty || (title == null && description == null)) return;

    final index = _tables.indexWhere((current) => current.id == tableId);

    // La tabla puede no estar en la cache: se cambio de empresa, o el listado
    // nunca se llego a leer (se entro por deep link). Lo que se lea despues ya
    // viene con el texto nuevo.
    if (index < 0) return;

    _tables = List<TableLiteModel>.from(_tables)
      ..[index] = _tables[index].withText(
        title: title?.trim(),
        description: description?.trim()
      );

    notifyListeners();
  }

  /// Baja de una tabla contra `DELETE /tables/structure/`.
  ///
  /// Se lleva la tabla, sus columnas y todo lo cargado en ella, asi que quien
  /// la llama tiene que haberlo confirmado antes: el servicio no pregunta.
  ///
  /// Como en la edicion, la cache se corrige en el acto —se saca la fila— en
  /// vez de invalidarse: la tabla que se elimino es la unica que cambio, y asi
  /// desaparece del listado sin que este parpadee cargando de nuevo. Si era la
  /// ultima, el listado pasa a `empty` y muestra su mensaje.
  Future<bool> remove(BuildContext context, TableLiteModel table) async {
    if (table.id.isEmpty) return false;

    try {
      await api.delete(
        path: "/tables/structure/",
        version: "v1",
        data: deleteTableRequest(id: table.id)
      );
    } catch (error) {
      if (kDebugMode) print("deleteTable failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    final remaining = _tables
      .where((current) => current.id != table.id)
      .toList();

    // Nada que sacar: la cache ya no era la que tenia esta tabla (se cambio de
    // empresa, o se recargo el listado mientras la baja viajaba).
    if (remaining.length == _tables.length) return true;

    _tables = remaining;

    // El estado sigue a lo que quedo: sin tablas, el listado tiene que mostrar
    // su mensaje de vacio y no una lista en blanco.
    if (_status == TablesStatus.ready && _tables.isEmpty) {
      _status = TablesStatus.empty;
    }

    notifyListeners();

    return true;
  }

  /// Importa una tabla desde una planilla o un CSV.
  ///
  /// **Son dos subidas del mismo archivo, con una espera en el medio**, porque
  /// asi lo parte el backend:
  ///
  /// 1. `POST /tables/import/structure/<formato>/` crea la tabla con las
  ///    columnas de la fila de encabezados y devuelve su id **en el acto**. No
  ///    guarda ni una fila de datos, y las columnas nacen todas en `text`: que
  ///    tipo tiene cada una no lo dice el encabezado, hay que mirar los valores
  ///    y preguntarle a un modelo, y eso el backend lo hace **detras de la
  ///    respuesta**. Cuando termina avisa por socket (`table/ready`, ver
  ///    [TableReadyModel]) y de paso deja puesta la columna de imagen.
  /// 2. `POST /tables/import/records/<formato>/` sube el archivo otra vez, ahora
  ///    contra esa tabla, y carga todo lo que hay debajo del encabezado. Las
  ///    columnas se emparejan **por nombre**, asi que esta pasada no depende de
  ///    en que orden quedaron los campos.
  ///
  /// **La segunda subida espera al aviso de la primera**, y eso no es prolijidad
  /// sino la unica forma de que la tabla quede bien: cada fila se guarda —y se
  /// indexa para la busqueda semantica— con el tipo que la columna tiene **en
  /// ese momento**. Subirlas antes las dejaria a todas como texto contra
  /// columnas que van a ser numeros, fechas o precios, y sin un solo vector
  /// generado: el backend no vuelve a pasar por ellas (normaliza con
  /// `reindex: false`, justamente porque cuenta con que las filas todavia no
  /// estan). Si el aviso no llega —la conexion en tiempo real esta caida— se
  /// sube igual pasado [_kReadyTimeout]: una tabla con los tipos a medio poner
  /// es mejor que una importacion que nunca termina.
  ///
  /// Por eso **la llamada vuelve apenas existe la tabla** y el resto sigue solo:
  /// entre las dos subidas hay medio minuto largo, y dejar la pantalla colgada
  /// de eso seria hacerle esperar a quien importa lo mismo que el backend
  /// decidio no hacerle esperar. En que anda cada una lo cuenta
  /// [importStage], que es lo que muestra el listado.
  ///
  /// El archivo viaja entero las dos veces: es el precio de que el backend no
  /// guarde nada entre una llamada y la otra, y a cambio no hay archivos a medio
  /// subir del otro lado si la segunda no sale.
  ///
  /// [headerRow] es cual de las filas del archivo trae los nombres de las
  /// columnas (1-based). Se manda siempre, aunque sea la primera, para no
  /// depender del valor por defecto del backend.
  ///
  /// A que endpoint se sube lo decide la extension ([importFormatOf]); un
  /// archivo que no sea planilla ni CSV no se sube (`unsupported`), porque no
  /// habria a cual de los dos mandarlo.
  ///
  /// Como el alta, invalida la cache del listado en cuanto la tabla existe —
  /// tambien si despues fallan las filas, porque la tabla vacia ya esta creada y
  /// tiene que aparecer.
  Future<TableImportResult> import(
    BuildContext context,
    File file, {
    int headerRow = 1
  }) async {
    final format = importFormatOf(file.path);
    if (format == null) return TableImportResult.unsupported;

    // Los dos avisos del final se arman **antes** de subir nada, con el unico
    // contexto que se sabe montado: el que queda es de una pantalla que para
    // entonces puede haberse ido, y no serviria ni para traducirlos.
    final done = S.of(context).import_table_done;
    final failure = S.of(context).import_table_partial;

    final name = importTableName(file.path);
    final String tableId;

    try {
      final response = await api.file(
        path: "/tables/import/structure/${format.segment}/",
        version: "v1",
        file: file,
        field: _kImportField,
        // Un nombre vacio no se manda: mandarlo taparia el que el backend saca
        // del archivo y la tabla nacería llamandose "table".
        data: {if (name.isNotEmpty) "NAME": name, "ROW": "$headerRow"}
      );

      tableId = _readId(response);
    } catch (error) {
      if (kDebugMode) print("importTableStructure failed: $error");

      if (context.mounted) _report(context, error);

      return TableImportResult.failed;
    }

    // La tabla ya existe aunque las filas todavia no: la cache vence aca y no
    // recien al final, para que un fallo de la segunda subida igual muestre la
    // tabla creada en vez de esconderla hasta la proxima recarga.
    _status = TablesStatus.idle;
    _importing[tableId] = TableImportStage.preparing;
    notifyListeners();

    // Sin `await` a proposito: lo que sigue es la espera del backend y la
    // segunda subida, y quien importo no tiene que quedarse mirandolas.
    unawaited(_importRecords(
      tableId: tableId,
      file: file,
      format: format,
      headerRow: headerRow,
      done: done,
      failure: failure
    ));

    return TableImportResult.started;
  }

  /// La segunda mitad de la importacion, la que corre sola: esperar a que el
  /// backend termine de preparar la tabla y recien ahi subirle las filas.
  ///
  /// Se avisa con la bandera flotante y no devolviendo nada porque para cuando
  /// esto termina la pantalla que lo disparo puede no existir; por eso tambien
  /// los textos llegan ya traducidos y la bandera se cuelga del navegador
  /// (`FloatFlag.of()` sin contexto).
  ///
  /// Se abandona sin ruido si la importacion dejo de estar anotada: eso pasa
  /// cuando se cierra la sesion o se cambia de empresa mientras se esperaba, y
  /// ahi ya no hay a que tabla subirle nada.
  Future<void> _importRecords({
    required String tableId,
    required File file,
    required ImportFormat format,
    required int headerRow,
    required String done,
    required String failure
  }) async {
    await _awaitReady(tableId);

    if (_importing[tableId] != TableImportStage.preparing) return;

    _importing[tableId] = TableImportStage.loading;
    notifyListeners();

    bool ok = true;

    try {
      await api.file(
        path: "/tables/import/records/${format.segment}/",
        version: "v1",
        file: file,
        field: _kImportField,
        data: {"TABLE_ID": tableId, "ROW": "$headerRow"}
      );
    } catch (error) {
      ok = false;

      if (kDebugMode) print("importTableRecords failed: $error");
    }

    if (_importing.remove(tableId) == null) return;

    if (ok) {
      FloatFlag.of().message(done);
    } else {
      FloatFlag.of().error(message: failure);
    }

    await _reload();
  }

  /// Espera el `table/ready` de [tableId], o se rinde pasado [_kReadyTimeout].
  ///
  /// Devuelve `null` cuando se rindio: no es un fallo del que haya que avisar
  /// —la tabla esta creada y el backend la preparo o no, pero eso ya no depende
  /// de aca— sino la señal de seguir sin el aviso.
  Future<TableReadyModel?> _awaitReady(String tableId) {
    final completer = Completer<TableReadyModel?>();
    _pending[tableId] = completer;

    return completer.future.timeout(_kReadyTimeout, onTimeout: () {
      _pending.remove(tableId);
      return null;
    });
  }

  /// El aviso de que una tabla quedo lista.
  ///
  /// Si es de una importacion que salio de aca, lo unico que hace es destrabar
  /// la espera: quien la sigue es [_importRecords], que despues de subir las
  /// filas recarga el listado una sola vez. Si no —la importo otro dispositivo,
  /// o se pidio normalizar la tabla desde otro lado— no hay a quien destrabar y
  /// lo unico que se puede hacer es traer el listado de nuevo: esa tabla acaba
  /// de ganar tipos y una columna mas.
  void _onReady(dynamic data) {
    final report = TableReadyModel.fromEvent(data);
    if (report.isEmpty) return;

    final pending = _pending.remove(report.id);

    if (pending != null) {
      if (!pending.isCompleted) pending.complete(report);
      return;
    }

    _reload();
  }

  /// Vuelve a leer el listado si tiene sentido volver a leerlo.
  ///
  /// Solo cuando ya hay uno cargado: si esta vencido (`idle`) o nunca se leyo,
  /// pedirlo aca seria una lectura para nadie —la seccion lo pide sola al
  /// abrirse— y alcanza con avisar, que es lo que saca de la fila el cartel de
  /// que la tabla se estaba armando.
  Future<void> _reload() {
    final businessId = _businessId;

    if (businessId == null ||
        (_status != TablesStatus.ready && _status != TablesStatus.empty)) {
      notifyListeners();
      return Future.value();
    }

    return load(businessId, force: true);
  }

  /// Vacia la cache. La llama el cierre de sesion, junto al resto de los
  /// servicios de la sesion.
  ///
  /// Se lleva tambien las importaciones a medio hacer, y eso es lo que las
  /// corta: la que estuviera esperando el aviso del backend ve que ya no esta
  /// anotada y se abandona sin subir nada. Subir las filas de una tabla de la
  /// sesion que se acaba de cerrar no llegaria a ningun lado.
  void clear() {
    _tables = const [];
    _status = TablesStatus.idle;
    _businessId = null;
    _abandon();
    notifyListeners();
  }

  @override
  void dispose() {
    _unlisten?.call();
    _unlisten = null;
    _abandon();
    super.dispose();
  }

  /// Suelta las importaciones pendientes: destraba a las que esperan (con
  /// `null`, que es "segui sin el aviso") y borra en que andaban, que es lo que
  /// las hace abandonar.
  void _abandon() {
    _importing.clear();

    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(null);
    }

    _pending.clear();
  }

  /// Muestra un error de una operacion sobre las tablas.
  ///
  /// Nunca se cae en silencio: si el error no trae nada mostrable, igual se
  /// avisa. Un `action` es una instruccion de navegacion (por ejemplo, sesion
  /// vencida): se relanza tal cual para que la maneje quien corresponda, asi que
  /// esta llamada puede no volver.
  ///
  /// Quien lo llama comprueba antes que la pantalla siga montada: con el arbol
  /// desmontado no hay a quien avisarle, y que decidir en ese caso —relanzar,
  /// devolver un resultado— es cosa de cada operacion.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Lee el identificador de la tabla de la respuesta del alta.
  ///
  /// El backend puede devolver el id pelado (`5`, `"5"`) o envuelto en un objeto
  /// (`{"id": 5}`), asi que se contemplan las dos formas antes de rendirse.
  String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["table_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The table was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The table was not created (empty response)"};
    }

    return response.toString();
  }
}
