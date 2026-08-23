import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connections/connection_lite_model.dart';

/// La etiqueta de estado de una conexion, en la fila del listado.
///
/// Una cuenta conectada tiene **dos estados que no son lo mismo** y confundirlos
/// hace perder tiempo:
///
/// - `ready` — si tiene cargado todo lo que su servicio le pide. Una cuenta
///   recien registrada y todavia sin tokens es normal (se da de alta antes de que
///   Meta los emita) y simplemente no esta lista. No es un error: es que falta
///   terminarla.
/// - `enabled` — el interruptor de la empresa. Una cuenta completa se puede
///   pausar sin perder su configuracion ni los bots que corren sobre ella.
///
/// De ahi los tres carteles: pausada gana sobre lo demas —si esta apagada no
/// importa que este completa—, despues "falta configurar", y recien si esta
/// entera y encendida, "conectada".
class ConnectionStateTag extends StatelessWidget {
  const ConnectionStateTag({super.key, required this.connection});

  final ConnectionLiteModel connection;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, color) = switch (connection) {
      // Pausada primero: es lo que explica que una cuenta completa no conteste.
      ConnectionLiteModel(enabled: false) => (
        S.of(context).connection_state_paused,
        scheme.text.secondary
      ),
      ConnectionLiteModel(ready: false) => (
        S.of(context).connection_state_pending,
        // El color de marca y no un rojo: falta terminarla, no se rompio nada.
        scheme.accent
      ),
      _ => (S.of(context).connection_state_ready, scheme.primary)
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        // Un fondo apenas tenido en vez de uno lleno: la etiqueta acompana al
        // nombre de la cuenta, no compite con el.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(label, color: color)
    );
  }
}
