import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_data_source.dart';
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channel_request.dart';
import 'package:app/services/channels/channel_tools.dart';

// WIDGETS
import 'package:core/form.dart';

/// En que esta la pagina del formulario.
///
/// Solo el alta arranca en [ready]: un canal que ya existe hay que ir a
/// buscarlo antes de poder dibujar nada, porque su configuracion es la que
/// llena los campos.
enum ChannelFormStatus { loading, ready, error }

/// Todo el estado del formulario de un canal, fuera de los widgets.
///
/// Vive aparte de la pantalla por lo mismo que el de la planilla: son muchas
/// piezas independientes —el tipo de canal, el rol del agente, la fuente de
/// datos, las herramientas y un campo por cada valor que pide la red— y ninguna
/// tiene por que repintar a las demas. Por eso cada una es su propio
/// [ValueNotifier] y no un `setState` de la pagina: elegir una herramienta no
/// puede volver a construir los quince campos de credenciales de al lado.
///
/// Los campos de configuracion se crean **a demanda y se reusan por clave**
/// ([field]). Cambiar de red no los tira: `app_secret` es literalmente el mismo
/// valor en WhatsApp, Messenger e Instagram —son la misma app de Meta— asi que
/// quien lo pego una vez no tiene que volver a pegarlo si se equivoco de red al
/// empezar.
///
/// Los dos formularios estan separados a proposito:
///
/// - [headerForm] tiene el nombre y la descripcion, y es el unico que se
///   valida: son los unicos datos que el backend exige.
/// - [configForm] tiene los campos de la red, y **no se valida nunca**. No es
///   descuido: un canal se guarda a medio configurar por diseno (se registra
///   antes de que Meta emita los tokens), asi que ningun campo de ahi puede
///   frenar un guardado. Ademas guarda controladores de redes que no se estan
///   mostrando, y `FormController.validate` recorre todos los que tenga
///   registrados, incluidos los que nunca se dibujaron.
class ChannelFormController {
  ChannelFormController({required this.channelId});

  /// Id del canal que se esta editando, o vacio si se esta creando uno.
  final String channelId;

  /// `true` si esto es la edicion de un canal que ya existe.
  bool get isEditing => channelId.isNotEmpty;

  /// Un canal nuevo no tiene nada que ir a buscar: se dibuja en el acto.
  late final status = ValueNotifier<ChannelFormStatus>(
    isEditing ? ChannelFormStatus.loading : ChannelFormStatus.ready
  );

  /// Codigo de la red elegida, o vacio si todavia no se eligio ninguna.
  ///
  /// En una edicion no se puede cambiar: las credenciales guardadas se juntaron
  /// para una red y apuntarlas a otra dejaria valores que ahi no significan
  /// nada. El backend lo rechaza (`provider_is_immutable`) y el selector ni
  /// siquiera lo ofrece.
  final provider = ValueNotifier<String>("");

  final role = ValueNotifier<ChannelAgentRole>(ChannelAgentRole.initial);
  final source = ValueNotifier<ChannelDataSource>(ChannelDataSource.initial);

  /// Herramientas encendidas. Se reemplaza el conjunto entero en vez de
  /// mutarlo: un [ValueNotifier] compara por identidad y mutar el `Set` no
  /// avisaria a nadie.
  final tools = ValueNotifier<Set<ChannelTool>>(const {});

  /// `true` mientras el guardado viaja. Lo escucha el boton de guardar.
  final saving = ValueNotifier<bool>(false);

  /// Detalle leido en una edicion. Es de donde sale que secretos ya estan
  /// guardados (por nombre) y que le falta al canal.
  ChannelDetailModel? detail;

  /// Nombre y descripcion con los que nacen sus campos.
  ///
  /// Se guardan como texto y no se escriben sobre los controladores porque
  /// **cuando llega el canal esos campos todavia no existen**: en una edicion
  /// la pantalla muestra el spinner hasta que la lectura vuelve, asi que los
  /// inputs se construyen despues de [apply]. Los crea la pagina ya con este
  /// valor puesto (`initial`), que ademas evita que el texto aparezca un frame
  /// tarde.
  String initialName = "";
  String initialDescription = "";

  final headerForm = FormController();
  final configForm = FormController();

  /// Campos de la red, por clave. Ver la nota de la clase sobre por que se
  /// reusan al cambiar de red.
  final _fields = <String, InputController>{};

  /// Tabla de productos elegida como fuente de datos. Es un select y no un
  /// campo de texto: se guarda el id de la tabla, no su nombre, para que
  /// renombrarla no desconecte el canal.
  late final table = InputController.select(
    key: ChannelDataSource.tableSettingKey,
    form: configForm
  );

  /// Controlador del campo [field], creandolo la primera vez.
  ///
  /// El tipo se traduce a lo que el input sabe hacer: un secreto se dibuja
  /// tapado, un numero con teclado numerico. El largo maximo es el que acepta
  /// el backend por valor de configuracion, que da de sobra para un token
  /// permanente o una clave PEM.
  InputController field(ChannelProviderField field) => _fields.putIfAbsent(
    field.key,
    () => InputController(
      key: field.key,
      form: configForm,
      type: switch (field.type) {
        ChannelFieldType.secret => InputType.password,
        ChannelFieldType.number => InputType.numeric,
        ChannelFieldType.email => InputType.email,
        _ => InputType.text
      },
      max: 4096
    )
  );

