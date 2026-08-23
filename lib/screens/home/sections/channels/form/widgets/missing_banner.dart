import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_provider_model.dart';

import '../state/channel_form_controller.dart';

/// Que le falta a un canal para poder funcionar, arriba de su formulario.
///
/// Solo aparece editando uno incompleto, que es el caso normal y no una
/// anomalia: un canal se registra antes de que Meta emita sus tokens y se
/// vuelve despues a terminarlo. Cuando se vuelve, esto es lo que dice **a que**
/// se volvio, sin tener que recorrer quince campos buscando cual quedo vacio.
///
/// Los nombres salen del esquema del proveedor y no de las claves crudas: el
/// backend responde `missing: ["access_token", "app_secret"]` y lo que hay que
/// leer es "Access token" y "App secret".
class MissingBanner extends StatelessWidget {
  const MissingBanner({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail;

    if (detail == null || detail.ready || detail.missing.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = ThemeColor.of(context);
    final schema = detail.schema;

    // La clave cruda es el ultimo recurso: si el esquema no vino, "access_token"
    // dice menos que "Access token" pero sigue siendo la pista correcta.
    final labels = [
      for (final key in detail.missing) _labelOf(schema, key)
    ];

    return Container(
      margin: EdgeInsets.only(bottom: AppSize.spaceM),
      padding: EdgeInsets.all(AppSize.spaceS),
      decoration: BoxDecoration(
        color: scheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CI.info, size: AppSize.text * 1.2, color: scheme.accent),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(S.of(context).channel_missing_title, bold: true),
              SizedBox(height: AppSize.gap),
              TextSmall(
                labels.join(" · "),
                lines: 2,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ))
        ]
      )
    );
  }

  /// Etiqueta de una clave segun el esquema del proveedor.
  static String _labelOf(ChannelProviderModel? schema, String key) {
    for (final field in schema?.fields ?? const <ChannelProviderField>[]) {
      if (field.key == key) return field.label;
    }

    return key;
  }
}
