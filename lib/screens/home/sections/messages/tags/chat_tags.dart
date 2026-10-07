import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/chats/chat_model.dart';

import './chat_tag_chip.dart';

/// Every tag of a conversation, as chips that wrap. Nothing when there are none.
class ChatTags extends StatelessWidget {
  const ChatTags({super.key, required this.tags, this.dense = false});

  /// In drawing order, as the backend sends them.
  final List<ChatTag> tags;

  /// Smaller text, for the inbox rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSize.gap * 0.6,
      runSpacing: AppSize.gap * 0.6,
      children: [
        for (final tag in tags) ChatTagChip(tag: tag, dense: dense)
      ]
    );
  }
}