  /// Lo escrito en un campo de la red, o vacio si no se creo (una red que no se
  /// llego a dibujar).
  String valueOf(String key) => _fields[key]?.value.trim() ?? "";

  /// Vuelca en el formulario el canal que se acaba de leer.
  ///
  /// Los secretos **no se rellenan y no es un olvido**: el backend no los
  /// devuelve, solo dice bajo que claves hay uno guardado. El campo queda vacio
  /// y el formulario avisa que ya esta configurado; escribir algo lo reemplaza,
  /// dejarlo en blanco lo conserva.
  void apply(ChannelDetailModel channel) {
    detail = channel;

    provider.value = channel.provider;

    initialName = channel.name;
    initialDescription = channel.description;

    role.value = ChannelAgentRole.from(
      channel.setting(ChannelAgentRole.settingKey)
    );

    source.value = ChannelDataSource.from(
      channel.setting(ChannelDataSource.settingKey)
    );

    final tableId = channel.setting(ChannelDataSource.tableSettingKey);
    if (tableId.isNotEmpty) table.selectedValue = tableId;

    tools.value = {
      for (final tool in ChannelTool.values)
        if (channel.flag(tool.settingKey)) tool
    };

    // Los campos planos se crean ya cargados, antes de que los dibuje nadie:
    // creados por el widget llegarian vacios y habria que llenarlos despues,
    // con el texto apareciendo un frame tarde.
    final schema = channel.schema;
    if (schema == null) return;

    for (final item in schema.settingsFields) {
      field(item).textController.text = channel.setting(item.key);
    }
  }

  /// Ajustes que viajan en `SETTINGS`: los campos planos de la red mas los
  /// ajustes propios de la app (rol, fuente de datos y herramientas).
  ///
  /// Se manda **todo**, tambien lo vacio. En el alta los vacios se descartan al
  /// armar el cuerpo; en la edicion son los que borran un ajuste que estaba
  /// cargado, que es justo lo que hace falta para poder corregir un id de
  /// cuenta mal pegado.
  Map<String, dynamic> settings(ChannelProviderModel schema) {
    final settings = <String, dynamic>{};

    for (final item in schema.settingsFields) {
      settings[item.key] = valueOf(item.key);
    }

    settings[ChannelAgentRole.settingKey] = role.value.value;
    settings[ChannelDataSource.settingKey] = source.value.value;
    settings[ChannelDataSource.tableSettingKey] = tableId;

    for (final tool in ChannelTool.values) {
      settings[tool.settingKey] = tools.value.contains(tool);
    }

    return settings;
  }

  /// Secretos que viajan en `CREDENTIALS`: solo los que se escribieron.
  ///
  /// Un campo de secreto vacio significa "dejá el que ya estaba" y no
  /// "borralo": el formulario no puede mostrar el token guardado, asi que
  /// dejarlo en blanco es exactamente lo que hace quien vino a cambiar el
  /// nombre del canal. Mandarlo vacio le borraria el token a un canal que
  /// estaba funcionando.
  Map<String, dynamic> credentials(ChannelProviderModel schema) {
    final credentials = <String, dynamic>{};

    for (final item in schema.secretFields) {
      final value = valueOf(item.key);
      if (value.isNotEmpty) credentials[item.key] = value;
    }

    return credentials;
  }

  /// Id de la tabla de productos elegida, o vacio si no se eligio ninguna.
  String get tableId => table.selectedValue?.trim() ?? "";

  /// Cuerpo de la escritura que corresponde: el alta o la edicion.
  Map<String, dynamic> payload(ChannelProviderModel schema) => isEditing
    ? editChannelRequest(
        id: channelId,
        name: nameValue,
        description: descriptionValue,
        settings: settings(schema),
        credentials: credentials(schema)
      )
    : createChannelRequest(
        provider: schema.provider,
        name: nameValue,
        description: descriptionValue,
        settings: settings(schema),
        credentials: credentials(schema)
      );

  String get nameValue => headerForm.inputs["NAME"]?.value.trim() ?? "";
  String get descriptionValue =>
    headerForm.inputs["DESCRIPTION"]?.value.trim() ?? "";

  /// Enciende o apaga una herramienta.
  void toggleTool(ChannelTool tool) {
    final next = Set<ChannelTool>.from(tools.value);

    if (!next.remove(tool)) next.add(tool);

    tools.value = next;
  }

  /// Marca el formulario como ocupado. Las dos partes a la vez: los inputs se
  /// bloquean escuchando el `loading` de **su** formulario, y son dos.
  void busy(bool value) {
    saving.value = value;
    headerForm.loading.value = value;
    configForm.loading.value = value;
  }

  void dispose() {
    status.dispose();
    provider.dispose();
    role.dispose();
    source.dispose();
    tools.dispose();
    saving.dispose();

    // El nombre y la descripcion los libera su formulario: siempre se
    // dibujaron, asi que estan registrados en el.
    headerForm.dispose();

    // Los de configuracion se liberan a mano, y no con `configForm.dispose()`,
    // porque un formulario solo conoce los controladores que **se llegaron a
    // dibujar** (se registran al montarse el input). Aca hay de los otros: los
    // que creo [apply] antes del primer frame y los de una red que se eligio y
    // despues se cambio. Recorrer el mapa los alcanza a todos, y saltear el
    // dispose del formulario evita liberar dos veces los que si estan en ambos.
    for (final input in _fields.values) {
      input.dispose();
    }

    table.dispose();

    _fields.clear();
    configForm.inputs.clear();
    configForm.data.clear();
    configForm.loading.dispose();
  }
}
