import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/edit_business_field/business_field.dart';

import 'profile_block.dart';
import 'profile_field.dart';
import 'profile_incorporation.dart';
import 'profile_select.dart';

/// Quien es la empresa en papel: su razon social, su handle, a que se dedica,
/// con que identificador fiscal responde y desde cuando existe.
///
/// Es un bloque como los demas y no la cabecera del perfil: el nombre en
/// grande con la situacion legal va arriba de todo ([BusinessProfileHeader]) y
/// el logo en la columna de al lado, y esto son datos que se leen y se editan
/// uno por uno, como los de operacion o los de contacto.
///
/// El nombre esta en los dos lados y no es una repeticion: arriba se lee de
/// quien es la ficha, y aca se corrige. Lo mismo con el handle y el lema, que
/// se muestran donde se cargan.
///
/// Una empresa recien creada tiene el nombre, el sector y poco mas: el resto de
/// las filas se dibujan vacias, porque desde que existe `PUT /business/profile/`
/// son el unico lugar desde donde se completan (ver [ProfileField]).
///
/// Los juegos de caracteres y los largos de cada dato son **los del backend**
/// (`lib/extras/rules.json`), no una version parecida: lo que la ficha acepte y
/// el servidor no vuelve como un error que no se puede corregir sin adivinar, y
/// lo que la ficha rechace y el servidor acepte es un dato que no se puede
/// cargar.
class BusinessProfileIdentity extends StatelessWidget {
  const BusinessProfileIdentity({super.key, required this.profile});

  final BusinessProfileModel profile;

  /// El nombre corto es el que va en listas y menus, asi que no lleva
  /// puntuacion: letras (con tildes y eñe), digitos, espacios y guiones.
  static const _namePattern = "[A-Za-z0-9 _ñáéíóúÑÁÉÍÓÚ-]";

  /// El lema es una frase, asi que lleva la puntuacion de una: signos de
  /// apertura y cierre, comillas, parentesis y los simbolos que aparecen en un
  /// eslogan (`&`, `%`, `+`).
  static const _captionPattern =
    "[A-Za-z0-9 .,;:!¡?¿'\"()/&%@#+=*_üÜñáéíóúÑÁÉÍÓÚ-]";

  /// Letras (con tildes y dieresis), eñe, digitos y la puntuacion habitual de
  /// una razon social: `Acme S.A.`, `Foo & Bar, Ltd.` Es el mismo juego que
  /// acepta el alta: es el mismo nombre, escrito en otro momento.
  static const _legalNamePattern = "[A-Za-z0-9 .,&'()üÜñáéíóúÑÁÉÍÓÚ-]";

  /// El handle es para enlaces y busqueda, asi que no lleva espacios ni
  /// puntuacion suelta. El backend lo guarda en minusculas: escribirlo con
  /// mayusculas no es un error, se lo pasa a minusculas al guardarlo.
  static const _nicknamePattern = "[A-Za-z0-9._-]";

  /// Identificadores fiscales de cualquier pais: letras, digitos, puntos y
  /// guiones (`J-12345678-9`, `B12345678`).
  static const _taxIdPattern = "[A-Za-z0-9.-]";

  @override
  Widget build(BuildContext context) => ProfileBlock(
    title: S.of(context).business_profile_section_identity,
    fields: [
      // El nombre corto es lo unico de la identidad que no se puede vaciar: es
      // con lo que la empresa aparece nombrada en todas partes, y una fila del
      // selector sin texto no es una empresa sin nombre, es una fila rota.
      ProfileField(
        icon: CI.bookmark,
        label: S.of(context).business_profile_name,
        description: S.of(context).business_profile_name_note,
        value: profile.name,
        field: BusinessField.text(
          key: "NAME",
          value: profile.name,
          pattern: _namePattern,
          min: 1,
          max: 64,
          obligatory: true
        )
      ),
      ProfileField(
        icon: CI.pen,
        label: S.of(context).business_profile_caption,
        description: S.of(context).business_profile_caption_note,
        value: profile.caption,
        field: BusinessField.text(
          key: "DESCRIPTION",
          value: profile.caption,
          pattern: _captionPattern,
          min: 1,
          max: 255
        )
      ),
      ProfileField(
        icon: CI.documents,
        label: S.of(context).business_profile_legal_name,
        description: S.of(context).business_profile_legal_name_note,
        value: profile.legalName,
        field: BusinessField.text(
          key: "LEGAL_NAME",
          value: profile.legalName,
          pattern: _legalNamePattern,
          min: 2,
          max: 160
        )
      ),
      ProfileField(
        icon: CI.user_circle,
        label: S.of(context).business_profile_nickname,
        description: S.of(context).business_profile_nickname_note,
        // Se lee con arroba y se edita sin ella: el arroba es como se escribe
        // un handle, no parte del que se guarda. Sin handle no se escribe
        // ninguna: el arroba solo no es un dato.
        value: profile.nickname.isEmpty ? "" : "@${profile.nickname}",
        field: BusinessField.text(
          key: "NICKNAME",
          value: profile.nickname,
          pattern: _nicknamePattern,
          min: 1,
          max: 32
        )
      ),
      // El sector se elige de la misma lista con la que se crea la empresa, asi
      // que lo que se elige aca se lee igual en las dos pantallas.
      ProfileSelectField(
        icon: CI.store,
        label: S.of(context).business_profile_activity,
        description: S.of(context).business_profile_activity_note,
        field: BusinessField.select(
          key: "ACTIVITY_TYPE",
          value: profile.activity.value,
          options: [
            for (final activity in BusinessActivity.catalog) SelectOption(
              value: activity.value,
              placeholder: activity.label(context)
            )
          ]
        )
      ),
      ProfileField(
        icon: CI.safe_password,
        label: S.of(context).business_profile_tax_id,
        description: S.of(context).business_profile_tax_id_note,
        value: profile.taxId,
        selectable: true,
        field: BusinessField.text(
          key: "TAX_ID",
          value: profile.taxId,
          pattern: _taxIdPattern,
          min: 3,
          max: 32
        )
      ),
      // La fecha no se escribe de corrido: se carga en tres campos, uno por
      // parte (ver [BusinessProfileIncorporation]). Escrita entera habia que
      // acertarle al formato del backend, que no es el formato en el que nadie
      // escribe una fecha.
      BusinessProfileIncorporation(date: profile.incorporationDate),
      // La situacion legal ya se ve como etiqueta bajo el nombre; lo que no
      // cabe ahi es desde cuando esta verificada, que es un dato y no un
      // estado. No se edita: la otorga el proceso de verificacion.
      if (profile.verifiedDate != null) ProfileField(
        icon: CI.chack_circle,
        label: S.of(context).business_profile_verified_date,
        description: S.of(context).business_profile_verified_date_note,
        value: _date(context, profile.verifiedDate!)
      )
    ]
  );

  /// La fecha con el formato del idioma de la app. Lo resuelve
  /// [MaterialLocalizations] y no un formateador propio: es el mismo que ya usa
  /// todo lo demas de Flutter, y viene inicializado con los idiomas que la app
  /// declara.
  String _date(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatShortDate(value);

}
