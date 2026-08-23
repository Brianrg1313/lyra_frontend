import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'channel_row.dart';

/// Panel derecho de la seccion de canales: los canales de la empresa.
///
/// Conectar uno nuevo abre su propia pagina ([ChannelFormSection]) y no un
/// modal: el formulario es largo —el tipo de canal, que hace el agente, de donde
/// saca los datos, que herramientas usa y las credenciales de la red— y las
/// credenciales se copian y pegan desde otra ventana.
///
/// El buscador es de este panel y no el del header porque el panel es angosto:
/// un campo de texto fijo arriba se comeria el ancho que necesita el nombre de
/// cada canal, asi que se lo esconde detras de un boton y solo aparece cuando se
/// va a buscar. Como es propio, tambien busca solo aca: el de arriba sigue
/// siendo el de la app.
///
/// El panel esta cortado en tres para que cada parte se repinte por su cuenta:
/// la barra de arriba solo cambia al abrir y cerrar el buscador, el cuerpo
/// escucha al servicio (que es lo que cambia al cargar) y el listado escucha
/// solo lo que se escribio. Por eso el texto de busqueda es un [ValueNotifier] y
/// no estado de la pantalla: con `setState` cada letra volveria a construir
/// tambien la barra y sus botones.
class ChannelListPanel extends StatefulWidget {
  const ChannelListPanel({super.key});

  @override
  State<ChannelListPanel> createState() => _ChannelListPanelState();
}

class _ChannelListPanelState extends State<ChannelListPanel> {
  /// El buscador vive lo que vive el panel, asi que su controlador es de esta
  /// pantalla y no del input que lo dibuja: el campo se monta y se desmonta cada
  /// vez que se abre y se cierra la busqueda.
  ///
  /// Por eso se crea con un form propio: sin el, `InputController.search()` arma
  /// uno marcado como `controlledByInput` y entonces [SearchInput] se toma por
  /// dueno y lo libera al desmontarse, dejando el controlador que este panel
  /// sigue guardando con su `FocusNode` ya desechado.
  final _form = FormController();
  late final _search = InputController.search(form: _form);

  /// Lo que se escribio, ya normalizado (sin espacios en los bordes y en
  /// minusculas), que es como lo compara el listado. Solo lo escucha el.
  final _query = ValueNotifier<String>("");

  /// `true` mientras el buscador esta abierto. Con el cerrado, la barra muestra
  /// el titulo y sus dos botones.
  bool _searching = false;

  @override
  void initState() {
    super.initState();

    // Las cargas notifican a sus oyentes; se difieren al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _load();

      // El catalogo se pide desde aca aunque quien lo usa sea el formulario:
      // el listado necesita el nombre y el icono de cada red para pintar sus
      // filas, y ademas asi ya esta cuando se toque "conectar canal".
      context.read<ChannelCatalogService>().load();
    });
  }

  @override
  void dispose() {
    // El form libera a sus inputs, el buscador entre ellos.
    _form.dispose();
    _query.dispose();
    super.dispose();
  }

  /// Pide los canales de la empresa activa. El servicio cachea por empresa, asi
  /// que esta llamada no vuelve a pegarle al backend si ya estan cargados.
  void _load({bool force = false}) => context.read<ChannelsService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: Column(children: [
      SizedBox(
        height: AppSize.button,
        child: _searching ? _searchBar(context) : _titleBar(context)
      ),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
      ),
      Expanded(child: _Body(
        query: _query,
        onRetry: () => _load(force: true)
      ))
    ])
  );

  /// El titulo con sus dos acciones: buscar y conectar un canal.
  ///
  /// Las dos son botones de icono y no uno de texto porque el panel es angosto:
  /// "Conectar canal" escrito entero dejaria al titulo sin lugar. Lo que hace
  /// cada uno se lee en su tooltip.
  Widget _titleBar(BuildContext context) => Row(children: [
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextMedium(
      S.of(context).channels,
      bold: true,
      ellipsis: true
    )),
    SizedBox(width: AppSize.gap),
    _PanelAction(
      icon: CI.search,
      message: S.of(context).search_channel,
      action: _openSearch
    ),
    SizedBox(width: AppSize.gap),
    _PanelAction(
      icon: CI.plus,
      message: S.of(context).create_channel,
      action: _create
    )
  ]);

  /// El buscador abierto: ocupa la barra entera —el titulo se va— porque en este
  /// ancho el campo no entra al lado de nada.
  Widget _searchBar(BuildContext context) => Row(children: [
    Expanded(child: SearchInput(
      controller: _search,
      autofocus: true,
      radius: AppSize.cornerInset(AppSize.gap),
      placeholder: S.of(context).search_channel,
      // [SearchInput] ya espera a que se deje de escribir, asi que esto corre
      // por busqueda y no por tecla.
      onSearch: (value) => _query.value = value.trim().toLowerCase()
    )),
    SizedBox(width: AppSize.gap),
    _PanelAction(
      icon: Icons.close,
      message: S.of(context).cancel,
      action: _closeSearch
    )
  ]);

  void _openSearch() => setState(() => _searching = true);

  /// Cierra el buscador y devuelve el listado entero: si al cerrarlo quedara
  /// filtrado, faltarian canales sin nada en pantalla que lo explique.
  void _closeSearch() {
    _search.textController.clear();
    _query.value = "";
    setState(() => _searching = false);
  }

  /// Abre la pagina de alta. Es una sub-pagina y no un modal: el formulario
  /// tiene cinco bloques y las credenciales de la red se copian y pegan desde
  /// otra ventana, asi que necesita la pantalla entera.
  void _create() => Navis.push(context, "/home/channels/new");
}

