import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'blocks/agent_picker.dart';
import 'blocks/credentials_block.dart';
import 'blocks/data_picker.dart';
import 'blocks/provider_picker.dart';
import 'blocks/tools_picker.dart';
import 'widgets/form_block.dart';
import 'widgets/missing_banner.dart';
import 'state/channel_form_controller.dart';

/// Alta y edicion de un canal. Es una sub-pagina de la seccion `channels`
/// (`parents: ["channels"]`): se abre desde el listado y comparte el shell del
/// home, por lo que la opcion del side bar sigue marcada.
///
/// Es una pagina y no un modal —a diferencia del alta de una tabla— porque son
/// cinco decisiones y un formulario de credenciales entero: que red se conecta,
/// que hace el agente que atiende, de donde saca los datos, que puede procesar
/// y con que tokens entra. Ademas esos tokens se copian y pegan desde la
/// consola de Meta, en otra ventana, y un modal se cierra de un clic afuera.
///
/// **Es la misma pantalla para las dos cosas.** Que sea un alta o una edicion
/// lo decide la URL: `/home/channels/new` no trae id y `/home/channels/:id` si.
/// El id se lee de [Navis.currentArgs] y no por constructor porque la
/// sub-pagina reusa la unica pagina del shell y el `Navigator` no reconstruye
/// el arbol al navegar.
///
/// Editando, la pantalla espera a que llegue el canal antes de dibujar nada: su
/// configuracion es la que llena los campos, y montar el formulario vacio para
/// llenarlo despues haria saltar el texto un frame mas tarde. Un alta no espera
/// nada.
///
/// Lo que **no** se puede hacer editando es cambiar la red. Los secretos
/// guardados se juntaron para una, y apuntarlos a otra dejaria valores que ahi
/// no significan nada: la otra red es un canal nuevo.
///
/// El estado vive en [ChannelFormController], fuera de los widgets, para que
/// cada bloque escuche solo lo suyo: elegir una herramienta no puede repintar
/// los quince campos de credenciales de al lado.
class ChannelFormSection extends StatefulWidget {
  const ChannelFormSection({super.key});

  /// Key de la ruta del alta (`/home/channels/new`).
  static const String createRouteKey = "channel_new";

  /// Key de la ruta de la edicion (`/home/channels/:id`).
  static const String editRouteKey = "channel_detail";

  @override
  State<ChannelFormSection> createState() => _ChannelFormSectionState();
}

