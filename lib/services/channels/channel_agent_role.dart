import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';

/// Con que papel atiende el modelo de IA que contesta en un canal.
///
/// No es una capacidad tecnica sino el encargo: el mismo canal de WhatsApp
/// vende o da soporte segun lo que se elija aca, y de eso dependen el tono, que
/// hace ante una duda que no sabe contestar y hacia donde empuja la
/// conversacion.
///
/// **Viaja dentro de `SETTINGS`**, bajo [settingKey]. El backend no conoce este
/// concepto: guarda la configuracion de un canal como un objeto plano de
/// claves libres (`Channels.config`), justamente para que el producto pueda
/// agregar ajustes sin tocar la api. Por eso se lee de vuelta con el resto de
/// los settings al reabrir el formulario.
enum ChannelAgentRole {
  /// Vende: presenta productos, arma el pedido y cierra.
  seller("seller"),

  /// Da soporte: resuelve problemas de algo que el cliente ya compro.
  support("support"),

  /// Atiende en general: responde lo que venga sin empujar hacia la venta.
  agent("agent");

  const ChannelAgentRole(this.value);

  /// Codigo que se guarda. Es lo que queda escrito en el canal, asi que no se
  /// cambia sin migrar lo ya guardado.
  final String value;

  /// Clave del ajuste dentro de `SETTINGS`.
  static const String settingKey = "agent_role";

  /// El que arranca elegido: vender es para lo que se conecta un canal la
  /// primera vez.
  static const ChannelAgentRole initial = seller;

  /// Lee el valor guardado. Lo desconocido (o lo que falta, en un canal creado
  /// antes de que existiera este ajuste) cae en [initial].
  static ChannelAgentRole from(String? raw) {
    final code = raw?.trim().toLowerCase();

    for (final role in values) {
      if (role.value == code) return role;
    }

    return initial;
  }

  String title(BuildContext context) => switch (this) {
    seller => S.of(context).channel_role_seller,
    support => S.of(context).channel_role_support,
    agent => S.of(context).channel_role_agent
  };

  String subtitle(BuildContext context) => switch (this) {
    seller => S.of(context).channel_role_seller_hint,
    support => S.of(context).channel_role_support_hint,
    agent => S.of(context).channel_role_agent_hint
  };

  IconData get icon => switch (this) {
    seller => CI.cart_shopping,
    support => CI.support,
    agent => CI.user_circle
  };
}
