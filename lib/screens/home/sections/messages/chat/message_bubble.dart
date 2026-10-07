import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_message_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/messages/chat_format.dart';
import 'package:app/screens/modals/shared/image_viewer/_image_viewer.dart';

/// One message. The customer's lean left; the company's lean right, tinted by
/// who wrote them: a person from the desk in the accent colour, the assistant
/// and automatic messages on the neutral surface, each labelled.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.grouped = false});

  final ChatMessage message;

  /// Continues a run from the same author: tighter spacing, no label.
  final bool grouped;

  /// Width of the thumbnail asked from the CDN for an image message.
  static const int _thumbnail = 480;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final outgoing = !message.incoming;

    final Color fill = switch (message.author) {
      ChatAuthorKind.operator => scheme.primary.withValues(alpha: 0.14),
      ChatAuthorKind.customer => scheme.background,
      _ => scheme.surfaceOver
    };

    final label = _author(context);

    return Padding(
      padding: EdgeInsets.only(top: grouped ? AppSize.gap * 0.5 : AppSize.spaceXS),
      child: LayoutBuilder(builder: (context, constraints) => Align(
        alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.72),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap * 1.4),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
            ),
            child: Column(
              crossAxisAlignment: outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!grouped && label.isNotEmpty) ...[
                  TextMedium(label, bold: true, multiplier: 0.8, color: scheme.text.secondary),
                  SizedBox(height: AppSize.gap * 0.6)
                ],
                if (message.media case final media?) ...[
                  _Picture(url: media.sized(_thumbnail), full: media.url),
                  SizedBox(height: AppSize.gap)
                ] else if (message.type == "audio") ...[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(CI.microphone, size: AppSize.text * 1.2, color: scheme.text.secondary),
                    SizedBox(width: AppSize.gap),
                    TextSmall(S.of(context).messages_audio, color: scheme.text.secondary)
                  ]),
                  SizedBox(height: AppSize.gap * 0.6)
                ],
                if (message.text.isNotEmpty)
                  TextMedium(message.text, lines: 1000, selectable: true),
                SizedBox(height: AppSize.gap * 0.6),
                _Footer(message: message)
              ]
            )
          )
        )
      ))
    );
  }

  String _author(BuildContext context) {
    if (message.incoming) return "";

    return switch (message.author) {
      ChatAuthorKind.bot => S.of(context).messages_author_bot,
      ChatAuthorKind.system => S.of(context).messages_author_system,
      ChatAuthorKind.operator => message.authorName.isNotEmpty
        ? message.authorName
        : S.of(context).messages_author_team,
      ChatAuthorKind.customer => ""
    };
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.url, required this.full});

  final String url;
  final String full;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final placeholder = Container(
      width: AppSize.action * 4,
      height: AppSize.action * 3,
      color: scheme.surfaceOver,
      alignment: Alignment.center,
      child: Icon(CI.image, color: scheme.text.secondary)
    );

    if (url.isEmpty) return placeholder;

    return FocusableWidget(
      action: () => showImageViewer(context, url: full),
      message: S.of(context).messages_image,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap * 2)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: AppSize.action * 6),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder
          )
        )
      )
    );
  }
}

/// Time and delivery state. Ticks only on outgoing messages.
class _Footer extends StatelessWidget {
  const _Footer({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final time = chatTimeLabel(context, message.date);

    if (message.incoming) {
      return TextSmall(time, multiplier: 0.85, color: scheme.text.secondary);
    }

    final Widget state;

    if (message.status == ChatMessageStatus.failed) {
      state = TextMedium(S.of(context).messages_status_failed, multiplier: 0.75, bold: true, color: scheme.chart.critical);
    } else if (message.queued) {
      state = TextSmall(S.of(context).messages_status_queued, multiplier: 0.85, color: scheme.chart.warning);
    } else {
      state = Icon(
        message.status == ChatMessageStatus.sent ? CI.check : CI.chekmark,
        size: AppSize.text,
        color: message.status == ChatMessageStatus.read ? scheme.primary : scheme.text.secondary
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      TextSmall(time, multiplier: 0.85, color: scheme.text.secondary),
      SizedBox(width: AppSize.gap),
      state
    ]);
  }
}
