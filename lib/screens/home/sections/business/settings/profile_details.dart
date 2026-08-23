import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_language.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/edit_business_field/business_field.dart';

import 'country_flag.dart';
import 'profile_block.dart';
import 'profile_danger.dart';
import 'profile_header.dart';
import 'profile_emails.dart';
import 'profile_field.dart';
import 'profile_id.dart';
import 'profile_identity.dart';
import 'profile_phone.dart';
import 'profile_select.dart';
import 'profile_website.dart';

/// El perfil de la empresa: todo lo que **tiene cargado**, agrupado por lo que
/// contesta —quien es en papel, como opera, como se la contacta y de que cuenta
/// cuelga— y en un solo hilo de arriba abajo.
///
/// Arranca diciendo de quien es todo lo que sigue —el logo, y al lado el nombre
/// en grande con la situacion legal y si la empresa es de quien la mira— y
/// recien despues empiezan los datos (ver [BusinessProfileHeader]).
///
/// Casi todo el perfil es opcional. Lo que **se edita** se dibuja igual cuando
/// no esta cargado —la fila vacia es el unico lugar desde donde se lo carga
/// (ver [ProfileField])—; lo que escribe la plataforma y no se toca desde aca
/// desaparece cuando no esta, porque esa fila no ofreceria nada. Un bloque que
/// se queda sin filas tampoco se dibuja. Un perfil a medio llenar se ve corto,
/// no se ve roto ni lleno de guiones.
class BusinessProfileDetails extends StatelessWidget {
  const BusinessProfileDetails({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  Widget build(BuildContext context) {
    // Los grupos que pueden quedarse sin datos. La identidad no esta en la
    // lista porque no puede: el sector siempre viene.
    final optional = <ProfileBlock>[
      ProfileBlock(
        title: S.of(context).business_profile_section_operation,
        fields: _operation(context)
      ),
      ProfileBlock(
        title: S.of(context).business_profile_section_contact,
        fields: _contact(context)
      ),
      // Este bloque se dibuja siempre, aunque la empresa no tenga ninguna
      // direccion: es el unico lugar desde donde se agrega la primera.
      ProfileBlock(
        title: S.of(context).business_profile_section_emails,
        fields: _emails(context),
        action: const ProfileEmailAdd()
      ),
      ProfileBlock(
        title: S.of(context).business_profile_section_account,
        fields: _account(context)
      )
    ];

    final blocks = <Widget>[
      Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: BusinessProfileHeader(profile: profile),
      ),
      Separator.horizontal(),
      BusinessProfileIdentity(profile: profile),
      ...optional.where((block) => block.fields.isNotEmpty),
      // Borrar la empresa va al final de todo y solo para quien la creo: es lo
      // unico de la ficha que no se deshace, y no es un dato mas (ver
      // [BusinessProfileDanger]).
      if (profile.owner) BusinessProfileDanger(profile: profile)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: AppSize.padding),
          blocks[i]
        ]
      ]);
  }

  /// Como opera: donde esta, en que idioma y con que monedas trabaja.
  ///
  /// El pais y la moneda no salen de una lista escrita aca sino de los catalogos
  /// que trae `/init` ([CountryCatalogService], [CurrencyCatalogService]): la
  /// plataforma habilita una region o una moneda del lado del backend y esta
  /// ficha la ofrece sin que haya que publicar una version de la app. Por eso se
  /// los observa y no se los lee una sola vez: si el catalogo se relee con la
  /// ficha abierta, las listas se rearman solas.
  List<Widget> _operation(BuildContext context) => [
    _country(context),
    ProfileField(
      icon: CI.shop,
      label: S.of(context).business_profile_address,
      value: profile.address,
      field: BusinessField.text(
        key: "ADDRESS",
        value: profile.address,
        min: 5,
        max: 160
      )
    ),
    ProfileSelectField(
      icon: CI.chat,
      label: S.of(context).business_profile_language,
      description: S.of(context).business_profile_language_note,
      field: BusinessField.select(
        key: "LANGUAGE",
        value: profile.language,
        options: [
          for (final language in BusinessLanguage.values) SelectOption(
            value: language.tag,
            placeholder: language.name
          ),
          // Lo guardado puede no ser ninguno del catalogo: lleva region
          // (`es-ve`) o es un idioma que esta version todavia no ofrece. Se
          // agrega como una opcion mas para que la lista muestre lo que la
          // empresa tiene y no un campo vacio; elegir otra cosa lo reemplaza.
          if (profile.language.isNotEmpty &&
              BusinessLanguage.values.every((l) => l.tag != profile.language))
            SelectOption(
              value: profile.language,
              placeholder: BusinessLanguage.label(profile.language)
            )
        ]
      )
    ),
    _currency(context),
    // Las secundarias son una lista y no un dato: elegir varias no es lo que
    // hace este formulario, asi que por ahora se leen y se cambian donde se
    // configuran las monedas de la empresa.
    if (profile.currencies.isNotEmpty) ProfileField(
      icon: CI.list,
      label: S.of(context).business_profile_currencies,
      description: S.of(context).business_profile_currencies_note,
      value: profile.currencies.join(" · ")
    )
  ];

  /// El pais donde opera, elegido entre los que la plataforma tiene habilitados.
  ///
  /// La opcion lleva la bandera y el nombre del pais, que es como se lo
  /// reconoce. El codigo no se muestra: es el dato que viaja, no algo que
  /// alguien tenga que leer para elegir su pais.
  ///
  /// Sin catalogo se vuelve justamente a ese campo de dos letras. Es la unica
  /// salida honesta: un desplegable vacio no deja cargar el pais, y esta fila es
  /// el unico lugar de la app desde donde se lo carga.
  Widget _country(BuildContext context) {
    final catalog = context.watch<CountryCatalogService>();

    if (!catalog.isReady) {
      return ProfileField(
        icon: CI.home,
        label: S.of(context).business_profile_country,
        description: S.of(context).business_profile_country_note,
        value: profile.country,
        field: BusinessField.text(
          key: "COUNTRY",
          value: profile.country,
          pattern: "[A-Za-z]",
          hint: S.of(context).business_profile_country_hint,
          min: 2,
          max: 2
        )
      );
    }

    return ProfileSelectField(
      icon: CI.home,
      label: S.of(context).business_profile_country,
      description: S.of(context).business_profile_country_note,
      field: BusinessField.select(
        key: "COUNTRY",
        value: profile.country,
        options: [
          for (final country in catalog.countries) SelectOption(
            value: country.code,
            placeholder: country.name,
            leading: CountryFlag(country: country)
          ),
          // El pais guardado puede no estar en el catalogo: la region se
          // deshabilito despues de que la empresa se registrara. Se agrega como
          // una opcion mas —con el codigo por nombre, que es lo unico que se
          // sabe de el— para que la ficha muestre lo que la empresa tiene y no
          // una lista donde no esta lo suyo.
          if (profile.country.isNotEmpty &&
              catalog.byCode(profile.country) == null)
            SelectOption(
              value: profile.country,
              placeholder: profile.country
            )
        ]
      )
    );
  }

  /// La moneda en la que factura, elegida entre las que la plataforma tiene
  /// habilitadas.
  ///
  /// La opcion lleva el codigo y, debajo, el simbolo y el nombre: el codigo es
  /// el dato y el simbolo es con lo que se reconocen los precios de esta empresa
  /// en el resto de la app.
  ///
  /// Sin catalogo se cae a un campo de texto de tres letras, por lo mismo que el
  /// pais: es preferible escribir el codigo a mano a no poder cambiar la moneda.
  Widget _currency(BuildContext context) {
    final catalog = context.watch<CurrencyCatalogService>();

    if (!catalog.isReady) {
      return ProfileField(
        icon: CI.wallet,
        label: S.of(context).business_profile_currency,
        description: S.of(context).business_profile_currency_note,
        value: profile.currency,
        field: BusinessField.text(
          key: "CURRENCY",
          value: profile.currency,
          pattern: "[A-Za-z]",
          min: 3,
          max: 3
        )
      );
    }

    return ProfileSelectField(
      icon: CI.wallet,
      label: S.of(context).business_profile_currency,
      description: S.of(context).business_profile_currency_note,
      field: BusinessField.select(
        key: "CURRENCY",
        value: profile.currency,
        options: [
          for (final currency in catalog.currencies) SelectOption(
            value: currency.code,
            placeholder: currency.code,
            subtitle: currency.name.isEmpty
              ? currency.symbol
              : "${currency.symbol} · ${currency.name}"
          ),
          // Igual que con el pais: la moneda guardada puede haberse
          // deshabilitado, y esconderla dejaria la lista sin lo que la empresa
          // tiene hoy.
          if (profile.currency.isNotEmpty &&
              catalog.byCode(profile.currency) == null)
            SelectOption(
              value: profile.currency,
              placeholder: profile.currency,
              subtitle: profile.currency
            )
        ]
      )
    );
  }

  /// Como se la contacta, sin los correos: esos son una lista y tienen bloque
  /// propio.
  ///
  /// Los dos se dibujan aunque esten vacios, como los de identidad y por lo
  /// mismo: son datos que se editan, y esta fila es el unico lugar desde donde
  /// se cargan. Escondidas, una empresa que nunca cargo su sitio no tenia como
  /// cargarlo —que es la situacion de **todas** apenas el dato existe—.
  List<Widget> _contact(BuildContext context) => [
    BusinessProfilePhone(phone: profile.phone, country: profile.country),
    BusinessProfileWebsite(website: profile.website)
  ];

  /// Las direcciones de la empresa, la principal primero (las ordena el
  /// backend).
  ///
  /// Sin ninguna queda una fila vacia y no un aviso suelto: el bloque se dibuja
  /// igual —una empresa sin correos es justamente la que tiene que poder cargar
  /// uno— y una linea de texto gris en el lugar donde el resto de los grupos
  /// tiene datos se lee como que la lista no cargo. La fila dice de que dato se
  /// trata y que no esta, como cualquier otro campo sin llenar; con que
  /// cargarlo esta en el titulo del bloque ([ProfileEmailAdd]), porque agregar
  /// es de la lista y no de esta fila.
  List<Widget> _emails(BuildContext context) {
    if (profile.emails.isEmpty) {
      return [ProfileField(
        icon: CI.mail,
        label: S.of(context).business_email_address,
        description: S.of(context).business_email_empty,
        value: ""
      )];
    }

    return [
      for (final email in profile.emails) ProfileEmailField(email: email)
    ];
  }

  /// De que cuenta cuelga: el identificador con el que la nombra el backend y
  /// desde cuando esta registrada. Ninguno de los dos se edita: los pone la
  /// plataforma.
  List<Widget> _account(BuildContext context) => [
    BusinessProfileId(id: profile.id),
    if (profile.date != null) ProfileField(
      icon: CI.calendar,
      label: S.of(context).business_profile_created,
      value: MaterialLocalizations.of(context).formatShortDate(profile.date!)
    )
  ];
}
