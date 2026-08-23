import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'sheet.dart';
import 'table_header.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_cursor.dart';
import 'state/sheet_dates.dart';
import 'state/sheet_drafts.dart';
import 'state/sheet_hover.dart';
import 'state/sheet_metrics.dart';
import 'state/sheet_widths.dart';

/// Vista de una tabla y sus datos como una planilla de calculo. Es una
/// sub-pagina de la seccion `inventory` (`parents: ["inventory"]`): se abre al
/// tocar una fila del listado de tablas y comparte el shell del home, por lo que
/// la opcion del side bar sigue marcada.
///
/// La grilla imita a un Excel y no a una tabla de datos: **las celdas ya estan**.
/// No hay que pedir una fila nueva para cargar algo; debajo de los registros
/// siempre sobran filas en blanco (las que entren en pantalla, y nunca menos de
/// unas pocas), asi que cargar es tocar una celda y escribir.
///
/// La primera fila **siempre son los campos**: es la fila 1 de la planilla, con
/// el nombre y el icono del tipo de cada columna. No es un encabezado decorativo
/// sino la fila 1 real, por eso el primer registro es la fila 2, igual que en una
/// planilla donde la primera fila lleva los titulos. Queda congelada arriba, y a
/// la izquierda queda congelada la columna de numeros de fila.
///
/// El resto de las filas son los registros:
/// - Las de arriba son los datos que ya vinieron del backend, y **se corrigen
///   donde se los ve**: se toca la celda, se escribe y al salir el cambio viaja
///   (`PUT /products/manage/`) sin volver a leer la tabla ni moverse de donde se
///   estaba. Viaja solo la celda que se toco, no la fila entera. Lo unico que no
///   se escribe es lo que todavia no llego: una fila cuyo tramo no entro se
///   recorre, pero no se sabe que tiene ni cual es. Son tantas como registros
///   tenga la tabla, se hayan leido o no: la planilla nace con su largo
///   definitivo y cada tramo se pide cuando esta por entrar en pantalla, asi que
///   bajando se sigue de largo sin botones de paginado ni cortes.
/// - Las de abajo estan vacias y son editables. En cuanto se escribe en una, esa
///   fila pasa a ser un borrador, y **al salir de la fila se guarda sola**
///   (`POST /products/manage/`): no hay tilde, ni boton, ni nada que confirmar.
///   Se guarda al dejar la fila y no al dejar cada celda porque una fila se
///   escribe de a varias columnas: recorrerla con Tab no manda nada y al salir
///   viaja entera, que es un alta y no una por columna. Mientras el alta viaja,
///   el numero de esa fila deja lugar a un spinner y la fila no se escribe; si
///   no sale, se queda escrita tal cual y se reintenta con solo volver a salir
///   de ella.
///
/// La navegacion tambien es la de una planilla: Tab / Shift+Tab se mueven de
/// celda, Enter y las flechas arriba/abajo bajan y suben, Escape cancela lo que
/// se estaba escribiendo. Llegar al final con Tab salta al principio de la fila
/// siguiente, y pasarse de la ultima fila agrega otra en blanco.
///
/// La tabla crece sola en los dos ejes, sin botones de "agregar":
/// - **Horizontal**: al final siempre sobran columnas libres. Poner un titulo en
///   una la crea (`POST /tables/fields/`) y aparece otra libre detras.
/// - **Vertical**: escribiendo en las filas en blanco del final.
///
/// El **ancho de cada columna** se arrastra desde el borde derecho de su celda
/// de campo, y al soltar se guarda con el campo (`PUT /tables/fields/`, sin
/// volver a pedir la tabla). No es una preferencia de quien lo arrastro: es como
/// queda la tabla, asi que la proxima vez que se la abra —la abra quien la
/// abra— las columnas miden eso. Lo trae la estructura con los campos, de modo
/// que la planilla se dibuja ya acomodada en el primer frame en vez de saltar
/// despues.
///
/// Las columnas tambien se **arrastran de lugar** desde su celda de campo, como
/// en una planilla: se agarra el titulo, una linea marca donde va a caer y al
/// soltar la columna se muda ahi con su ancho puesto. El orden nuevo se ve al
/// instante y las posiciones viajan detras (`PUT /tables/fields/`), sin volver a
/// pedir la tabla: los registros leidos **no se mueven de donde estan** —lo
/// unico que cambia es de que lugar de la fila lee cada columna—, asi que
/// arrastrar una columna cuesta lo mismo en una tabla de diez registros que en
/// una de cientos de miles.
///
/// La celda de un campo se sigue comportando como una celda despues de creado,
/// asi que **el campo se edita donde se lo ve** y no en un formulario aparte:
/// escribirle otro titulo lo renombra al salir de la celda, la flecha le cambia
/// el tipo y **vaciarle el titulo lo elimina**, que es lo unico que no se hace
/// solo: antes se pide confirmacion, porque se lleva la columna y todo lo
/// cargado en ella.
///
/// Cual tabla se resuelve del id en la URL (`/home/inventory/:id`), no por
/// constructor: la sub-pagina reusa la unica pagina del shell y el `Navigator`
/// no reconstruye el arbol al navegar, asi que el id se lee de
/// [Navis.currentArgs].
///
/// La tabla se abre en dos fases (ver [TableViewService]) y la planilla las
/// muestra como lo que son:
/// - **La estructura** (`GET /tables/structure/<id>`) es lo que se espera con la
///   pantalla en blanco: sin columnas no hay planilla que dibujar, asi que si
///   falla lo que se ve es el error a pantalla completa.
/// - **Los datos** (`POST /tables/records/`) llegan despues y sobre una planilla
///   ya dibujada: se piden de a tramos a medida que se baja, sin tapar nada, y
///   tanto su espera como su error se avisan en la barra de arriba.
///
/// **El buscador del header busca en la tabla.** Es uno solo para todo el home y
/// busca sobre la seccion que se este mirando ([HomeService.searchQuery]); en
/// esta, la planilla pasa a mostrar las filas que mencionan lo que se escribio,
/// en cualquiera de sus columnas ([_onSearch]).
///
/// Filtra el backend y no la planilla (`MATCH`, ver [TableViewService.search]):
/// de una tabla de cientos de miles de filas en memoria hay unos tramos, asi que
/// esconder las que no coinciden buscaria en lo que se miro y no en la tabla. Lo
/// que se pide ya viene filtrado, contado y paginado, y por eso buscar se
/// recorre como cualquier tabla: bajando entran los tramos siguientes del
/// resultado.
///
/// Una planilla filtrada **no tiene filas en blanco al final**: no es donde se
/// carga. Lo que se escribiera ahi nace sin lo que se busco, asi que se iria de
/// la pantalla en la que se lo escribio, y el lugar donde se lo escribio tampoco
/// es un lugar de la tabla —las filas de una busqueda estan salteadas—. Para
/// cargar se vacia el buscador, que devuelve la tabla entera. Lo que si se puede
/// es **corregir lo que se encontro**: una celda de un resultado se escribe como
/// cualquier otra, que es media razon para buscar.
///
/// Una tabla recien importada se sigue armando **con la pantalla abierta**, y de
/// eso se entera por dos caminos distintos, porque son dos cosas distintas: que
/// sus columnas ya tengan tipo lo avisa el backend por socket y lo escucha
/// [TableViewService], que vuelve a leer la tabla donde este; que sus filas ya
/// hayan entrado lo sabe [TablesService], que es quien las sube, y por eso esta
/// pantalla lo escucha a el ([_onImport]). Hasta que las dos cosas pasen, la
/// barra de arriba dice en que anda.
///
/// ---
///
/// **Como se reparte el repintado.** La pantalla esta pensada para tablas de
/// cientos de miles de registros, asi que ningun cambio puede costar la grilla
/// entera. Este widget no escucha nada: crea el servicio y el [SheetController],
/// los publica y no se vuelve a construir. De ahi para abajo cada parte se
/// suscribe a lo suyo y nada mas:
///
/// | Se toca | Se vuelve a construir |
/// |---|---|
/// | Se mueve el cursor | 2 filas (la que se deja y la que se toma) |
/// | Se pasa el mouse a otra fila | 2 filas |
/// | Se cambia el formato de una columna de fechas | las celdas de esa columna |
/// | Se arrastra un ancho | las celdas de esa columna |
/// | Se arrastra una columna de lugar | nada, hasta soltarla |
/// | Entra un tramo de registros | las filas de ese tramo |
/// | Se escribe en una celda | esa celda y, si la fila cambio de estado, su fila |
/// | Se guarda sola una fila | esa fila y su numero |
/// | Se corrige una celda de un registro | esa fila |
/// | Se renombra una columna | la celda de ese campo |
/// | Se le cambia el tipo a una columna | la celda de ese campo y las de su columna |
/// | Se agrega, se borra o se suelta una columna | la grilla |
/// | Se busca algo en el header | la grilla (son otras filas) |
///
/// Los tres ultimos releen la estructura entera de la tabla, y aun asi solo el
/// ultimo cuesta la grilla: lo que la planilla escucha es **la forma** de las
/// columnas ([SheetColumns.shape]), que no cambia por un titulo ni por un tipo.
///
/// Y ninguno de los tres desmonta la pantalla. Una relectura de estructura sobre
/// una tabla ya dibujada no vuelve a [TableStructureStatus.loading]: se avisa en
/// la barra de arriba y la planilla se queda donde esta, con su desplazamiento y
/// con lo que se estuviera escribiendo. Sin eso, agregar una columna en la fila
/// cincuenta mil obligaba a volver a bajar hasta ahi.
///
/// El servicio ([TableViewService]) lo posee esta pantalla y no el scope de la
/// app: es estado efimero de una tabla abierta (su estructura y los tramos que
/// se estan mirando), que debe reiniciarse cada vez que se entra y descartarse
/// al salir.
class TableViewSection extends StatefulWidget {
  const TableViewSection({super.key});

