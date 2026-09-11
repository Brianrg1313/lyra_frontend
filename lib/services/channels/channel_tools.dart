import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';

/// What kinds of content, in addition to text, the model **can understand and
/// produce** for a channel's replies.
///
/// With [voice] turned on, a WhatsApp audio is transcribed and answered by
/// speaking; with [images] or [video] the model looks at what is sent to it —a
/// product photo, the video of a fault— and responds about it; with [documents]
/// it reads the attachment.
///
/// **Each one makes processing more expensive**, and not a little: processing
/// audio, image or video costs quite a bit more than reading text, and it is
/// paid per conversation handled. That is why they are chosen one at a time and
/// the form says so where they are chosen, not in the fine print.
///
/// **They travel inside `SETTINGS`**, one boolean key per tool
/// ([settingKey]). See [ChannelAgentRole] for why the backend does not know
/// them.
enum ChannelTool {
  /// Listen to voice notes and reply by speaking.
  voice("tool_voice"),

  /// Look at and generate images.
  images("tool_images"),

  /// Look at videos.
  video("tool_video"),

  /// Read attached documents.
  documents("tool_documents");

  const ChannelTool(this.settingKey);

  /// Boolean key inside `SETTINGS`.
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
