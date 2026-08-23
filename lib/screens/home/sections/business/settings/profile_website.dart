import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:url_launcher/url_launcher.dart';

// WIDGETS
import 'package:app/screens/modals/edit_business_field/_edit_business_field.dart';
import 'package:app/screens/modals/edit_business_field/business_field.dart';

import 'profile_field.dart';

/// El sitio de la empresa: la unica fila del perfil que **lleva a otro lado**.
///
/// Por eso no se dibuja como el resto de los datos sino dentro de una caja que
/// se puede tocar ([Surface.over]): un texto suelto en una ficha se lee, no se
/// toca, y nada en el renglon decia que ahi habia un enlace. La caja mide lo que
/// mide la direccion y no el ancho de la columna, para que lo que se puede tocar
/// sea lo que se puede tocar.
///
/// Sin sitio cargado no hay caja: queda el aviso de que el dato falta, como en
/// cualquier otra fila vacia. Una caja vacia invitaria a tocar algo que no
/// lleva a ningun lado.
///
/// La direccion se guarda como la escribe quien la carga (`ryzer.com`), asi que
/// abrirla es completarle el esquema: sin el, el sistema no sabe que es una
/// pagina web.
class BusinessProfileWebsite extends StatelessWidget {
  const BusinessProfileWebsite({super.key, required this.website});

  final String website;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: CI.link,
    label: S.of(context).business_profile_website,
    description: S.of(context).business_profile_website_note,
    action: ProfileAction(
      icon: website.isEmpty ? CI.plus : CI.edit,
      message: website.isEmpty
        ? S.of(context).business_profile_add(
            S.of(context).business_profile_website
          )
        : S.of(context).business_profile_edit(
            S.of(context).business_profile_website
          ),
      action: () => _edit(context)
    ),
    child: website.isEmpty ? _empty(context) : _link(context)
  );

  Widget _empty(BuildContext context) => TextMedium(
    S.of(context).business_profile_empty,
    color: ThemeColor.of(context).text.secondary
  );

  /// La direccion dentro de una caja que se abre. Alineada a la izquierda y
  /// midiendo su texto: es un boton, y un boton del ancho de la ficha no se lee
  /// como un enlace sino como una barra.
  Widget _link(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: FeedbackButton(
        action: () => _open(context),
        message: S.of(context).business_profile_website_open,
        radius: AppSize.cornerInset(AppSize.gap),
        color: scheme.surfaceOver,
        feedbackColor: scheme.line,
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.spaceXS,
          vertical: AppSize.gap
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: TextMedium(
              website,
              ellipsis: true,
              color: scheme.primary
            )),
            SizedBox(width: AppSize.gap),
            Icon(
              CI.link,
              size: AppSize.text,
              color: scheme.text.secondary
            )
          ]
        )
      )
    );
  }

  /// Abre el sitio en el navegador del sistema.
  ///
  /// Que no se pueda abrir se avisa: es lo unico que distingue una direccion
  /// mal cargada de un toque que no hizo nada, y el que la cargo es el unico
  /// que puede corregirla.
  ///
  /// Abrir es cosa del sistema y puede fallar por algo que no es la direccion
  /// —no hay navegador, el sistema lo niega—, y eso llega como excepcion. Se
  /// atrapa y se cuenta igual: lo que hay que saber es que el sitio no se
  /// abrio, y una excepcion suelta desde el toque de un boton no se la cuenta a
  /// nadie.
  Future<void> _open(BuildContext context) async {
    bool opened = false;

    final url = Uri.tryParse(_address);

    if (url != null) {
      try {
        opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (E) {
        if (kDebugMode) {
          print("No se pudo abrir $url: $E");
        }
      }
    }

    if (opened || !context.mounted) return;

    FloatFlag.of(context).error(
      message: S.of(context).business_profile_website_failed
    );
  }

  /// La direccion como la entiende el sistema. Lo guardado casi nunca trae
  /// esquema —se carga `ryzer.com`, que es como se dice— y sin el, `Uri` lo lee
  /// como una ruta de archivo.
  String get _address {
    final value = website.trim();

    return value.contains("://") ? value : "https://$value";
  }

  /// Cambiar el sitio es escribir, asi que se hace donde se escribe: el modal
  /// de un campo, igual que el resto de los datos de texto de la ficha.
  Future<void> _edit(BuildContext context) => showModal(
    context: context,
    title: website.isEmpty
      ? S.of(context).business_profile_add(
          S.of(context).business_profile_website
        )
      : S.of(context).business_profile_edit(
          S.of(context).business_profile_website
        ),
    builder: (BuildContext context) => EditBusinessFieldModal(
      label: S.of(context).business_profile_website,
      field: BusinessField.text(
        key: "WEBSITE",
        value: website,
        pattern: "[A-Za-z0-9_@.:/?&=#%~+-]",
        hint: S.of(context).business_profile_website_hint,
        min: 4,
        max: 255
      )
    )
  );
}
