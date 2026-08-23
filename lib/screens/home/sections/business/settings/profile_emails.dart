import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/modals/edit_business_email/_edit_business_email.dart';
import 'package:app/screens/modals/verify_business_email/_verify_business_email.dart';

import 'profile_field.dart';
import 'profile_tag.dart';

/// Una direccion de correo de la empresa, como fila del bloque de correos.
///
/// El nombre es como la llama la empresa —el suyo, o para que es—, la
/// explicacion es que se hace con ella y el valor la direccion, que se puede
/// seleccionar porque se usa afuera de la app.
///
/// Al lado de la direccion va si esta verificada, que es lo unico que dice si
/// **funciona**: una direccion es lo que alguien escribio en un formulario, y
/// hasta que no llego un codigo a esa casilla nadie sabe si lo que se le manda
/// llega o rebota. Se muestran los dos estados y no solo el malo: la fila sin
/// etiqueta no se leeria como verificada, se leeria como incompleta.
///
/// La accion de verificar va junto a la etiqueta y no arriba con las demas: es
/// la respuesta a lo que se acaba de leer ahi mismo, y arriba ya conviven
/// ascender, cambiar y borrar.
///
/// Las tres cosas que se le pueden hacer estan juntas arriba: ascenderla a
/// principal (solo si no lo es), cambiarla y borrarla. Ascender no pregunta
/// nada —es un cambio que se deshace ascendiendo otra— pero borrar si: la
/// direccion se va con su nombre y su proposito.
class ProfileEmailField extends StatelessWidget {
  const ProfileEmailField({super.key, required this.email});

  final BusinessEmailModel email;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: email.purpose.icon,
    label: email.title(context),
    // Que se hace con esta direccion, y no que es una direccion: la lista es de
    // correos, lo que cambia de uno a otro es a donde va lo que se escribe.
    // Vale incluso cuando la empresa le puso nombre propio ("Facturacion
    // Colombia"), porque el nombre dice cual es y no para que es.
    description: email.purpose.description(context),
    // La principal se marca arriba y no ordenandola primero a mano: ya llega
    // primera, pero eso no se ve, y cual es la que publica la empresa es lo
    // primero que se viene a mirar de esta lista.
    note: email.main ? S.of(context).business_email_main : null,
    action: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!email.main) ...[
          // Escrito y no un tilde: cual de las direcciones publica la empresa
          // es una decision, y un icono no dice cual se estaria tomando.
          ProfileTextAction(
            label: S.of(context).business_email_promote,
            action: () => _promote(context)
          ),
          SizedBox(width: AppSize.gap)
        ],
        ProfileAction(
          icon: CI.edit,
          message: S.of(context).business_profile_edit(
            S.of(context).business_email_address
          ),
          action: () => _edit(context)
        ),
        SizedBox(width: AppSize.gap),
        ProfileAction(
          icon: CI.trash,
          message: S.of(context).delete_business_email,
          action: () => _delete(context)
        )
      ]
    ),
    child: _value(context)
  );

  /// La direccion y, pegado a ella, si se comprobo que llega. Envuelven porque
  /// son tres cosas de largo variable —una direccion larga, la etiqueta y, si
  /// falta verificarla, el boton— y en una fila fija la ultima se recortaria.
  Widget _value(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSize.spaceXS,
    runSpacing: AppSize.gap,
    children: [
      TextMedium(email.email, lines: 2, ellipsis: true, selectable: true),
      ProfileTag(
        icon: email.verificationIcon,
        label: email.verificationLabel(context),
        color: email.verificationColor
      ),
      if (!email.verified) ProfileTextAction(
        label: S.of(context).business_email_verify,
        action: () => _verify(context)
      )
    ]
  );

  /// Abre la verificacion. Lo que pase adentro lo guarda el propio modal contra
  /// el servicio, que relee el perfil: aca no queda nada por hacer al cerrarse.
  Future<void> _verify(BuildContext context) => showModal(
    context: context,
    title: S.of(context).business_email_verify_title,
    builder: (BuildContext context) => VerifyBusinessEmailModal(email: email)
  );

  /// Ascender no avisa nada al salir bien: la etiqueta de principal se movio a
  /// esta fila y el boton de ascenderla desaparecio, que es todo lo que habia
  /// para contar. El error lo muestra el servicio.
  Future<void> _promote(BuildContext context) => context
    .read<BusinessService>()
    .editEmail(context, email.id, {"MAIN": true});

  Future<void> _edit(BuildContext context) => showModal(
    context: context,
    title: S.of(context).business_email_edit_title,
    builder: (BuildContext context) => EditBusinessEmailModal(email: email)
  );

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).business_email_delete_title,
      message: S.of(context).business_email_delete_message(email.email),
      confirmText: S.of(context).delete_business_email,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    final removed = await context.read<BusinessService>().removeEmail(
      context,
      email.id
    );

    if (!removed || !context.mounted) return;

    FloatFlag.of(context).message(S.of(context).business_email_deleted);
  }
}

/// El boton de agregar una direccion, para el titulo del bloque de correos.
///
/// Va en el titulo y no como una fila mas porque agregar no es un dato de la
/// empresa: es lo que se hace con la lista entera, incluso cuando esta vacia.
class ProfileEmailAdd extends StatelessWidget {
  const ProfileEmailAdd({super.key});

  @override
  Widget build(BuildContext context) => ProfileTextAction(
    label: S.of(context).business_email_add,
    action: () => showModal(
      context: context,
      title: S.of(context).business_email_add,
      builder: (BuildContext context) => const EditBusinessEmailModal()
    )
  );
}
