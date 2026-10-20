import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_detail_model.dart';
import 'package:app/services/chats/chat_thread_service.dart';

// WIDGETS
import 'package:core/form.dart';

/// One question the assistant left with the team, and the box a person answers
/// it in. The answer goes **to the assistant, not to the customer**: it tells
/// them at once, in its own words, and the purchase carries on where it was
/// instead of a person stepping into it (and pausing it). Enter sends.
class ChatQuestionAnswer extends StatefulWidget {
  const ChatQuestionAnswer({super.key, required this.question});

  final ChatQuestion question;

  @override
  State<ChatQuestionAnswer> createState() => _ChatQuestionAnswerState();
}

class _ChatQuestionAnswerState extends State<ChatQuestionAnswer> {
  /// Backend limit of `ANSWER`.
  static const int _max = 1000;

  /// Formless: the [Input] owns and disposes it.
  final InputController _controller = InputController(key: "ANSWER", max: _max);

  Future<void> _send() async {
    final thread = context.read<ChatThreadService>();
    final text = _controller.text.trim();

    if (text.isEmpty || thread.busy) return;

    final relay = await thread.answer(questionId: widget.question.id, text: text);
    if (relay == null || !mounted) return;

    final s = S.of(context);

    FloatFlag.of(context).message(switch (relay) {
      ChatRelay.now => s.messages_question_relayed,
      ChatRelay.paused => s.messages_question_relay_paused,
      ChatRelay.closed => s.messages_question_relay_closed
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = context.watch<ChatThreadService>();
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextSmall(widget.question.text, lines: 4, selectable: true),
        SizedBox(height: AppSize.gap * 0.6),
        Row(children: [
          Expanded(child: Input(
            controller: _controller,
            placeholder: S.of(context).messages_question_placeholder,
            buttonSpace: false,
            onSubmit: _send
          )),
          SizedBox(width: AppSize.gap),
          SizedBox.square(
            dimension: AppSize.action,
            child: thread.busy
              ? const Center(child: Loading())
              : FeedbackButton(
                  action: _send,
                  message: S.of(context).messages_question_send,
                  radius: AppSize.cornerInset(AppSize.gap),
                  color: scheme.primary,
                  child: Center(child: Icon(CI.arrow_right, size: AppSize.text * 1.4, color: scheme.surface))
                )
          )
        ])
      ]
    );
  }
}
