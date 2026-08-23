import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

import 'agent_block.dart';
import 'channels_block.dart';
import 'columns_block.dart';
import 'columns_table.dart';
import 'summary_block.dart';

/// Abre los ajustes de [tableId] en el panel del costado.
///
/// Es la unica puerta a la ficha y por eso es una funcion y no dos llamadas
/// sueltas: se entra desde el menu de la tabla en el listado y desde el boton
/// de ajustes de la planilla, y las dos tienen que abrir lo mismo, del mismo
/// ancho y con el mismo titulo.
///
/// Va al costado y no en la caja centrada de siempre porque la ficha se lee
/// **contra la tabla**: se abre encima de donde se estaba —el listado o la
/// planilla— y eso sigue a la vista al lado, que es lo que se estaba mirando
/// cuando se quiso saber de que columnas esta hecha. En telefono no hay "al
/// lado" y [showSideModal] cae solo en la hoja de abajo.
///
/// El ancho se le dice al panel en vez de dejar que lo pida el contenido: la
/// ficha se acomoda con dos [LayoutBuilder] —uno parte la ficha en dos columnas
/// y otro parte cada fila de columnas en dos renglones— y un `LayoutBuilder` no
/// sabe contestar cuanto mide hasta que le dicen cuanto tiene. Con el ancho
/// minimo y el maximo iguales, el panel ya nace medido y nadie se lo pregunta a
/// lo de adentro.
Future<void> showTableSettings(BuildContext context, String tableId) async {
  // En una ventana angosta manda la ventana: el panel deja ver la pagina que
  // acompana, y uno de 600 sobre una de 900 la tapa entera.
  final width = math.min(
    _panelWidth,
    MediaQuery.of(context).size.width * .55
  );

  await showSideModal(
    context: context,
    title: S.of(context).table_settings_title,
    minWidth: width,
    maxWidth: width,
    builder: (BuildContext context) => TableSettingsModal(tableId: tableId)
  );
}

/// Ancho del panel en una ventana que da para el.
///
/// Sale de lo que necesita la tabla de columnas para no partirse: sus cinco
/// celdas entran a partir de `AppSize.action * 11` (ver [TableColumnsTable]), y
/// encima de eso van los dos margenes del panel y los dos de la ficha. El resto
/// es aire, para que el nombre de una columna no quede en un hilo entre tres
/// desplegables.
double get _panelWidth => AppSize.action * 13 + AppSize.padding * 4;

/// Los ajustes de una tabla: todo lo que hay que saber de ella **menos sus
/// filas**. Se abre con [showTableSettings], tanto desde el menu de la tabla en
/// el listado como desde el boton de ajustes de la planilla.
///
/// Contesta cinco preguntas:
///
/// 1. **Que es y que tan grande es** — el nombre, la descripcion, cuantos
///    registros, cuantas columnas y cuantos bots la leen.
/// 2. **Que ve el modelo** — cuanto de la tabla puede usar un bot que la lea.
/// 3. **Quien la esta leyendo** — los canales conectados, incluidos los que
///    llegan sin haberla elegido (ver [TableChannelsBlock]).
/// 4. **Cuando paso algo** — cuando se creo, cuando cambio su estructura por
///    ultima vez y cuando entro el ultimo dato. Son fechas distintas y se
///    muestran distintas (ver [TableDatesBlock]).
/// 5. **De que esta hecha** — sus columnas, una por una, con su tipo y su
///    visibilidad (ver [TableColumnsBlock]).
///
/// Las fechas van despues de los canales porque son el dato de consulta de la
/// ficha: se las busca cuando ya se sabe que se esta buscando —hace cuanto no
/// entra un registro, cuando se toco la estructura—, mientras que las dos
/// anteriores son las que se miran al entrar sin buscar nada.
///
/// Las columnas van al final y solas, y no porque sean lo ultimo que importa:
/// son una tabla de cinco celdas por fila y necesitan el ancho entero del
/// panel. Metidas en una de las dos mitades quedarian con trescientos pixeles
/// para el nombre de la columna, su tipo, su visibilidad y sus opciones.
///
/// Se lee todo de una sola peticion (`GET /tables/details/<id>`): el endpoint
/// junta lo que vive en tres bases distintas justamente para que esta ficha no
/// tenga que hacer tres viajes. Es una lectura cara y por eso **no esta en la
/// estructura** que dibuja la planilla, que se pide en cada clic.
///
/// Lo que se **escribe** desde aca se escribe en el renglon donde se lee, sin
/// formularios de por medio: los dos textos que alguien redacta —el titulo y la
/// descripcion, ver [TableSummaryBlock]— y, de cada columna, su tipo, su
/// visibilidad y las opciones de su lista (ver [TableColumnsTable]). Son los
/// datos que se miran comparando la tabla entera, y por eso se corrigen donde
/// se los comparo y no abriendo la planilla columna por columna.
///
/// Lo que no se escribe aca sigue editandose donde se lo ve: los valores de las
/// filas en la propia planilla, de que tabla lee un bot desde el bot.
///
/// Cual tabla llega por constructor y no de la URL: el panel se monta encima de
/// la pagina y no en su lugar, asi que la direccion sigue siendo la de lo que
/// hay debajo —el listado o la planilla— y no dice nada de que ficha se abrio.
///
/// Tampoco escucha el cambio de empresa, a diferencia de las pantallas atadas a
/// un id: mientras el panel esta abierto el selector queda detras de su velo,
/// asi que la tabla que se esta mirando no puede dejar de ser de la empresa
/// activa.
///
/// El servicio ([TableDetailService]) lo posee este panel y no el scope de la
/// app: es el estado de una tabla que se esta mirando, y ademas es justamente
/// lo que no conviene cachear —se abre esto para ver como esta la tabla ahora,
/// no como estaba la vez pasada—.
class TableSettingsModal extends StatefulWidget {
  const TableSettingsModal({super.key, required this.tableId});

