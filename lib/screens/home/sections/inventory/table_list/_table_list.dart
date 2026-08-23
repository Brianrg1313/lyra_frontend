import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/create_table/_create_table.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'import_button.dart';
import 'table_card.dart';
import 'table_row.dart';

/// Tablas de productos: es el contenido de la seccion `inventory` del home.
///
/// Misma estructura que la lista de empresas: barra de busqueda arriba con las
/// acciones a la derecha (importar y crear) y el listado debajo. El listado sale
/// de [TablesService], que lee `GET /tables/list/` de la empresa activa.
///
/// La pantalla esta cortada en tres para que cada parte se repinte por su
/// cuenta: la barra de arriba no escucha nada y se dibuja una sola vez, el
/// cuerpo escucha al servicio (que es lo que cambia al cargar) y el listado
/// escucha solo lo que se escribio en el buscador. Por eso el texto de busqueda
/// llega como [ValueListenable] y no como estado de la pantalla: con `setState`
/// cada letra volveria a construir tambien la barra y sus botones.
class InventorySection extends StatefulWidget {
  const InventorySection({super.key});

  @override
  State<InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<InventorySection> {
  /// Lo que se escribio en el buscador del header, ya normalizado. La seccion no
  /// tiene el suyo: la barra de arriba es la misma para todas y busca sobre la
  /// que se este mirando. Solo lo escucha el listado.
  late final ValueListenable<String> _query;

  /// `true` mientras se esta eligiendo el archivo y creando la tabla con el.
  /// Solo lo escucha el boton de importar, que es el que lo muestra.
  ///
  /// No cubre la importacion entera: lo que sigue —que el backend tipe las
  /// columnas y que despues suban las filas— pasa con la tabla ya en el listado
  /// y se muestra en su fila, no en el boton, para que se pueda importar otra
  /// mientras tanto.
  final _importing = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery;

    // La carga notifica a los oyentes; se difiere al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _importing.dispose();
    super.dispose();
  }

  /// Pide las tablas de la empresa activa. El servicio cachea por empresa, asi
  /// que esta llamada no vuelve a pegarle al backend si ya estan cargadas.
  void _load({bool force = false}) => context.read<TablesService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding / 2),
    child: Column(children: [
      Row(children: [
        Expanded(child: TextMedium(
          S.of(context).inventory,
          bold: true,
          ellipsis: true
        )),
        SizedBox(width: AppSize.gap),
        ImportButton(action: _import, loading: _importing),
        SizedBox(width: AppSize.gap),
        Button(
          width: null,
          title: S.of(context).create_table,
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          action: _create
        )
      ]),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
      ),
      Expanded(child: _Body(
        query: _query,
        onCreate: _create,
        onRetry: () => _load(force: true)
      ))
    ])
  );

  /// Abre el modal de alta. La tabla se crea vacia (titulo, descripcion y
  /// color); al cerrarse el modal se recarga el listado para mostrarla.
  ///
  /// Si se creo una tabla, [TablesService.create] dejo la cache en `idle` y la
  /// recarga la repuebla; si se cancelo, la cache sigue `ready` y [_load]
  /// retorna sin pegarle al backend. La seccion no se desmonta al abrir el modal
  /// (queda por detras), asi que nadie mas dispararia esta recarga.
  Future<void> _create() async {
    await showModal(
      context: context,
      title: S.of(context).create_table,
      builder: (BuildContext context) => const CreateTableModal()
    );

    if (mounted) _load();
  }

  /// Importa una tabla desde un archivo: se elige la planilla en el dialogo del
  /// sistema y se sube.
  ///
  /// El dialogo ya viene filtrado a planillas y CSV ([pickImportFile]), asi que
  /// no hay nada que validar antes de subir; `unsupported` solo aparece si se
  /// escribio el nombre a mano en un dialogo que no filtra (Linux, macOS).
  ///
  /// **Esto termina antes que la importacion.** Lo que se espera aca es que la
  /// tabla exista, que es lo unico rapido: ponerle el tipo a sus columnas le
  /// lleva al backend medio minuto largo y recien despues se suben las filas
  /// (ver [TablesService.import]). Eso sigue solo, se ve en la fila de la tabla
  /// mientras dura y se avisa con una bandera cuando termina, salga bien o mal.
  ///
  /// El listado se recarga pase lo que pase: si la tabla se creo, el servicio
  /// dejo la cache vencida y [_load] la trae —vacia y a medio armar, que es como
  /// esta—; si no se creo nada, la cache sigue `ready` y la llamada no le pega
  /// al backend.
  ///
  /// El unico final que no se avisa desde aca es `failed`: ese error ya lo
  /// mostro el servicio con el del backend, que dice mas que un texto generico.
  Future<void> _import() async {
    if (_importing.value) return;

    // Se marca ocupado desde antes de abrir el dialogo y no recien al subir: el
    // dialogo es una ventana del sistema y mientras esta abierta el boton sigue
    // ahi, asi que sin esto un segundo clic abriria otro y terminarian entrando
    // dos tablas.
    _importing.value = true;

    final TableImportResult result;

    try {
      final file = await pickImportFile(
        label: S.of(context).import_table_file_type
      );

      // El dialogo se cerro sin elegir nada, o la seccion se fue mientras
      // estaba abierto (puede quedar abierta un buen rato).
      if (file == null || !mounted) return;

      result = await context.read<TablesService>().import(context, file);
    } finally {
      // Desmontada la seccion el notificador ya no existe: se lo libero en
      // [dispose] mientras el archivo viajaba.
      if (mounted) _importing.value = false;
    }

    if (!mounted) return;

    switch (result) {
      case TableImportResult.started:
        FloatFlag.of(context).message(S.of(context).import_table_started);
      case TableImportResult.unsupported:
        FloatFlag.of(context).error(
          message: S.of(context).import_table_unsupported
        );
      case TableImportResult.failed:
        break;
    }

    _load();
  }
}

