import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_request.dart';
import 'package:app/services/chats/chat_thread_service.dart';
import 'package:app/services/chats/chats_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/messages/chat/widgets/chat_bot_line.dart';
import 'package:app/screens/home/sections/messages/chat/widgets/chat_handover_button.dart';
import 'package:app/screens/home/sections/messages/tags/chat_stage_tag.dart';
import 'package:app/screens/home/sections/messages/tags/chat_tag_color.dart';
import 'package:app/screens/home/sections/messages/tags/chat_tags.dart';
import 'package:app/screens/modals/messages/chat_usage/_chat_usage.dart';

/// Who the customer is, where the conversation stands and what else is true
/// about it (tags, with since when and from which tickets), who answers it,
/// and the actions on it: take over / return to the assistant, assign, and the
/// menu (close by hand, mark read, AI cost, earlier sessions).
class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final thread = context.watch<ChatThreadService>();
    final detail = thread.detail!;
    final scheme = ThemeColor.of(context);
    final tags = chatTagsBeside(detail.stage, detail.tags);

    final subtitle = [
      if (detail.name.isNotEmpty) detail.contact,
      if (detail.line?.purpose.isNotEmpty ?? false) detail.line!.purpose
    ].join(" · ");

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSize.spaceM, AppSize.spaceS, AppSize.spaceS, AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ProfilePicture(kind: ProfileKind.customer, size: AppSize.action, label: detail.title),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Flexible(child: TextMedium(detail.title, bold: true, ellipsis: true, multiplier: 1.1)),
                  SizedBox(width: AppSize.gap),
                  Flexible(child: ChatStageTag(stage: detail.stage))
                ]),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: AppSize.gap * 0.5),
                  TextSmall(subtitle, ellipsis: true, color: scheme.text.secondary)
                ]
              ]
            )),
            SizedBox(width: AppSize.gap),
            const ChatHandoverButton(),
            SizedBox(width: AppSize.gap),
            _IconAction(
              icon: CI.employee,
              message: S.of(context).messages_assign,
              action: (context) => _assign(context)
            ),
            _IconAction(
              icon: CI.dots_horizontal,
              message: S.of(context).messages_options,
              action: (context) => _options(context)
            )
          ]),
          if (tags.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            ChatTags(tags: tags)
          ],
          SizedBox(height: AppSize.gap),
          ChatBotLine(detail: detail)
        ]
      )
    );
  }

  Future<void> _assign(BuildContext context) async {
    final thread = context.read<ChatThreadService>();
    final team = context.read<ChatsService>().team;
    final current = thread.detail?.assignee;

    final picked = await showSelectMenu(
      context: context,
      selected: current?.username,
      searchPlaceholder: S.of(context).messages_assign,
      options: [
        for (final person in team)
          SelectOption(value: person.username, placeholder: person.label, icon: CI.user),
        if (current != null)
          SelectOption(value: "", placeholder: S.of(context).messages_unassign, icon: CI.remove_image)
      ]
    );

    if (picked == null || picked.value == current?.username) return;

    await thread.assign(picked.value.isEmpty ? null : picked.value);
  }

  Future<void> _options(BuildContext context) async {
    final thread = context.read<ChatThreadService>();
    final detail = thread.detail!;
    final manual = context.read<ChatsService>().manualStages.map((stage) => stage.stage).toSet();

    // Without a catalog yet, the two stages the contract names are offered.
    bool can(String stage) => manual.isEmpty || manual.contains(stage);

    final closed = detail.stage.stage == kChatStageSold || detail.stage.stage == kChatStageEnded;

    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        if (!detail.answered)
          SelectOption(value: "read", placeholder: S.of(context).messages_mark_read, icon: CI.chekmark),
        if (detail.stage.stage != kChatStageSold && can(kChatStageSold))
          SelectOption(value: kChatStageSold, placeholder: S.of(context).messages_mark_sold, icon: CI.shopping_check),
        if (detail.stage.stage != kChatStageEnded && can(kChatStageEnded))
          SelectOption(value: kChatStageEnded, placeholder: S.of(context).messages_mark_ended, icon: CI.chack_circle),
        if (closed)
          SelectOption(value: "undo", placeholder: S.of(context).messages_undo_stage, icon: CI.arrow_left),
        SelectOption(value: "usage", placeholder: S.of(context).messages_usage, icon: CI.wallet),
        if (detail.sessions > 1)
          SelectOption(
            value: "sessions",
            placeholder: thread.allSessions
              ? S.of(context).messages_this_session
              : S.of(context).messages_all_sessions,
            icon: CI.list
          )
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "read":
        final marked = S.of(context).messages_marked_read;
        if (await thread.markRead()) FloatFlag.of().message(marked);
      case kChatStageSold:
        final confirmed = await showAlertModal(
          context: context,
          title: S.of(context).messages_sold_confirm_title,
          message: S.of(context).messages_sold_confirm_message,
          confirmText: S.of(context).messages_confirm,
          cancelText: S.of(context).messages_cancel
        );
        if (confirmed) await thread.setStage(kChatStageSold);
      case kChatStageEnded:
        await thread.setStage(kChatStageEnded);
      case "undo":
        await thread.setStage(null);
      case "usage":
        await showChatUsage(context, thread: thread);
      case "sessions":
        await thread.showAllSessions(!thread.allSessions);
    }
  }
}

/// An icon button whose menu anchors to itself.
class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.message, required this.action});

  final IconData icon;
  final String message;
  final Future<void> Function(BuildContext context) action;

  @override
  Widget build(BuildContext context) => Builder(builder: (context) => FeedbackButton(
    action: () => action(context),
    message: message,
    width: AppSize.action,
    height: AppSize.action,
    radius: AppSize.cornerInset(AppSize.gap),
    child: Center(child: Icon(icon, size: AppSize.text * 1.4, color: ThemeColor.of(context).icon))
  ));
}