  final String tableId;

  @override
  State<TableSettingsModal> createState() => _TableSettingsModalState();
}

class _TableSettingsModalState extends State<TableSettingsModal> {
  // Propio del panel: se crea al abrirlo y se libera al cerrarlo. Ver la nota
  // de la clase sobre por que no se cachea.
  final _service = TableDetailService();

  @override
  void initState() {
    super.initState();

    // La carga se difiere al primer frame para no notificar mientras el arbol
    // se monta, igual que el resto de las pantallas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _service.load(widget.tableId);

      // El catalogo de redes es lo que le pone nombre e icono a cada canal que
      // lee la tabla. Se cachea para toda la sesion, asi que si ya se visito la
      // seccion de canales esto no le pega al backend, y si falla la lista se
      // dibuja igual con el codigo crudo de la red.
      context.read<ChannelCatalogService>().load();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider<TableDetailService>.value(
      value: _service,
      child: Column(children: [
        _Header(tableId: widget.tableId),
        SizedBox(height: AppSize.gap),
        const Expanded(child: _Body())
      ])
    );
}

/// De que tabla son estos ajustes, y el boton de releerlos.
///
/// El nombre va aca dentro y no en el titulo del panel porque **cambia desde la
/// propia ficha**: se lo renombra en el primer renglon (ver [TableSummaryBlock])
/// y un titulo que se le paso al panel al abrirlo se quedaria con el viejo.
/// Arriba queda lo que no cambia —que esto son los ajustes de una tabla— y aca,
/// cual.
///
/// El nombre lo da el detalle, que es el que trae el de verdad; hasta que llega
/// se muestra el que ya tenia cacheado el listado de tablas y, si tampoco esta
/// (se abrio la ficha con el listado sin cargar), uno generico. Es el mismo
/// camino que hace el encabezado de la planilla, y por lo mismo: la ficha se
/// dibuja con el nombre puesto en vez de estrenarlo un frame mas tarde.
class _Header extends StatelessWidget {
  const _Header({required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final cached = context.select<TablesService, String>(
      (tables) => _cachedTitle(tables.tables, tableId)
    );

    // Del servicio se lleva **texto ya resuelto** y no el detalle: lo demas que
    // trae —veinte columnas, los canales— no dice nada de esta barra, y con el
    // objeto se repintaria por todo.
    final (name, color, reloading) = context
      .select<TableDetailService, (String, Color?, bool)>(
        (service) => (
          service.detail.name,
          service.detail.tint,
          service.isReloading
        )
      );

    final title = name.isNotEmpty
      ? name
      : cached.isNotEmpty ? cached : S.of(context).product_table_view_title;

    return Row(children: [
      if (color != null) ...[
        Container(
          width: AppSize.text * 0.75,
          height: AppSize.text * 0.75,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)
        ),
        SizedBox(width: AppSize.spaceXS)
      ],
      Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
      SizedBox(width: AppSize.spaceS),
      // Mientras se relee, el boton deja lugar al spinner: son la misma cosa en
      // dos momentos, y dejar los dos correria la barra entera.
      if (reloading)
        SizedBox(
          width: AppSize.action,
          height: AppSize.action,
          child: Center(child: SizedBox(
            width: AppSize.text,
            height: AppSize.text,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          ))
        )
      else
        FeedbackButton(
          action: context.read<TableDetailService>().refresh,
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).table_settings_refresh,
          child: Center(child: Icon(
            Icons.refresh,
            size: AppSize.spaceM,
            color: scheme.text.primary
          ))
        )
    ]);
  }

