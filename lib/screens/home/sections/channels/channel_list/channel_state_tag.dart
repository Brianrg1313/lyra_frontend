import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_lite_model.dart';

/// La etiqueta de estado de un canal, en la fila del listado.
///
/// Un canal tiene **dos estados que no son lo mismo** y confundirlos hace
/// perder tiempo:
///
/// - `ready` — si tiene cargado todo lo que su red le pide. Un canal recien
///   registrado y todavia sin tokens es normal (se da de alta antes de que Meta
///   los emita) y simplemente no esta listo. No es un error: es que falta
///   terminarlo.
/// - `enabled` — el interruptor de la empresa. Un canal completo se puede
///   pausar sin perder su configuracion.
///
/// De ahi los tres carteles: pausado gana sobre lo demas —si esta apagado no
/// importa que este completo—, despues "falta configurar", y recien si esta
/// entero y encendido, "conectado".
class ChannelStateTag extends StatelessWidget {
  const ChannelStateTag({super.key, required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, color) = switch (channel) {
      // Pausado primero: es lo que explica que un canal completo no conteste.
      ChannelLiteModel(enabled: false) => (
        S.of(context).channel_state_paused,
        scheme.text.secondary
      ),
      ChannelLiteModel(ready: false) => (
        S.of(context).channel_state_pending,
        // El color de marca y no un rojo: falta terminarlo, no se rompio nada.
        scheme.accent
      ),
      _ => (S.of(context).channel_state_ready, scheme.primary)
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        // Un fondo apenas tenido en vez de uno lleno: la etiqueta acompana al
        // nombre del canal, no compite con el.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(label, color: color)
    );
  }
}
