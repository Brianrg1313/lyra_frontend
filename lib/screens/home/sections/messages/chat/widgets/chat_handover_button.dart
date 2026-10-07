import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_thread_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Take over (pause the assistant, with a duration) or return to the assistant.
class ChatHandoverButton extends StatelessWidget {
  const ChatHandoverButton({super.key});

  @override
  Widget build(BuildContext context) {
    final thread = context.watch<ChatThreadService>();
    final bot = thread.detail!.bot;
    final scheme = ThemeColor.of(context);

    if (!bot.enabled) return const SizedBox.shrink();

    if (bot.isPausedAt(DateTime.now())) {
      return Button(
        width: null,
        title: S.of(context).messages_return,
        leftIcon: Icon(CI.message_ai, size: AppSize.text * 1.2, color: scheme.button.text),
        action: thread.resume
      );
    }

    // [Button] and not [MainButton]: the main one always fills its width, and
    // this sits in a row next to the title.
    return Builder(builder: (context) => Button(
      width: null,
      title: S.of(context).messages_take,
      leftIcon: Icon(CI.user, size: AppSize.text * 1.2, color: scheme.button.text),
      action: () => _take(context)
    ));
  }

  Future<void> _take(BuildContext context) async {
    final thread = context.read<ChatThreadService>();

    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        SelectOption(value: "30", placeholder: S.of(context).messages_take_30m),
        SelectOption(value: "120", placeholder: S.of(context).messages_take_2h),
        SelectOption(value: "1440", placeholder: S.of(context).messages_take_24h),
        SelectOption(value: "0", placeholder: S.of(context).messages_take_manual)
      ]
    );

    if (picked == null) return;

    final minutes = int.tryParse(picked.value) ?? 0;

    await thread.pause(minutes: minutes > 0 ? minutes : null);
  }
}