  /// Titulo de la tabla segun el listado cacheado, o vacio si todavia no esta
  /// cargado.
  static String _cachedTitle(List<TableLiteModel> tables, String id) {
    for (final table in tables) {
      if (table.id == id && table.title.isNotEmpty) return table.title;
    }
    return "";
  }
}

/// El cuerpo, que depende solo del estado de la unica lectura de la ficha.
///
/// Sin detalle no hay ficha que dibujar —todo lo que muestra sale de el— asi
/// que la espera es el panel en blanco y el error lo ocupa entero, con la
/// relectura como salida. Una **relectura** no pasa por aca: se avisa arriba y
/// lo que hay se queda donde esta.
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    // El detalle va en el mismo `select` que el estado y no se lee aparte: una
    // relectura deja el estado en `ready` y cambia solo el objeto, asi que
    // mirando el estado a secas la ficha se quedaria con la lectura anterior.
    final (status, detail) = context
      .select<TableDetailService, (TableDetailStatus, TableDetailModel)>(
        (service) => (service.status, service.detail)
      );

    return switch (status) {
      TableDetailStatus.idle || TableDetailStatus.loading =>
        const Center(child: Loading()),
      TableDetailStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).table_settings_error_title,
        subtitle: S.of(context).table_settings_error_subtitle,
        action: context.read<TableDetailService>().retry,
        actionLabel: S.of(context).product_tables_retry
      ),
      TableDetailStatus.ready => _Details(detail: detail)
    };
  }
}

/// La ficha: arriba, dos mitades que se leen por separado —**que es esta
/// tabla** (que tiene, cuando cambio) y **para que se esta usando** (cuanto ve
/// el modelo, quien la lee)— y debajo, ocupando el ancho entero, de que
/// columnas esta hecha.
///
/// En el panel las dos mitades se apilan en el orden de arriba leido de
/// corrido, que es el orden en que se hacen las preguntas; el corte en dos
/// sigue estando para el ancho en que las dos entran, que es el de la ventana
/// entera.
///
/// Las columnas van abajo y sin partir porque son una tabla, no un dato: cinco
/// celdas por fila necesitan el ancho entero, y ademas son tan largas como
/// columnas tenga la tabla, asi que arriba empujarian todo lo demas fuera de la
/// pantalla.
class _Details extends StatelessWidget {
  const _Details({required this.detail});

  final TableDetailModel detail;

  /// Ancho a partir del cual la ficha se abre en dos columnas. El mismo del
  /// formulario de un canal: es el ancho en el que dos columnas de datos se
  /// siguen leyendo.
  static double get _twoColumns => AppSize.action * 16;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // El aire de la ficha lo pone el scroll y no un `Padding` por afuera: la
      // barra tiene que quedar contra el borde, no dentro del margen. Por eso
      // se descuenta aca antes de partir en columnas.

      // Un ancho sin medida no puede pasar a las mitades: se toma el minimo
      // para partir, que deja una sola columna.
      final available = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _twoColumns - 1;

      final split = available >= _twoColumns;

      // Al piso: dos mitades que sumen un pelo mas que el ancho por el
      // redondeo del punto flotante no entran en la misma fila, y el [Wrap]
      // baja la segunda —una columna cuando habia lugar para dos—.
      final column = split
        ? ((available - AppSize.spaceM) / 2).floorToDouble()
        : available;

      return ScrollableWidget(
        showBar: false,
        children: [
          Wrap(
            spacing: AppSize.spaceS,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(width: column, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TableSummaryBlock(detail: detail)]
              )),
              SizedBox(width: column, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TableAgentBlock(detail: detail),
                  TableChannelsBlock(detail: detail),
                  TableDatesBlock(detail: detail)
                ]
              ))
            ]
          ),
          TableColumnsBlock(detail: detail)
        ]
      );
    }
  );
}
