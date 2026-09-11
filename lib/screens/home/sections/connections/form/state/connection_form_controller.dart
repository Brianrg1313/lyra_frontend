import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/connections/connection_detail_model.dart';
import 'package:app/services/connections/connection_provider_model.dart';
import 'package:app/services/connections/connection_request.dart';

// WIDGETS
import 'package:core/form.dart';

/// What state the form's page is in.
///
/// Only the creation starts in [ready]: a connection that already exists has
/// to be fetched before drawing anything, because its configuration is what
/// fills the fields.
enum ConnectionFormStatus { loading, ready, error }

/// All the state of a connection's form, outside the widgets.
///
/// It lives apart from the screen for the same reason the spreadsheet's does:
/// they're independent pieces —the chosen service and one field per value it
/// asks for— and none of them has to repaint the others. That's why the
/// service is its own [ValueNotifier] and not a `setState` of the page:
/// choosing it can't rebuild the seven credential fields next to it while
/// they're being typed into.
///
/// The configuration fields are created **on demand and reused by key**
/// ([field]). Changing service doesn't throw them away: `app_secret` is
/// literally the same value in WhatsApp, Messenger and Instagram —they're the
/// same Meta app— so whoever pasted it once doesn't have to paste it again if
/// they picked the wrong service to start.
///
/// The two forms are separated on purpose:
///
/// - [headerForm] has the name and the description, and it's the only one
///   that gets validated: they're the only data the backend requires.
/// - [configForm] has the service's fields, and it's **never validated**. It's
///   not neglect: a connection is saved half-configured by design (it's
///   registered before Meta issues the tokens), so no field in there can block
///   a save. Besides, it holds controllers of services that aren't being
///   shown, and `FormController.validate` goes through all the ones it has
///   registered, including those that were never drawn.
class ConnectionFormController {
  ConnectionFormController({required this.connectionId});

  /// Id of the connection being edited, or empty if one is being created.
  final String connectionId;

  /// `true` if this is the edit of a connection that already exists.
  bool get isEditing => connectionId.isNotEmpty;

  /// A new connection has nothing to go fetch: it's drawn on the spot.
  late final status = ValueNotifier<ConnectionFormStatus>(
    isEditing ? ConnectionFormStatus.loading : ConnectionFormStatus.ready
  );

  /// Code of the chosen service, or empty if none has been chosen yet.
  ///
  /// It can't be changed in an edit: the stored credentials were gathered for
  /// one service and pointing them at another would leave values that mean
  /// nothing there. The backend rejects it (`provider_is_immutable`) and the
  /// picker doesn't even offer it.
  final provider = ValueNotifier<String>("");

  /// `true` while the save is in transit. The save button listens to it.
  final saving = ValueNotifier<bool>(false);

  /// Detail read in an edit. It's where it comes from which secrets are
  /// already stored (by name) and what the account is missing.
  ConnectionDetailModel? detail;

  /// Name and description that its fields are born with.
  ///
  /// They're stored as text and not written over the controllers because
  /// **when the connection arrives those fields don't exist yet**: in an edit
  /// the screen shows the spinner until the read comes back, so the inputs
  /// are built after [apply]. The page creates them already with this value
  /// set (`initial`), which also keeps the text from appearing a frame late.
  String initialName = "";
  String initialDescription = "";

  final headerForm = FormController();
  final configForm = FormController();

  /// Service fields, by key. See the class note on why they're reused when
  /// changing service.
  final _fields = <String, InputController>{};

  /// Controller of the field [field], creating it the first time.
  ///
  /// The type is translated into what the input knows how to do: a secret is
  /// drawn masked, a number with a numeric keyboard. The maximum length is the
  /// one the backend accepts per configuration value, which is more than
  /// enough for a permanent token or a PEM key.
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

  /// What was typed into a service field, or empty if it wasn't created (a
  /// service that never got drawn).
  String valueOf(String key) => _fields[key]?.value.trim() ?? "";

  /// Dumps into the form the connection that was just read.
  ///
  /// The secrets **aren't filled and it's not an oversight**: the backend
  /// doesn't return them, it only says under which keys one is stored. The
  /// field stays empty and the form lets you know it's already configured;
  /// writing something replaces it, leaving it blank keeps it.
  void apply(ConnectionDetailModel connection) {
    detail = connection;

    provider.value = connection.provider;

    initialName = connection.name;
    initialDescription = connection.description;

    // The plain fields are created already loaded, before anyone draws them:
    // created by the widget they'd arrive empty and would need filling
    // afterwards, with the text appearing a frame late.
    final schema = connection.schema;
    if (schema == null) return;

    for (final item in schema.settingsFields) {
      field(item).textController.text = connection.setting(item.key);
    }
  }

  /// Settings that travel in `SETTINGS`: the service's plain fields.
  ///
  /// **Everything** is sent, even the empty ones. In a creation the empty ones
  /// are discarded when building the body; in an edit they're what deletes a
  /// setting that was loaded, which is exactly what's needed to be able to
  /// correct a mispasted account id.
  Map<String, dynamic> settings(ConnectionProviderModel schema) {
    final settings = <String, dynamic>{};

    for (final item in schema.settingsFields) {
      settings[item.key] = valueOf(item.key);
    }

    return settings;
  }

  /// Secrets that travel in `CREDENTIALS`: only the ones written.
  ///
  /// An empty secret field means "leave the one that was there" and not
  /// "delete it": the form can't show the stored token, so leaving it blank is
  /// exactly what someone who came to change the account's name does.
  /// Sending it empty would delete the token of a connection that was working.
  Map<String, dynamic> credentials(ConnectionProviderModel schema) {
    final credentials = <String, dynamic>{};

    for (final item in schema.secretFields) {
      final value = valueOf(item.key);
      if (value.isNotEmpty) credentials[item.key] = value;
    }

    return credentials;
  }

  /// Body of the corresponding write: the creation or the edit.
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

  /// Marks the form as busy. Both parts at once: the inputs block listening
  /// to the `loading` of **their** form, and there are two.
  void busy(bool value) {
    saving.value = value;
    headerForm.loading.value = value;
    configForm.loading.value = value;
  }

  void dispose() {
    status.dispose();
    provider.dispose();
    saving.dispose();

    // The name and description are released by their form: they were always
    // drawn, so they're registered in it.
    headerForm.dispose();

    // The configuration ones are released by hand, and not with
    // `configForm.dispose()`, because a form only knows the controllers that
    // **got drawn** (they register when the input mounts). Here there are the
    // other kind: the ones [apply] created before the first frame and those of
    // a service that was chosen and then changed. Walking the map reaches
    // them all, and skipping the form's dispose avoids releasing twice the
    // ones that are in both.
    for (final input in _fields.values) {
      input.dispose();
    }

    _fields.clear();
    configForm.inputs.clear();
    configForm.data.clear();
    configForm.loading.dispose();
  }
}
