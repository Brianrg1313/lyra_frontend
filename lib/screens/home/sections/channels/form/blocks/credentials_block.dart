import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_provider_model.dart';

// WIDGETS
import 'package:core/form.dart';

import '../widgets/form_block.dart';
import '../state/channel_form_controller.dart';

/// Las credenciales de la red: el id de la cuenta, el token de acceso, el
/// secreto de la app, el token de verificacion del webhook.
///
/// **Nada de esto esta escrito en esta app.** Los campos, su orden, cual es
/// secreto, cual es obligatorio y donde encontrar cada valor en la consola de
/// Meta salen del catalogo del backend, que es tambien quien decide en cual de
/// los dos objetos viaja cada uno (`SETTINGS` o `CREDENTIALS`). Una red que se
/// agregue del otro lado aparece con su formulario hecho, sin tocar esto.
///
/// Un canal se puede guardar con esto a medio llenar, y no es un descuido: se
/// registra "Instagram — Ventas" hoy y se pegan los tokens cuando Meta los
/// emita. Por eso los obligatorios se marcan pero no frenan el guardado; lo que
/// hacen es dejar el canal como "falta configurar" en el listado.
class CredentialsBlock extends StatelessWidget {
  const CredentialsBlock({
    super.key,
    required this.controller,
    required this.schema
  });

  final ChannelFormController controller;
  final ChannelProviderModel schema;

  @override
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).channel_credentials_title,
    subtitle: S.of(context).channel_credentials_subtitle(schema.name),
    child: Column(children: [
      // Los campos se dibujan en el orden del catalogo: los ids de cuenta
      // primero y los secretos al final, que es el orden en que se consiguen.
      //
      // La key es la clave del campo y no su posicion: al cambiar de red las
      // listas se cruzan —`app_secret` es el septimo campo de WhatsApp y el
      // quinto de Messenger, pero es el mismo campo con el mismo valor— y sin
      // key Flutter emparejaria por posicion, dejando un input dibujando el
      // controlador de otro campo. Con ella, los que se repiten entre dos redes
      // ni se enteran del cambio y los que no, se van y vuelven enteros.
      for (final field in schema.fields) _Field(
        key: ValueKey(field.key),
        controller: controller,
        field: field
      )
    ])
  );
}

/// Un campo del proveedor.
///
/// Un secreto ya guardado se muestra vacio y **no es un error**: el backend
/// nunca devuelve el valor de un token, solo dice bajo que clave hay uno. El
/// campo lo aclara ("ya configurado") y funciona como reemplazo: escribir algo
/// lo pisa, dejarlo en blanco lo conserva.
class _Field extends StatelessWidget {
  const _Field({super.key, required this.controller, required this.field});

  final ChannelFormController controller;
  final ChannelProviderField field;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final stored = controller.detail?.hasCredential(field.key) ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Input(
            title: _title(context),
            placeholder: stored
              ? S.of(context).channel_secret_stored
              : field.label,
            controller: controller.field(field),
            leftIcon: Icon(
              field.secret ? CI.key : CI.pen,
              color: scheme.icon
            )
          ),
          // La pista la escribe el backend y dice **donde** sacar el valor en
          // la consola del proveedor. Es lo unico que tiene quien configura, y
          // sin ella este formulario es una lista de campos imposibles.
          if (field.hint.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: AppSize.spaceS,
                bottom: AppSize.gap
              ),
              child: TextSmall(
                field.hint,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            )
        ]
      )
    );
  }

  /// El titulo del campo, marcando los que la red necesita si o si.
  ///
  /// Se marca con una palabra y no con un asterisco: el asterisco significa
  /// "no podes guardar sin esto", y aca si se puede.
  String _title(BuildContext context) => field.required
    ? "${field.label} · ${S.of(context).channel_field_required}"
    : field.label;
}
