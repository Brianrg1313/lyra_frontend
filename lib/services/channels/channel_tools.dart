import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';

/// Que tipos de contenido, ademas de texto, puede **entender y producir** el
/// modelo que atiende un canal.
///
/// Con [voice] encendida un audio de WhatsApp se transcribe y se contesta
/// hablando; con [images] o [video] el modelo mira lo que le mandan —la foto de
/// un producto, el video de una falla— y responde sobre eso; con [documents]
/// lee lo adjunto.
///
/// **Cada una encarece el procesamiento**, y no poco: procesar audio, imagen o
/// video cuesta bastante mas que leer texto, y se paga por conversacion
/// atendida. Por eso se eligen de a una y el formulario lo dice donde se
/// eligen, no en la letra chica.
///
/// **Viajan dentro de `SETTINGS`**, una clave booleana por herramienta
/// ([settingKey]). Ver [ChannelAgentRole] por que el backend no las conoce.
enum ChannelTool {
  /// Escuchar notas de voz y contestar hablando.
  voice("tool_voice"),

  /// Mirar y generar imagenes.
  images("tool_images"),

  /// Mirar videos.
  video("tool_video"),

  /// Leer documentos adjuntos.
  documents("tool_documents");

  const ChannelTool(this.settingKey);

  /// Clave booleana dentro de `SETTINGS`.
  final String settingKey;

  String title(BuildContext context) => switch (this) {
    voice => S.of(context).channel_tool_voice,
    images => S.of(context).channel_tool_images,
    video => S.of(context).channel_tool_video,
    documents => S.of(context).channel_tool_documents
  };

  String subtitle(BuildContext context) => switch (this) {
    voice => S.of(context).channel_tool_voice_hint,
    images => S.of(context).channel_tool_images_hint,
    video => S.of(context).channel_tool_video_hint,
    documents => S.of(context).channel_tool_documents_hint
  };

  IconData get icon => switch (this) {
    voice => CI.microphone,
    images => CI.image,
    video => CI.video,
    documents => CI.documents
  };
}