  /// Key de la ruta de esta sub-pagina. Es la unica fuente: la usan tanto la
  /// tabla de rutas como el shell para decidir cuando mostrarla.
  static const String routeKey = "inventory_table_view";

  @override
  State<TableViewSection> createState() => _TableViewSectionState();
}

class _TableViewSectionState extends State<TableViewSection>
    with BusinessListener<TableViewSection> {
  // Propio de la pantalla: se crea al entrar y se libera al salir, sin pasar por
  // un provider de la app, porque su estado (los tramos abiertos) no debe
  // sobrevivir a la navegacion.
  final _service = TableViewService();

  late final SheetController _controller;
  late final String _tableId;

  /// El listado de tablas, que es quien lleva las importaciones en curso. Se
  /// guarda la instancia porque hay que darse de baja de ella en [dispose], y
  /// para entonces el contexto ya no sirve para buscarla.
  late final TablesService _tables;

  /// En que andaba la importacion de esta tabla la ultima vez que se miro. Es
  /// para reaccionar a que **cambie**, y no a cada aviso del listado.
  TableImportStage? _stage;

  /// Lo que se escribio en el buscador del header. Es el mismo buscador para
  /// todo el home y busca sobre la seccion que se este mirando: en esta, sobre
  /// las filas de la tabla abierta.
  ///
  /// Se guarda la referencia por lo mismo que el listado de tablas: hay que
  /// darse de baja en [dispose], y para entonces el contexto ya no sirve para
  /// buscar el servicio.
  late final ValueListenable<String> _query;

  @override
  void initState() {
    super.initState();

    // El id vive en la URL.
    _tableId = Navis.currentArgs?["id"] ?? "";

    _tables = context.read<TablesService>();
    _stage = _tables.importStage(_tableId);
    _tables.addListener(_onImport);

    _query = context.read<HomeService>().searchQuery;
    _query.addListener(_onSearch);

    _controller = SheetController(
      service: _service,
      metrics: SheetMetrics(
        rowHeight: AppSize.action,
        gutterWidth: AppSize.action
      ),
      widths: SheetWidths(
        defaultWidth: AppSize.action * 3.5,
        minWidth: AppSize.action * 1.5,
        maxWidth: AppSize.action * 16
      ),
      // El controlador vive mas que cualquier `build`, asi que el contexto se le
      // pasa como funcion y no como valor.
      context: () => context
    );

    // La carga se difiere al primer frame para no notificar mientras el arbol se
    // monta, igual que el resto de las secciones.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.open(_tableId, query: _query.value);
    });
  }

  /// La tabla abierta es de la empresa que estaba activa: su id no significa
  /// nada en la que se acaba de elegir, asi que quedarse seria pedir una tabla
  /// que esta empresa no tiene. Se vuelve al listado, que es lo unico que se
  /// puede mostrar de la empresa nueva.
  ///
  /// Se navega en el acto —sin esperar al proximo frame— para que la pantalla se
  /// vaya antes de que el shell la vuelva a montar: si no, se pediria la
  /// estructura de esa tabla contra la empresa nueva solo para mostrar un error.
  @override
  void onBusinessChanged(String businessId) =>
    Navis.push(context, "/home/inventory");

  /// La importacion de esta tabla termino de subir sus filas: hay que volver a
  /// leerla entera.
  ///
  /// Es lo unico que el servicio de la tabla no puede escuchar por su cuenta.
  /// El aviso del backend (`table/ready`) llega **antes** que las filas —dice
  /// que las columnas ya tienen tipo, que es justo lo que hay que saber para
  /// empezar a subirlas— asi que la relectura que dispara encuentra la tabla
  /// todavia vacia. Quien sabe cuando entraron las filas es el listado, que es
  /// el que las sube.
  ///
  /// Se mira el paso anterior y no solo el de ahora porque `null` tambien es lo
  /// que hay cuando esta tabla nunca se importo desde aca, que es el caso
  /// normal y no tiene nada que releer.
  void _onImport() {
    final stage = _tables.importStage(_tableId);
    if (stage == _stage) return;

    final before = _stage;
    _stage = stage;

    if (before == TableImportStage.loading && stage == null) _service.refresh();
  }

  /// Se escribio (o se borro) algo en el buscador del header: la planilla pasa a
  /// mostrar las filas que lo mencionan, o la tabla entera al vaciarlo.
  ///
  /// El header ya espera a que se deje de escribir antes de avisar, asi que esto
  /// corre por busqueda y no por tecla, y el servicio ademas ignora un texto
  /// igual al que ya tenia: volver a la pantalla o cambiar de empresa no vuelve
  /// a pedir la tabla por una busqueda que no cambio.
  ///
  /// El cursor se lleva a la primera celda porque las filas de abajo son otras:
  /// dejarlo donde estaba lo dejaria sobre la fila que ahora ocupa ese lugar, que
  /// no es la que se estaba mirando.
  void _onSearch() {
    // Irse de la pantalla vacia el buscador (lo hace el header, ver
    // [HomeHeader]), y ese aviso llega con esta todavia montada: sin la guarda,
    // salir de una tabla buscando la volveria a pedir entera para desmontarla
    // acto seguido.
    if (Navis.currentKey.value != TableViewSection.routeKey) return;

    _controller.reset();
    _service.search(_query.value);
  }

  @override
  void dispose() {
    _query.removeListener(_onSearch);
    _tables.removeListener(_onImport);
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  // Se usa `.value` en todos: los notificadores no son de los providers sino del
  // controlador, que es quien los crea y los libera. Un provider que los
  // liberara por su cuenta los mataria en el primer rebuild de la pantalla.
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<SheetController>.value(value: _controller),
      Provider<SheetWidths>.value(value: _controller.widths),
      ChangeNotifierProvider<TableViewService>.value(value: _service),
      ChangeNotifierProvider<SheetCursor>.value(value: _controller.cursor),
      ChangeNotifierProvider<SheetColumns>.value(value: _controller.columns),
      ChangeNotifierProvider<SheetDrafts>.value(value: _controller.drafts),
      ChangeNotifierProvider<SheetHover>.value(value: _controller.hover),
      ChangeNotifierProvider<SheetDates>.value(value: _controller.dates)
    ],
    child: Surface(child: Column(children: [
      TableHeader(tableId: _tableId),
      Separator.horizontal(),
      const Expanded(child: _Body())
    ]))
  );
}

/// Lo que se ve depende solo de la **primera** fase: la estructura es la que
/// dice cuales son las columnas, y sin ellas no hay planilla que dibujar.
///
/// Una vez que llego, la grilla se queda quieta: la lectura de los registros y
/// todo lo que venga despues (guardar una fila, agregar una columna) se avisa en
/// la barra de arriba, sin tapar lo que se estaba escribiendo. Una tabla sin
/// ningun campo tampoco es un callejon sin salida: se muestra la planilla vacia,
/// que ya trae sus columnas libres para escribir el primer titulo encima.
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final status = context.select<TableViewService, TableStructureStatus>(
      (service) => service.structureStatus
    );

    return switch (status) {
      TableStructureStatus.idle || TableStructureStatus.loading =>
        const Center(child: Loading()),
      TableStructureStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).product_table_view_error_title,
        subtitle: S.of(context).product_table_view_error_subtitle,
        action: context.read<TableViewService>().retry,
        actionLabel: S.of(context).product_tables_retry
      ),
      TableStructureStatus.ready => const Sheet()
    };
  }
}
