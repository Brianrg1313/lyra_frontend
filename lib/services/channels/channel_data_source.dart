import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';

/// De donde saca el modelo de IA lo que sabe cuando atiende un canal.
///
/// Un canal sin fuente contesta de memoria, que es lo mismo que decir que
/// inventa: esto es lo que lo ata a datos reales de la empresa.
///
/// Hoy solo una esta hecha. Las otras dos se muestran igual, apagadas, y no
/// porque sea bonito: quien conecta un canal necesita saber que agendar citas y
/// responder por documentos son cosas que van a existir, para no armar el canal
/// dos veces.
///
/// **Viaja dentro de `SETTINGS`** ([settingKey]), junto con la tabla elegida
/// ([tableSettingKey]) cuando corresponde. Ver [ChannelAgentRole] por que el
/// backend no conoce estas claves.
enum ChannelDataSource {
  /// Una tabla de productos de la seccion de productos: el modelo responde
  /// precios, stock y fichas leyendo de ahi.
  productTable("table", available: true),

  /// Un calendario de servicios, para agendar citas. Todavia no existe.
  serviceCalendar("calendar", available: false),

  /// Una base de conocimiento: informacion suelta con la que el modelo
  /// responde preguntas o arma piezas de marketing. Todavia no existe.
  knowledgeBase("knowledge", available: false);

  const ChannelDataSource(this.value, {required this.available});

  /// Codigo que se guarda en el canal.
  final String value;

  /// `false` mientras la fuente no este construida. El selector la muestra
  /// apagada y el formulario no la deja elegir.
  final bool available;

  /// Clave del ajuste dentro de `SETTINGS`.
  static const String settingKey = "data_source";

  /// Clave donde se guarda **cual** tabla de productos se eligio, cuando la
  /// fuente es [productTable]. Es el id de la tabla, no su nombre: renombrarla
  /// no puede desconectar el canal.
  static const String tableSettingKey = "data_table_id";

  static const ChannelDataSource initial = productTable;

  static ChannelDataSource from(String? raw) {
    final code = raw?.trim().toLowerCase();

    for (final source in values) {
      if (source.value == code) return source;
    }

    return initial;
  }

  /// `true` si al elegir esta fuente hay que decir ademas cual: la tabla de
  /// productos son varias, y el canal lee de una.
  bool get needsTable => this == productTable;

  String title(BuildContext context) => switch (this) {
    productTable => S.of(context).channel_source_table,
    serviceCalendar => S.of(context).channel_source_calendar,
    knowledgeBase => S.of(context).channel_source_knowledge
  };

  String subtitle(BuildContext context) => switch (this) {
    productTable => S.of(context).channel_source_table_hint,
    serviceCalendar => S.of(context).channel_source_calendar_hint,
    knowledgeBase => S.of(context).channel_source_knowledge_hint
  };

  IconData get icon => switch (this) {
    productTable => CI.list,
    serviceCalendar => CI.calendar,
    knowledgeBase => CI.bookmark
  };
}
