import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/chats/chats_service.dart';
import 'package:app/services/home/home_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/messages/chat/_chat.dart';
import 'package:app/screens/home/sections/messages/inbox/_inbox.dart';
import 'package:app/screens/home/sections/messages/start/_start.dart';

/// **The conversation desk**: the content of the `messages` section.
///
/// Two panels side by side, one third and two thirds: the inbox of
/// conversations the assistant holds with customers on the left, and the open
/// conversation on the right. The open one is state of this page and not a
/// URL: switching chats is constant while working, and a route per chat would
/// stack history nobody walks back through.
///
/// [ChatsService] lives here and not app-wide, like the sales services: what it
/// holds belongs to the company being looked at, and a business switch
/// remounts the section. The header search travels to the backend (`SEARCH`,
/// profile name or number), debounced.
///
/// A company with no channel gets [MessagesStart] instead: nothing can arrive
/// until one is connected. The channels are the app-wide [ChannelsService]'s,
/// read here too so the desk follows a channel created anywhere.
class MessagesSection extends StatefulWidget {
  const MessagesSection({super.key});

  @override
  State<MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends State<MessagesSection> {
  static const Duration _searchDelay = Duration(milliseconds: 350);

  final ChatsService _chats = ChatsService();

  late final ValueListenable<String> _query;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _query = context.read<HomeService>().searchQuery;
    _query.addListener(_onSearch);

    // Deferred: the reads notify, and notifying while mounting rebuilds mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _chats.load();
      context.read<ChannelsService>().load(context.read<BusinessService>().active.id);
    });
  }

  @override
  void dispose() {
    _query.removeListener(_onSearch);
    _searchDebounce?.cancel();
    _chats.dispose();

    super.dispose();
  }

  void _onSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDelay, () {
      if (mounted) _chats.applySearch(_query.value);
    });
  }

  /// Whether the last settled read of the channels found none. Kept through
  /// the reads that follow (a create leaves the list `idle` until reloaded),
  /// so the page does not flicker between the start and the desk; null until
  /// the first read settles.
  bool? _noChannels;

  @override
  Widget build(BuildContext context) {
    final status = context.select<ChannelsService, ChannelsStatus>((service) => service.status);

    // A failed read keeps the desk: the chats can still be there.
    if (status == ChannelsStatus.empty) _noChannels = true;
    if (status == ChannelsStatus.ready || status == ChannelsStatus.error) _noChannels = false;

    return switch (_noChannels) {
      null => const Surface(child: Center(child: Loading())),
      true => const MessagesStart(),
      false => _desk()
    };
  }

  Widget _desk() => ChangeNotifierProvider<ChatsService>.value(
    value: _chats,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: Surface(child: InboxPanel())),
        SizedBox(width: AppSize.gap),
        const Expanded(flex: 2, child: Surface(child: _OpenChat()))
      ]
    )
  );
}

/// The right panel: the selected conversation, keyed by id so every chat gets
/// a fresh [ChatPanel] (and its own thread service).
class _OpenChat extends StatelessWidget {
  const _OpenChat();

  @override
  Widget build(BuildContext context) {
    final selected = context.select<ChatsService, String?>((service) => service.selected);

    if (selected == null) {
      return SectionMessage(
        icon: CI.chat,
        title: S.of(context).messages_select_title,
        subtitle: S.of(context).messages_select_subtitle
      );
    }

    return ChatPanel(key: ValueKey("chat_$selected"), id: selected);
  }
}