/// El cuerpo del listado: lo unico que escucha a [TablesService], asi que
/// cargar, fallar o traer las tablas no vuelve a construir la barra de arriba.
class _Body extends StatelessWidget {
  const _Body({
    required this.query,
    required this.onCreate,
    required this.onRetry
  });

  final ValueListenable<String> query;
  final void Function() onCreate;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();

    return switch (service.status) {
      TablesStatus.loading || TablesStatus.idle => const Center(child: Loading()),
      TablesStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).product_tables_error_title,
        subtitle: S.of(context).product_tables_error_subtitle,
        action: onRetry,
        actionLabel: S.of(context).product_tables_retry,
        actionIcon: CI.plus
      ),
      TablesStatus.empty => SectionMessage(
        icon: CI.list,
        title: S.of(context).product_tables_empty_title,
        subtitle: S.of(context).product_tables_empty_subtitle,
        action: onCreate,
        actionLabel: S.of(context).create_table,
        actionIcon: CI.plus
      ),
      TablesStatus.ready => _List(tables: service.tables, query: query)
    };
  }
}

/// El listado filtrado. Escucha solo el buscador: escribir en el no toca ni la
/// barra ni el servicio, solo vuelve a filtrar estas tablas.
///
/// El filtro mira el titulo y la descripcion, igual que el de las conexiones:
/// una tabla se busca por como la llamo la empresa —"Precios mayoristas"— y esa
/// es tambien la unica frase donde puede estar la palabra que se recuerda.
///
/// Lo que se busca ya viene normalizado por [HomeService.search] (sin espacios
/// en los bordes y en minusculas), asi que aca solo se baja el texto de la
/// tabla.
class _List extends StatelessWidget {
  const _List({required this.tables, required this.query});

  final List<TableLiteModel> tables;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: query,
    builder: (context, value, _) {
      final filtered = value.isEmpty
        ? tables
        : tables.where((table) =>
            table.title.toLowerCase().contains(value) ||
            table.description.toLowerCase().contains(value)
          ).toList();

      // No es lo mismo que la seccion vacia: hay tablas, pero ninguna se llama
      // asi. Por eso no se ofrece crear una, que seria crearla con el nombre
      // que se estaba buscando.
      if (filtered.isEmpty) {
        return SectionMessage(
          icon: CI.search,
          title: S.of(context).product_tables_search_empty
        );
      }

      // En escritorio las tablas van en grilla y en telefono en filas: es el
      // mismo listado y las mismas opciones, repartido segun el ancho que hay.
      // Una fila a lo ancho de un monitor es un titulo corto y medio metro de
      // aire; una tarjeta en una pantalla de telefono no entra ni una por
      // renglon.
      //
      // El tablet va con la grilla: a ese ancho ya entran dos columnas.
      return DeviceSelector(
        phone: (context) => _Rows(tables: filtered),
        tablet: (context) => _Grid(tables: filtered),
        desktop: (context) => _Grid(tables: filtered)
      );
    }
  );
}

/// Las tablas en grilla, que es como se ven en escritorio.
///
/// Las columnas no son un numero fijo sino lo que entre: la grilla reparte el
/// ancho que tenga en tantas como quepan sin pasar de [TableCard.maxWidth], asi
/// que la misma pantalla muestra tres tablas por renglon con el side bar
/// abierto y cuatro con el cerrado, y todas terminan del mismo ancho.
///
/// El alto lo fija la tarjeta ([TableCard.height]) en vez de salir de una
/// proporcion: lo que se apila adentro mide lo que mide —dos lineas de
/// descripcion, un renglon de titulo—, y con `childAspectRatio` ese alto
/// dependeria del ancho de la ventana.
class _Grid extends StatelessWidget {
  const _Grid({required this.tables});

  final List<TableLiteModel> tables;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: EdgeInsets.zero,
    itemCount: tables.length,
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: TableCard.maxWidth,
      mainAxisExtent: TableCard.height,
      crossAxisSpacing: AppSize.gap,
      mainAxisSpacing: AppSize.gap
    ),
    itemBuilder: (context, index) => TableCard(table: tables[index])
  );
}

/// Las tablas en filas, que es como se ven en telefono: una debajo de la otra a
/// todo el ancho, que es todo lo que hay.
class _Rows extends StatelessWidget {
  const _Rows({required this.tables});

  final List<TableLiteModel> tables;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.zero,
    itemCount: tables.length,
    separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
    itemBuilder: (context, index) => TableListRow(table: tables[index])
  );
}