/// Boton de icono de la barra del panel, de la medida de la fila.
class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;

  /// Que es el boton. Es su tooltip, y lo unico que lo nombra: el boton es solo
  /// el icono.
  final String message;

  final void Function() action;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    message: message,
    width: AppSize.button,
    height: AppSize.button,
    radius: AppSize.cornerInset(AppSize.gap),
    color: ThemeColor.of(context).surfaceOver,
    child: Center(child: Icon(
      icon,
      size: AppSize.text * 1.2,
      color: ThemeColor.of(context).icon
    ))
  );
}

/// El cuerpo del listado: lo unico que escucha a [ChannelsService], asi que
/// cargar, fallar o traer los canales no vuelve a construir la barra de arriba.
///
/// Cada estado dice lo que paso, y **no lo mismo con distinto texto**: que no se
/// hayan podido leer los canales y que la empresa todavia no tenga ninguno son
/// dos situaciones sin nada en comun —una se reintenta, la otra se resuelve
/// conectando una cuenta—, y confundirlas manda a revisar la conexion a quien
/// solo esta empezando.
///
/// Por eso el error es el unico que se explica: cuenta que fallo, sugiere que
/// mirar y ofrece reintentar, porque el panel quedo sin datos por algo que no
/// se sabe. El vacio, en cambio, es una sola linea: no hay nada que explicar ni
/// nada que reintentar, y en un panel de este ancho un parrafo con su boton se
/// lee como un problema.
class _Body extends StatelessWidget {
  const _Body({required this.query, required this.onRetry});

  final ValueListenable<String> query;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ChannelsService>();

    return switch (service.status) {
      ChannelsStatus.loading || ChannelsStatus.idle =>
        const Center(child: Loading()),
      ChannelsStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).channels_error_title,
        subtitle: S.of(context).channels_error_subtitle,
        action: onRetry,
        actionLabel: S.of(context).channels_retry
      ),
      // Sin subtitulo y sin boton: el "+" de la barra de arriba es el mismo alta
      // y esta a la vista, asi que repetirlo aca solo agrega ruido a un mensaje
      // que ya dijo todo lo que tenia que decir.
      ChannelsStatus.empty => SectionMessage(
        icon: CI.ia,
        title: S.of(context).channels_empty_title
      ),
      ChannelsStatus.ready => _List(channels: service.channels, query: query)
    };
  }
}

/// El listado filtrado. Escucha solo el buscador: escribir en el no toca ni la
/// barra ni el servicio, solo vuelve a filtrar estas filas.
///
/// El filtro mira el nombre y la descripcion: un canal se busca por como lo
/// llamo la empresa ("Ventas"), que es lo que se recuerda, y no por el codigo
/// de la red.
class _List extends StatelessWidget {
  const _List({required this.channels, required this.query});

  final List<ChannelLiteModel> channels;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: query,
    builder: (context, value, _) {
      final filtered = value.isEmpty
        ? channels
        : channels.where((channel) =>
            channel.name.toLowerCase().contains(value) ||
            channel.description.toLowerCase().contains(value)
          ).toList();

      if (filtered.isEmpty) {
        return SectionMessage(
          icon: CI.search,
          title: S.of(context).channels_search_empty
        );
      }

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
        itemBuilder: (context, index) => ChannelListRow(
          channel: filtered[index]
        )
      );
    }
  );
}
