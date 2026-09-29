import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/chats/chat_detail_model.dart';
import 'package:app/services/chats/chat_thread_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Opens what the open conversation session cost in AI.
///
/// The [thread] is handed in and provided again because a modal opens above
/// the section's providers.
Future<void> showChatUsage(BuildContext context, {required ChatThreadService thread}) => showModal(
  context: context,
  title: S.of(context).messages_usage_title,
  builder: (context) => ChangeNotifierProvider.value(
    value: thread,
    child: const ChatUsageModal()
  )
);

/// The session's spend: the total, the tokens behind it and the areas it went
/// to. Read-only.
///
/// It rereads the detail on opening: the spend moves with every turn and no
/// socket event carries it, so the figure from when the chat was opened would
/// be stale. Until the answer lands the last known figure shows.
class ChatUsageModal extends StatefulWidget {
  const ChatUsageModal({super.key});

  @override
  State<ChatUsageModal> createState() => _ChatUsageModalState();
}

class _ChatUsageModalState extends State<ChatUsageModal> {
  bool _reading = true;

  @override
  void initState() {
    super.initState();

    context.read<ChatThreadService>().refreshDetail().whenComplete(() {
      if (mounted) setState(() => _reading = false);
    });
  }

  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final usage = context.watch<ChatThreadService>().detail?.usage;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (usage == null)
            _reading
              ? Padding(padding: EdgeInsets.all(AppSize.spaceL), child: const Center(child: Loading()))
              : _Message(S.of(context).messages_usage_unavailable)
          else ...[
            _Totals(usage: usage),
            SizedBox(height: AppSize.spaceS),
            if (usage.isEmpty)
              _Message(S.of(context).messages_usage_none)
            else ...[
              _Tokens(usage: usage),
              _Areas(usage: usage)
            ]
          ],
          TextSmall(S.of(context).messages_usage_note, lines: 4, color: scheme.text.secondary)
        ]
      )
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.usage});

  final ChatUsage usage;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: SettingsStat(
      icon: CI.wallet,
      value: usageCost(context, usage.cost),
      label: S.of(context).messages_usage_cost,
      tint: ThemeColor.of(context).primary
    )),
    SizedBox(width: AppSize.spaceXS),
    Expanded(child: SettingsStat(
      icon: CI.ia,
      value: usageCompact(context, usage.input + usage.output),
      label: S.of(context).messages_usage_tokens
    )),
    SizedBox(width: AppSize.spaceXS),
    Expanded(child: SettingsStat(
      icon: CI.network,
      value: usageNumber(context, usage.requests),
      label: S.of(context).messages_usage_requests
    ))
  ]);
}

class _Tokens extends StatelessWidget {
  const _Tokens({required this.usage});

  final ChatUsage usage;

  @override
  Widget build(BuildContext context) => SettingsBlock(
    title: S.of(context).messages_usage_tokens_title,
    child: SettingsList(rows: [
      SettingsValue(
        icon: CI.arrow_top,
        label: S.of(context).messages_usage_input,
        value: usageNumber(context, usage.input),
        hint: S.of(context).messages_usage_input_hint
      ),
      if (usage.cached > 0) SettingsValue(
        icon: CI.save,
        label: S.of(context).messages_usage_cached,
        value: usageNumber(context, usage.cached),
        hint: S.of(context).messages_usage_cached_hint
      ),
      SettingsValue(
        icon: CI.arrow_down,
        label: S.of(context).messages_usage_output,
        value: usageNumber(context, usage.output),
        hint: S.of(context).messages_usage_output_hint
      )
    ])
  );
}

/// Only the areas that ran: five rows of zeros would bury the one that spent.
class _Areas extends StatelessWidget {
  const _Areas({required this.usage});

  final ChatUsage usage;

  @override
  Widget build(BuildContext context) {
    final ran = usage.areas.entries.where((entry) => entry.value.ran).toList();
    if (ran.isEmpty) return const SizedBox.shrink();

    return SettingsBlock(
      title: S.of(context).messages_usage_areas_title,
      child: SettingsList(rows: [
        for (final entry in ran)
          SettingsValue(
            icon: _icon(entry.key),
            label: _label(context, entry.key),
            value: usageCost(context, entry.value.cost),
            hint: S.of(context).messages_usage_area_line(
              usageNumber(context, entry.value.requests),
              usageCompact(context, entry.value.input),
              usageCompact(context, entry.value.output)
            )
          )
      ])
    );
  }

  static IconData _icon(String area) => switch (area) {
    "replies" => CI.message_ai,
    "routing" => CI.network,
    "media" => CI.image,
    "research" => CI.search,
    "embeddings" => CI.inventory,
    _ => CI.ia
  };

  /// An area the app does not know yet shows under its backend code rather
  /// than disappearing from a total it is part of.
  static String _label(BuildContext context, String area) => switch (area) {
    "replies" => S.of(context).messages_usage_area_replies,
    "routing" => S.of(context).messages_usage_area_routing,
    "media" => S.of(context).messages_usage_area_media,
    "research" => S.of(context).messages_usage_area_research,
    "embeddings" => S.of(context).messages_usage_area_embeddings,
    _ => area
  };
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
    child: TextMedium(text, lines: 3, color: ThemeColor.of(context).text.secondary)
  );
}

String _locale(BuildContext context) => Localizations.localeOf(context).toString();

/// USD. A session costs cents, so below a dollar four decimals are kept; a
/// non-zero amount under the last one is never written as zero.
String usageCost(BuildContext context, double value) {
  const smallest = 0.0001;
  final format = NumberFormat.currency(
    locale: _locale(context),
    symbol: r"$",
    decimalDigits: value >= 1 ? 2 : 4
  );

  if (value > 0 && value < smallest) return "< ${format.format(smallest)}";

  return format.format(value);
}

String usageNumber(BuildContext context, int value) =>
  NumberFormat.decimalPattern(_locale(context)).format(value);

/// `252K`: the exact count is in the tokens block.
String usageCompact(BuildContext context, int value) =>
  NumberFormat.compact(locale: _locale(context)).format(value);