class _ChannelFormSectionState extends State<ChannelFormSection>
    with BusinessListener<ChannelFormSection> {
  late final ChannelFormController _controller;

  /// Nombre del canal. Es lo unico que el backend exige de verdad, con el mismo
  /// largo y los mismos caracteres que acepta del otro lado: letras, numeros,
  /// espacios, guiones y guion bajo. Un nombre con parentesis o barras lo
  /// rechazaria la api, asi que se frena aca con un mensaje que se entiende.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 _\\-]";

  late final _name = InputController(
    key: "NAME",
    form: _controller.headerForm,
    pattern: _namePattern,
    min: 2,
    max: 64,
    obligatory: true,
    initial: _controller.initialName,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).channel_name_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).channel_name_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).channel_name_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).channel_name_input)
    }
  );

  /// Descripcion opcional: sin `obligatory`, solo se valida el largo.
  late final _description = InputController(
    key: "DESCRIPTION",
    form: _controller.headerForm,
    max: 255,
    initial: _controller.initialDescription,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).channel_description_input)
    }
  );

  @override
  void initState() {
    super.initState();

    // El id vive en la URL: sin el, esto es un alta.
    _controller = ChannelFormController(
      channelId: Navis.currentArgs?["id"] ?? ""
    );

    // Las cargas notifican a sus oyentes; se difieren al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // El catalogo dibuja el formulario entero (que campos pide cada red), asi
      // que sin el no hay pantalla. Normalmente ya lo pidio el listado.
      context.read<ChannelCatalogService>().load();

      // Las tablas de productos son la fuente de datos elegible: se piden a la
      // misma cache que usa la seccion de productos, asi que si ya se visito,
      // esto no le pega al backend.
      context.read<TablesService>().load(
        context.read<BusinessService>().active.id
      );

      if (_controller.isEditing) _open();
    });
  }

  /// El canal que se esta editando es de la empresa que estaba activa: su id no
  /// significa nada en la que se acaba de elegir. Se vuelve al listado, que es
  /// lo unico que se puede mostrar de la empresa nueva.
  @override
  void onBusinessChanged(String businessId) => _back();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Lee el canal que se va a editar. Trae su configuracion, que secretos ya
  /// tiene guardados y la descripcion de su proveedor, todo en una sola
  /// lectura.
  Future<void> _open() async {
    final channel = await context
      .read<ChannelsService>()
      .detail(context, _controller.channelId);

    if (!mounted) return;

    if (channel == null) {
      _controller.status.value = ChannelFormStatus.error;
      return;
    }

    _controller.apply(channel);
    _controller.status.value = ChannelFormStatus.ready;
  }

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      _header(context),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: ValueListenableBuilder<ChannelFormStatus>(
        valueListenable: _controller.status,
        builder: (context, status, _) => switch (status) {
          ChannelFormStatus.loading => const Center(child: Loading()),
          ChannelFormStatus.error => SectionMessage(
            icon: CI.info,
            title: S.of(context).channel_open_error_title,
            subtitle: S.of(context).channel_open_error_subtitle,
            action: _back,
            actionLabel: S.of(context).channels
          ),
          ChannelFormStatus.ready => _body()
        }
      ))
    ])
  );

  /// Barra superior: volver al listado, el titulo y el boton de guardar.
  ///
  /// El titulo de una edicion es el nombre que el canal tenia **al abrirlo** y
  /// no lo que se este escribiendo en el campo: si siguiera al input, renombrar
  /// el canal reescribiria el encabezado letra por letra.
  Widget _header(BuildContext context) => Row(children: [
    FeedbackButton(
      action: _back,
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).channels,
      child: Center(child: Icon(
        CI.arrow_left,
        color: ThemeColor.of(context).text.primary
      ))
    ),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextMedium(
      _controller.isEditing && _controller.initialName.isNotEmpty
        ? _controller.initialName
        : S.of(context).create_channel,
      bold: true,
      ellipsis: true
    )),
    SizedBox(width: AppSize.spaceS),
    ValueListenableBuilder<ChannelFormStatus>(
      valueListenable: _controller.status,
      builder: (context, status, _) => status != ChannelFormStatus.ready
        // Sin formulario no hay nada que guardar: el boton no se muestra
        // apagado, no se muestra.
        ? const SizedBox.shrink()
        : SizedBox(
            width: AppSize.action * 4,
            child: Button(
              title: S.of(context).save,
              loading: _controller.saving,
              action: _submit
            )
          )
    )
  ]);

  /// Ancho a partir del cual el formulario se abre en dos columnas.
  static double get _twoColumns => AppSize.action * 16;

  /// El formulario, partido en dos mitades que se leen por separado: **a que se
  /// conecta** (como se llama, que red, con que credenciales) y **como
  /// atiende** (que hace el agente, de donde saca los datos, que puede
  /// procesar).
  ///
  /// El corte no es solo para llenar el ancho. Los seis bloques en una sola
  /// columna obligan a bajar hasta el final para llegar a las credenciales, que
  /// es a lo que se vuelve cuando el canal quedo a medio configurar; asi quedan
  /// arriba, del lado de la red que las pide.
  ///
  /// En angosto se apilan en el orden en que se decide un canal, que es el
  /// mismo de arriba leido de corrido.
  ///
  /// Las dos mitades van siempre en el mismo [Wrap] y lo unico que cambia con
  /// el ancho es **cuanto mide cada una**: enteras se acomodan una debajo de la
  /// otra, a la mitad entran lado a lado. No se arma un `Row` cuando hay lugar
  /// y una `Column` cuando no, y no es por gusto: cambiar la forma del arbol al
  /// cruzar el ancho desmonta y vuelve a montar los inputs, y un
  /// [InputController] no sobrevive a eso —los widgets de `core` le asignan su
  /// validacion al montarse y el campo es de una sola escritura—. Estirar la
  /// ventana rompia el formulario.
  Widget _body() => LayoutBuilder(builder: (context, constraints) {
    // Un ancho sin medida no puede pasar a las mitades: se toma el minimo para
    // partir, que deja una sola columna.
    final available = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : _twoColumns - 1;

    final split = available >= _twoColumns;

    // Al piso: dos mitades que sumen un pelo mas que el ancho por el redondeo
    // del punto flotante no entran en la misma fila, y el [Wrap] baja la
    // segunda —una columna cuando habia lugar para dos.
    final column = split
      ? ((available - AppSize.spaceM) / 2).floorToDouble()
      : available;

    final connection = <Widget>[
      FormBlock(
        title: S.of(context).channel_identity_title,
        subtitle: S.of(context).channel_identity_subtitle,
        child: Column(children: [
          Input(
            title: S.of(context).channel_name_input,
            placeholder: S.of(context).channel_name_placeholder,
            controller: _name,
            leftIcon: Icon(CI.tems, color: ThemeColor.of(context).icon),
            next: _description.focus
          ),
          Input(
            title: S.of(context).channel_description_input,
            placeholder: S.of(context).channel_description_placeholder,
            controller: _description,
            leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
          )
        ])
      ),
      ProviderPicker(controller: _controller),
      // Las credenciales dependen de la red: hasta que no se elige una no hay
      // campos que dibujar, porque cada red pide los suyos.
      ValueListenableBuilder<String>(
        valueListenable: _controller.provider,
        builder: (context, code, _) {
          final schema = _schemaOf(code);

          if (schema == null) return const SizedBox.shrink();

          return CredentialsBlock(controller: _controller, schema: schema);
        }
      )
    ];

    final agent = <Widget>[
      AgentPicker(controller: _controller),
      DataPicker(controller: _controller),
      ToolsPicker(controller: _controller)
    ];

    return ScrollableWidget(
      children: [
        if (_controller.isEditing) MissingBanner(controller: _controller),
        Wrap(
          spacing: AppSize.spaceM,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(width: column, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: connection
            )),
            SizedBox(width: column, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: agent
            ))
          ]
        )
      ]
    );
  });

  /// Descripcion de la red elegida.
  ///
  /// Editando sale del propio canal (viene pegada al detalle) y si no, del
  /// catalogo. Se prefiere la del canal porque es la que corresponde a lo que
  /// tiene guardado, aunque el catalogo se haya movido.
  ChannelProviderModel? _schemaOf(String code) {
    if (code.isEmpty) return null;

    final schema = _controller.detail?.schema;
    if (schema != null && schema.provider == code) return schema;

    return context.read<ChannelCatalogService>().byCode(code);
  }

  void _back() => Navis.push(context, "/home/channels");

  /// Guarda el canal.
  ///
  /// Lo unico que se exige es el nombre y la red: **el resto puede quedar a
  /// medio llenar a proposito**, porque un canal se registra antes de que Meta
  /// emita sus tokens y se termina de configurar despues. Lo que si se pide es
  /// que la fuente de datos este completa: elegir "tabla de productos" y no
  /// decir cual deja al agente sin nada que leer, y eso no es un canal a medio
  /// configurar sino uno mal configurado.
  Future<void> _submit() async {
    if (_controller.saving.value) return;

    final schema = _schemaOf(_controller.provider.value);

    if (schema == null) {
      FloatFlag.of(context).error(
        message: S.of(context).channel_type_missing
      );
      return;
    }

    if (!_controller.headerForm.validate()) return;

    if (_controller.source.value.needsTable && _controller.tableId.isEmpty) {
      FloatFlag.of(context).error(
        message: S.of(context).channel_source_missing
      );
      return;
    }

    _controller.busy(true);

    final saved = await _write(_controller.payload(schema));

    if (!mounted) return;

    _controller.busy(false);

    // Fallo: el error ya lo mostro el servicio y la pantalla se queda con todo
    // lo escrito, que es lo unico razonable cuando alguien acaba de pegar
    // cuatro tokens.
    if (!saved) return;

    FloatFlag.of(context).message(
      _controller.isEditing
        ? S.of(context).channel_saved
        : S.of(context).channel_created
    );

    _back();
  }

  /// Manda la escritura que corresponda y responde solo si salio o no.
  ///
  /// Las dos operaciones del servicio avisan distinto —la edicion devuelve un
  /// booleano y el alta devuelve el id o relanza— y a esta pantalla le da igual
  /// cual fue: en las dos ya se mostro el error y lo unico que cambia despues
  /// es el texto del aviso.
  Future<bool> _write(Map<String, dynamic> data) async {
    final service = context.read<ChannelsService>();

    if (_controller.isEditing) return service.edit(context, data);

    try {
      await service.create(context, data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
