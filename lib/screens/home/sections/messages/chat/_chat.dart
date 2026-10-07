import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_thread_service.dart';
import 'package:app/services/chats/chats_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './chat_attention.dart';
import './chat_composer.dart';
import './chat_header.dart';
import './message_list.dart';

/// The right panel: one open conversation.
///
/// Mounted per chat id (the section keys it), so it owns a fresh
/// [ChatThreadService] for exactly that conversation. The header is drawn from
/// the inbox row until the detail arrives.
class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.id});

  final String id;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  late final ChatThreadService _thread;

  @override
  void initState() {
    super.initState();

    final inbox = context.read<ChatsService>();

    _thread = ChatThreadService(id: widget.id, inbox: inbox, row: inbox.rowOf(widget.id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _thread.load();
    });
  }

  @override
  void dispose() {
    _thread.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<ChatThreadService>.value(
    value: _thread,
    child: Consumer<ChatThreadService>(
      builder: (context, thread, _) {
        if (thread.status == ChatThreadStatus.error) {
          return SectionMessage(
            icon: CI.info,
            title: S.of(context).messages_thread_error_title,
            subtitle: S.of(context).messages_error_subtitle,
            action: thread.load,
            actionLabel: S.of(context).messages_retry
          );
        }

        if (thread.detail == null) return const Center(child: Loading());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ChatHeader(),
            const ChatAttentionBar(),
            Separator.horizontal(),
            const Expanded(child: MessageList()),
            Separator.horizontal(),
            const ChatComposer()
          ]
        );
      }
    )
  );
}
