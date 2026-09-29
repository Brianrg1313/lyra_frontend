import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_thread_service.dart';

// WIDGETS
import 'package:core/form.dart';

/// The reply box. Enter sends.
///
/// Replying pauses the assistant on this conversation for 24 h (the backend's
/// default), so the hint says so while the assistant still holds it.
class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  /// Backend limit of `MESSAGE`.
  static const int _max = 4096;

  /// Formless: the [Input] owns and disposes it.
  final InputController _controller = InputController(key: "MESSAGE", max: _max);

  Future<void> _send() async {
    final thread = context.read<ChatThreadService>();
    final text = _controller.text.trim();

    if (text.isEmpty || thread.sending) return;

    final landed = await thread.send(text);
    if (landed == null || !mounted) return;

    // A message that opened a new session already moved the section to it
    // (`ChatsService.moved`), which remounts this box.
    _controller.textController.clear();
    _controller.focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final thread = context.watch<ChatThreadService>();
    final scheme = ThemeColor.of(context);
    final bot = thread.detail?.bot;
    final warn = bot != null && bot.enabled && !bot.isPausedAt(DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSize.spaceS, AppSize.spaceXS, AppSize.spaceS, AppSize.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warn) Padding(
            padding: EdgeInsets.only(left: AppSize.gap, bottom: AppSize.gap),
            child: TextSmall(S.of(context).messages_composer_hint, color: scheme.text.secondary)
          ),
          Row(children: [
            Expanded(child: Input(
              controller: _controller,
              placeholder: S.of(context).messages_composer_placeholder,
              buttonSpace: false,
              onSubmit: _send
            )),
            SizedBox(width: AppSize.gap),
            SizedBox.square(
              dimension: AppSize.action,
              child: thread.sending
                ? const Center(child: Loading())
                : FeedbackButton(
                    action: _send,
                    message: S.of(context).messages_send,
                    radius: AppSize.cornerInset(AppSize.gap),
                    color: scheme.primary,
                    child: Center(child: Icon(CI.arrow_right, size: AppSize.text * 1.4, color: scheme.surface))
                  )
            )
          ])
        ]
      )
    );
  }
}
