import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_provider_model.dart';
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'blocks/credentials_block.dart';
import 'blocks/provider_picker.dart';
import 'widgets/form_block.dart';
import 'widgets/missing_banner.dart';
import 'state/connection_form_controller.dart';

/// Alta y edicion de una conexion. Es una sub-pagina de la seccion `connections`
/// (`parents: ["connections"]`): se abre desde el listado y comparte el shell del
/// home, por lo que la opcion del side bar sigue marcada.
///
/// Son tres decisiones y nada mas: como se llama la cuenta, de que servicio es y
/// con que credenciales se entra. **Lo que la cuenta hace no se decide aca**: no
/// hay rol de agente, ni tabla de la que leer, ni herramientas; eso es un bot
/// sobre esta conexion y se arma en otra parte. Una cuenta se autentica una vez y
/// la comparten todos los bots que corran encima.
///
/// Es una pagina y no un modal aunque sean tres bloques: los tokens se copian y
/// pegan desde la consola del servicio, en otra ventana, y un modal se cierra de
/// un clic afuera. Perder siete campos pegados a mano por un clic al lado no es
/// una opcion.
///
/// **Es la misma pantalla para las dos cosas.** Que sea un alta o una edicion lo
/// decide la URL: `/home/connections/new` no trae id y `/home/connections/:id` si.
/// El id se lee de [Navis.currentArgs] y no por constructor porque la sub-pagina
/// reusa la unica pagina del shell y el `Navigator` no reconstruye el arbol al
/// navegar.
///
/// Editando, la pantalla espera a que llegue la conexion antes de dibujar nada: su
/// configuracion es la que llena los campos, y montar el formulario vacio para
/// llenarlo despues haria saltar el texto un frame mas tarde. Un alta no espera
/// nada.
///
/// Lo que **no** se puede hacer editando es cambiar el servicio. Los secretos
/// guardados se juntaron para uno, y apuntarlos a otro dejaria valores que ahi no
/// significan nada: el otro servicio es una conexion nueva.
///
/// El estado vive en [ConnectionFormController], fuera de los widgets, para que
/// cada bloque escuche solo lo suyo: elegir el servicio no puede repintar los
/// campos que se estan escribiendo al lado.
class ConnectionFormSection extends StatefulWidget {
  const ConnectionFormSection({super.key});

  /// Key de la ruta del alta (`/home/connections/new`).
  static const String createRouteKey = "connection_new";

  /// Key de la ruta de la edicion (`/home/connections/:id`).
  static const String editRouteKey = "connection_detail";

  @override
  State<ConnectionFormSection> createState() => _ConnectionFormSectionState();
}

