import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/connections/connection_detail_model.dart';
import 'package:app/services/connections/connection_provider_model.dart';
import 'package:app/services/connections/connection_request.dart';

// WIDGETS
import 'package:core/form.dart';

/// En que esta la pagina del formulario.
///
/// Solo el alta arranca en [ready]: una conexion que ya existe hay que ir a
/// buscarla antes de poder dibujar nada, porque su configuracion es la que llena
/// los campos.
enum ConnectionFormStatus { loading, ready, error }

/// Todo el estado del formulario de una conexion, fuera de los widgets.
///
/// Vive aparte de la pantalla por lo mismo que el de la planilla: son piezas
/// independientes —el servicio elegido y un campo por cada valor que pide— y
/// ninguna tiene por que repintar a las demas. Por eso el servicio es su propio
/// [ValueNotifier] y no un `setState` de la pagina: elegirlo no puede volver a
/// construir los siete campos de credenciales de al lado mientras se escriben.
///
/// Los campos de configuracion se crean **a demanda y se reusan por clave**
/// ([field]). Cambiar de servicio no los tira: `app_secret` es literalmente el
/// mismo valor en WhatsApp, Messenger e Instagram —son la misma app de Meta— asi
/// que quien lo pego una vez no tiene que volver a pegarlo si se equivoco de
/// servicio al empezar.
///
/// Los dos formularios estan separados a proposito:
///
/// - [headerForm] tiene el nombre y la descripcion, y es el unico que se valida:
///   son los unicos datos que el backend exige.
/// - [configForm] tiene los campos del servicio, y **no se valida nunca**. No es
///   descuido: una conexion se guarda a medio configurar por diseno (se registra
///   antes de que Meta emita los tokens), asi que ningun campo de ahi puede frenar
///   un guardado. Ademas guarda controladores de servicios que no se estan
///   mostrando, y `FormController.validate` recorre todos los que tenga
///   registrados, incluidos los que nunca se dibujaron.
class ConnectionFormController {
  ConnectionFormController({required this.connectionId});

  /// Id de la conexion que se esta editando, o vacio si se esta creando una.
  final String connectionId;

  /// `true` si esto es la edicion de una conexion que ya existe.
  bool get isEditing => connectionId.isNotEmpty;

  /// Una conexion nueva no tiene nada que ir a buscar: se dibuja en el acto.
  late final status = ValueNotifier<ConnectionFormStatus>(
    isEditing ? ConnectionFormStatus.loading : ConnectionFormStatus.ready
  );

  /// Codigo del servicio elegido, o vacio si todavia no se eligio ninguno.
  ///
  /// En una edicion no se puede cambiar: las credenciales guardadas se juntaron
  /// para un servicio y apuntarlas a otro dejaria valores que ahi no significan
  /// nada. El backend lo rechaza (`provider_is_immutable`) y el selector ni
  /// siquiera lo ofrece.
  final provider = ValueNotifier<String>("");

  /// `true` mientras el guardado viaja. Lo escucha el boton de guardar.
  final saving = ValueNotifier<bool>(false);

  /// Detalle leido en una edicion. Es de donde sale que secretos ya estan
  /// guardados (por nombre) y que le falta a la cuenta.
  ConnectionDetailModel? detail;

  /// Nombre y descripcion con los que nacen sus campos.
  ///
  /// Se guardan como texto y no se escriben sobre los controladores porque
  /// **cuando llega la conexion esos campos todavia no existen**: en una edicion
  /// la pantalla muestra el spinner hasta que la lectura vuelve, asi que los
  /// inputs se construyen despues de [apply]. Los crea la pagina ya con este valor
  /// puesto (`initial`), que ademas evita que el texto aparezca un frame tarde.
  String initialName = "";
  String initialDescription = "";

  final headerForm = FormController();
  final configForm = FormController();

  /// Campos del servicio, por clave. Ver la nota de la clase sobre por que se
  /// reusan al cambiar de servicio.
  final _fields = <String, InputController>{};

