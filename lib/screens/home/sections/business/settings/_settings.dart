import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

import 'profile_details.dart';

/// Pestana de ajustes: como esta configurada la empresa. Hoy es su perfil
/// —quien es, como opera, como se la contacta— que es lo que contesta
/// `GET /business/profile/`, en una sola columna de arriba abajo.
///
/// Se llama ajustes y no perfil porque es donde se **cambia** la empresa, no
/// donde se la mira: el perfil es lo unico que hay para configurar por ahora,
/// pero lo que venga —quien puede hacer que, como factura, que avisa— entra
/// aca y no en una pestana nueva. Por eso los widgets de adentro siguen
/// llamandose `profile_*`: son los del perfil, que es uno de los ajustes.
///
/// Arranca por la cabecera —el logo, y al lado el nombre en grande con la
/// situacion legal y el rol de quien mira— y sigue con los datos uno por uno,
/// agrupados por lo que contestan.
///
/// No hay una columna aparte para el logo: era una columna entera ocupada por
/// una sola imagen, y ese ancho es el que necesitan los datos, que son los que
/// se leen. Puesto junto al nombre, lo que identifica a la empresa se lee de
/// una sola vez y en el mismo lugar, en cualquier ancho de ventana.
///
/// El perfil no se pide aca: lo pide la pagina al montarse, porque el nombre
/// que trae es el de la cabecera y se ve desde cualquiera de las pestanas (ver
/// `BusinessDetailSection`). Esta solo mira como viene.
///
/// No trae superficie propia: la de la pagina es la del cuerpo, y esta pestana
/// es uno de sus contenidos. Las que si son superficies son las tarjetas de
/// adentro ([Surface.over]): una por cada grupo de datos. Son bloques sobre esa
/// hoja, no otra hoja.
class BusinessSettingsTab extends StatelessWidget {
  const BusinessSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();
    final profile = service.profile;

    return switch (service.profileStatus) {
      BusinessProfileStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).business_profile_error_title,
        subtitle: S.of(context).business_profile_error_subtitle,
        action: () => service.loadProfile(force: true),
        actionLabel: S.of(context).business_list_retry
      ),
      BusinessProfileStatus.ready when profile != null => ScrollableWidget(
        showBar: false,
        children: [BusinessProfileDetails(profile: profile)]
      ),
      _ => const Center(child: Loading())
    };
  }
}
