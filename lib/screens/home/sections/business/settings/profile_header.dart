import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';

import 'profile_logo.dart';
import 'profile_tag.dart';

/// De quien es todo lo que sigue: el logo de la empresa y, al lado, su nombre
/// en grande con en que situacion legal esta y si es de quien la esta mirando.
///
/// Abre el perfil porque no es una ficha que se mira de reojo: es el titulo de
/// lo que se esta leyendo. Puesto al costado obligaba a cruzar la pantalla para
/// saber de que empresa era el telefono que se estaba corrigiendo; puesto
/// arriba se lee una vez y vale para todo lo de abajo.
///
/// El logo esta aca y no en una columna propia por lo mismo: es la otra mitad
/// de la misma presentacion —lo unico que se reconoce sin leerlo—, y una
/// columna entera para una sola imagen le sacaba el ancho a los datos, que es
/// lo que si lo necesita. Va primero porque es lo que se reconoce de un
/// vistazo: se ve de que empresa es la ficha antes de leer el nombre.
///
/// Lleva el nombre y no lo demas que identifica a la empresa —el handle, el
/// lema— porque esos son datos y estan cargados como tales unas lineas mas
/// abajo (ver [BusinessProfileIdentity]). Escribirlos aca era escribirlos dos
/// veces en la misma pantalla.
///
/// Las dos etiquetas si van aca aunque no sean datos que se editan: cambian
/// como se lee todo el resto. Una empresa sin verificar opera con limites, y
/// que la ficha sea de uno o de otro decide que se puede hacer con ella.
class BusinessProfileHeader extends StatelessWidget {
  const BusinessProfileHeader({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      BusinessProfileLogo(profile: profile),
      SizedBox(width: AppSize.padding),
      // El texto se lleva todo el ancho que sobra: el logo mide lo mismo
      // siempre, y lo que se parte en varios renglones es el nombre.
      Expanded(child: _identity(context))
    ]
  );

  /// El nombre y, debajo, como esta la empresa: verificada o no, y de quien es.
  Widget _identity(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextLarge(profile.name, lines: 2, ellipsis: true),
        SizedBox(height: AppSize.spaceXS),
        // Envuelven porque son dos etiquetas de largo variable: en una fila
        // fija, la segunda se recortaria en una ventana angosta.
        Wrap(
          spacing: AppSize.gap,
          runSpacing: AppSize.gap,
          children: [
            ProfileTag(
              icon: profile.verification.icon,
              label: profile.verification.label(context),
              color: profile.verification.color
            ),
            if (profile.owner) ProfileTag(
              icon: CI.user,
              label: S.of(context).business_profile_owner,
              color: scheme.primary
            )
          ]
        )
      ]
    );
  }
}