class _ConnectionFormSectionState extends State<ConnectionFormSection>
    with BusinessListener<ConnectionFormSection> {
  late final ConnectionFormController _controller;

  /// Nombre de la conexion. Es lo unico que el backend exige de verdad, con el
  /// mismo largo y los mismos caracteres que acepta del otro lado: letras,
  /// numeros, espacios, guiones y guion bajo. Un nombre con parentesis o barras lo
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
      InputError.empty:
        S.of(context).form_empty_ma(S.of(context).connection_name_input),
      InputError.invalid:
        S.of(context).form_invalid_ma(S.of(context).connection_name_input),
      InputError.long:
        S.of(context).form_long_ma(S.of(context).connection_name_input),
      InputError.incomplete:
        S.of(context).form_incomplete_ma(S.of(context).connection_name_input)
    }
  );

  /// Descripcion opcional: sin `obligatory`, solo se valida el largo.
  late final _description = InputController(
    key: "DESCRIPTION",
    form: _controller.headerForm,
    max: 255,
    initial: _controller.initialDescription,
    customErrors: {
      InputError.long:
        S.of(context).form_long_ma(S.of(context).connection_description_input)
    }
  );

  @override
  void initState() {
    super.initState();

    // El id vive en la URL: sin el, esto es un alta.
    _controller = ConnectionFormController(
      connectionId: Navis.currentArgs?["id"] ?? ""
    );

    // Las cargas notifican a sus oyentes; se difieren al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // El catalogo dibuja el formulario entero (que campos pide cada servicio),
      // asi que sin el no hay pantalla. Normalmente ya lo pidio el listado.
      context.read<ConnectionCatalogService>().load();

      if (_controller.isEditing) _open();
    });
  }

  /// La conexion que se esta editando es de la empresa que estaba activa: su id no
  /// significa nada en la que se acaba de elegir. Se vuelve al listado, que es lo
  /// unico que se puede mostrar de la empresa nueva.
  @override
  void onBusinessChanged(String businessId) => _back();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Lee la conexion que se va a editar. Trae su configuracion, que secretos ya
  /// tiene guardados y la descripcion de su proveedor, todo en una sola lectura.
  Future<void> _open() async {
    final connection = await context
      .read<ConnectionsService>()
      .detail(context, _controller.connectionId);

    if (!mounted) return;

    if (connection == null) {
      _controller.status.value = ConnectionFormStatus.error;
      return;
    }

    _controller.apply(connection);
    _controller.status.value = ConnectionFormStatus.ready;
  }

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      _header(context),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: ValueListenableBuilder<ConnectionFormStatus>(
        valueListenable: _controller.status,
        builder: (context, status, _) => switch (status) {
          ConnectionFormStatus.loading => const Center(child: Loading()),
          ConnectionFormStatus.error => SectionMessage(
            icon: CI.info,
            title: S.of(context).connection_open_error_title,
            subtitle: S.of(context).connection_open_error_subtitle,
            action: _back,
            actionLabel: S.of(context).connections
          ),
          ConnectionFormStatus.ready => _body()
        }
      ))
    ])
  );

  /// Barra superior: volver al listado, el titulo y el boton de guardar.
  ///
  /// El titulo de una edicion es el nombre que la conexion tenia **al abrirla** y
  /// no lo que se este escribiendo en el campo: si siguiera al input, renombrarla
  /// reescribiria el encabezado letra por letra.
  Widget _header(BuildContext context) => Row(children: [
    FeedbackButton(
      action: _back,
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).connections,
      child: Center(child: Icon(
        CI.arrow_left,
        color: ThemeColor.of(context).text.primary
      ))
    ),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextMedium(
      _controller.isEditing && _controller.initialName.isNotEmpty
        ? _controller.initialName
        : S.of(context).create_connection,
      bold: true,
      ellipsis: true
    )),
    SizedBox(width: AppSize.spaceS),
    ValueListenableBuilder<ConnectionFormStatus>(
      valueListenable: _controller.status,
      builder: (context, status, _) => status != ConnectionFormStatus.ready
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

  /// Ancho maximo del formulario.
  ///
  /// Los tres bloques van en una sola columna —son pocos y se leen de corrido— y
  /// esta es la unica medida que hace falta: en un monitor ancho, un campo de
  /// texto de punta a punta para pegar un id de cuenta se lee peor, y el selector
  /// de servicio queda con tarjetas mas anchas que altas. Lo que sobra queda como
  /// aire a los costados.
  static double get _maxWidth => AppSize.action * 15;

  /// El formulario: como se llama la cuenta, de que servicio es y sus
  /// credenciales, en ese orden.
  ///
  /// El orden no es arbitrario: el servicio decide **que campos existen** debajo,
  /// asi que antes de elegirlo el bloque de credenciales no puede dibujarse. El
  /// nombre va primero porque es lo unico que se puede llenar sin haber abierto la
  /// consola de nadie.
  Widget _body() => ScrollableWidget(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.isEditing) MissingBanner(controller: _controller),
            FormBlock(
              title: S.of(context).connection_identity_title,
              subtitle: S.of(context).connection_identity_subtitle,
              child: Column(children: [
                Input(
                  title: S.of(context).connection_name_input,
                  placeholder: S.of(context).connection_name_placeholder,
                  controller: _name,
                  leftIcon: Icon(CI.tems, color: ThemeColor.of(context).icon),
                  next: _description.focus
                ),
                Input(
                  title: S.of(context).connection_description_input,
                  placeholder: S.of(context).connection_description_placeholder,
                  controller: _description,
                  leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
                )
              ])
            ),
            ProviderPicker(controller: _controller),
            // Las credenciales dependen del servicio: hasta que no se elige uno no
            // hay campos que dibujar, porque cada uno pide los suyos.
            ValueListenableBuilder<String>(
              valueListenable: _controller.provider,
              builder: (context, code, _) {
                final schema = _schemaOf(code);

                if (schema == null) return const SizedBox.shrink();

                return CredentialsBlock(
                  controller: _controller,
                  schema: schema
                );
              }
            )
          ]
        )
      )
    ]
  );

  /// Descripcion del servicio elegido.
  ///
  /// Editando sale de la propia conexion (viene pegada al detalle) y si no, del
  /// catalogo. Se prefiere la de la conexion porque es la que corresponde a lo que
  /// tiene guardado, aunque el catalogo se haya movido.
  ConnectionProviderModel? _schemaOf(String code) {
    if (code.isEmpty) return null;

    final schema = _controller.detail?.schema;
    if (schema != null && schema.provider == code) return schema;

    return context.read<ConnectionCatalogService>().byCode(code);
  }

  void _back() => Navis.push(context, "/home/connections");

  /// Guarda la conexion.
  ///
  /// Lo unico que se exige es el nombre y el servicio: **el resto puede quedar a
  /// medio llenar a proposito**, porque una cuenta se registra antes de que el
  /// servicio emita sus tokens y se termina de configurar despues. Queda como
  /// "falta configurar" en el listado hasta entonces, que es exactamente lo que
  /// es.
  Future<void> _submit() async {
    if (_controller.saving.value) return;

    final schema = _schemaOf(_controller.provider.value);

    if (schema == null) {
      FloatFlag.of(context).error(
        message: S.of(context).connection_provider_missing
      );
      return;
    }

    if (!_controller.headerForm.validate()) return;

    _controller.busy(true);

    final saved = await _write(_controller.payload(schema));

    if (!mounted) return;

    _controller.busy(false);

    // Fallo: el error ya lo mostro el servicio y la pantalla se queda con todo lo
    // escrito, que es lo unico razonable cuando alguien acaba de pegar cuatro
    // tokens.
    if (!saved) return;

    FloatFlag.of(context).message(
      _controller.isEditing
        ? S.of(context).connection_saved
        : S.of(context).connection_created
    );

    _back();
  }

  /// Manda la escritura que corresponda y responde solo si salio o no.
  ///
  /// Las dos operaciones del servicio avisan distinto —la edicion devuelve un
  /// booleano y el alta devuelve el id o relanza— y a esta pantalla le da igual
  /// cual fue: en las dos ya se mostro el error y lo unico que cambia despues es el
  /// texto del aviso.
  Future<bool> _write(Map<String, dynamic> data) async {
    final service = context.read<ConnectionsService>();

    if (_controller.isEditing) return service.edit(context, data);

    try {
      await service.create(context, data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