  /// Controlador del campo [field], creandolo la primera vez.
  ///
  /// El tipo se traduce a lo que el input sabe hacer: un secreto se dibuja tapado,
  /// un numero con teclado numerico. El largo maximo es el que acepta el backend
  /// por valor de configuracion, que da de sobra para un token permanente o una
  /// clave PEM.
  InputController field(ConnectionProviderField field) => _fields.putIfAbsent(
    field.key,
    () => InputController(
      key: field.key,
      form: configForm,
      type: switch (field.type) {
        ConnectionFieldType.secret => InputType.password,
        ConnectionFieldType.number => InputType.numeric,
        ConnectionFieldType.email => InputType.email,
        _ => InputType.text
      },
      max: 4096
    )
  );

  /// Lo escrito en un campo del servicio, o vacio si no se creo (un servicio que
  /// no se llego a dibujar).
  String valueOf(String key) => _fields[key]?.value.trim() ?? "";

  /// Vuelca en el formulario la conexion que se acaba de leer.
  ///
  /// Los secretos **no se rellenan y no es un olvido**: el backend no los
  /// devuelve, solo dice bajo que claves hay uno guardado. El campo queda vacio y
  /// el formulario avisa que ya esta configurado; escribir algo lo reemplaza,
  /// dejarlo en blanco lo conserva.
  void apply(ConnectionDetailModel connection) {
    detail = connection;

    provider.value = connection.provider;

    initialName = connection.name;
    initialDescription = connection.description;

    // Los campos planos se crean ya cargados, antes de que los dibuje nadie:
    // creados por el widget llegarian vacios y habria que llenarlos despues, con
    // el texto apareciendo un frame tarde.
    final schema = connection.schema;
    if (schema == null) return;

    for (final item in schema.settingsFields) {
      field(item).textController.text = connection.setting(item.key);
    }
  }

  /// Ajustes que viajan en `SETTINGS`: los campos planos del servicio.
  ///
  /// Se manda **todo**, tambien lo vacio. En el alta los vacios se descartan al
  /// armar el cuerpo; en la edicion son los que borran un ajuste que estaba
  /// cargado, que es justo lo que hace falta para poder corregir un id de cuenta
  /// mal pegado.
  Map<String, dynamic> settings(ConnectionProviderModel schema) {
    final settings = <String, dynamic>{};

    for (final item in schema.settingsFields) {
      settings[item.key] = valueOf(item.key);
    }

    return settings;
  }

  /// Secretos que viajan en `CREDENTIALS`: solo los que se escribieron.
  ///
  /// Un campo de secreto vacio significa "dejá el que ya estaba" y no "borralo":
  /// el formulario no puede mostrar el token guardado, asi que dejarlo en blanco
  /// es exactamente lo que hace quien vino a cambiar el nombre de la cuenta.
  /// Mandarlo vacio le borraria el token a una conexion que estaba funcionando.
  Map<String, dynamic> credentials(ConnectionProviderModel schema) {
    final credentials = <String, dynamic>{};

    for (final item in schema.secretFields) {
      final value = valueOf(item.key);
      if (value.isNotEmpty) credentials[item.key] = value;
    }

    return credentials;
  }

  /// Cuerpo de la escritura que corresponde: el alta o la edicion.
  Map<String, dynamic> payload(ConnectionProviderModel schema) => isEditing
    ? editConnectionRequest(
        id: connectionId,
        name: nameValue,
        description: descriptionValue,
        settings: settings(schema),
        credentials: credentials(schema)
      )
    : createConnectionRequest(
        provider: schema.provider,
        name: nameValue,
        description: descriptionValue,
        settings: settings(schema),
        credentials: credentials(schema)
      );

  String get nameValue => headerForm.inputs["NAME"]?.value.trim() ?? "";
  String get descriptionValue =>
    headerForm.inputs["DESCRIPTION"]?.value.trim() ?? "";

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
    saving.dispose();

    // El nombre y la descripcion los libera su formulario: siempre se dibujaron,
    // asi que estan registrados en el.
    headerForm.dispose();

    // Los de configuracion se liberan a mano, y no con `configForm.dispose()`,
    // porque un formulario solo conoce los controladores que **se llegaron a
    // dibujar** (se registran al montarse el input). Aca hay de los otros: los que
    // creo [apply] antes del primer frame y los de un servicio que se eligio y
    // despues se cambio. Recorrer el mapa los alcanza a todos, y saltear el
    // dispose del formulario evita liberar dos veces los que si estan en ambos.
    for (final input in _fields.values) {
      input.dispose();
    }

    _fields.clear();
    configForm.inputs.clear();
    configForm.data.clear();
    configForm.loading.dispose();
  }
}
