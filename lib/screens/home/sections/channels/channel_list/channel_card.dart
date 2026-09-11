import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:app/screens/modals/channels/channel_detail/_channel_detail.dart';

import 'baileys_channel_switch.dart';
import 'channel_state_tag.dart';

/// Card of a channel, as it looks in the grid.
///
/// A channel no longer carries a name the company had to type in, so nothing
/// here is that free text. What identifies it is what it already has for
/// free: on top, its network —"WhatsApp", "Instagram"— read from the catalog
/// by [ChannelLiteModel.provider], with the job it does on it underneath
/// ([ChannelLiteModel.scopeName]) — a provider that answers several jobs
/// (messages, comments...) is one channel per job, so two cards can share the
/// same network and only the job tells them apart. Below that, **the table it
/// answers from, by name** — the one thing on the card that is the company's
/// own words, and therefore what tells two channels of the same network on the
/// same job apart at a glance; "1 table" said nothing to a company with four
/// of them. A channel without a source still says so, because answering from
/// memory is answering with made-up prices.
///
/// The switch is the company's own, and sits where an options button used to:
/// pausing a channel does not touch its configuration, only whether it
/// answers, and it is the one thing worth reaching without opening the card.
///
/// **The whole card is a button.** Tapping it —anywhere but the switch— opens
/// the channel's side panel.
class ChannelCard extends StatelessWidget {
  const ChannelCard({super.key, required this.channel});

  final ChannelLiteModel channel;

  /// Height of the card. Fixed so every row of the grid measures the same,
  /// whether or not a card has a pending tag to show.
  static double get height => AppSize.action * 2.6;

  /// Max width of a grid column. Wider than the product table cards: a card
  /// now carries a two-line header (network + job) and the switch needs room
  /// of its own on the same row, so a narrower ceiling would crowd them.
  static double get maxWidth => AppSize.action * 7;

  /// How the grid is laid out: how many cards fit per row, how much each one
  /// measures and how much air goes between them.
  static SliverGridDelegate get grid =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxWidth,
      mainAxisExtent: height,
      crossAxisSpacing: AppSize.gap,
      mainAxisSpacing: AppSize.gap
    );

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // From the catalog this takes **only the already resolved name and
    // icon** and not the whole provider: the catalog loads once and does not
    // change, so this stops listening to it as soon as it arrived.
    final (label, icon) = context
      .select<ChannelCatalogService, (String, IconData)>((catalog) {
        final provider = catalog.byCode(channel.provider);

        // Without the catalog (still loading, or failed) the raw code is
        // shown: "whatsapp" says less than "WhatsApp Business" but much more
        // than a blank, and the card does not depend on that read to exist.
        return (provider?.name ?? channel.provider, provider?.icon ?? CI.link);
      });

    return FeedbackButton(
      action: () => _open(context, label),
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: AppSize.button,
              height: AppSize.button,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(
                  AppSize.cornerInset(AppSize.spaceXS)
                )
              ),
              child: Center(child: Icon(
                icon,
                size: AppSize.text * 1.2,
                // A paused channel looks dimmed in its icon too: it is the
                // first thing looked at in the card.
                color: channel.enabled ? scheme.icon : scheme.text.secondary
              ))
            ),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextMedium(label, ellipsis: true, bold: true),
                if (channel.scopeName.isNotEmpty) TextSmall(
                  channel.scopeName,
                  ellipsis: true,
                  color: scheme.text.secondary
                )
              ]
            )),
            SizedBox(width: AppSize.gap),
            _EnabledSwitch(channel: channel)
          ]),
          SizedBox(height: AppSize.gap),
          // Only shown when it needs saying: a channel that is whole does not
          // need a "connected" badge repeating what the switch already says.
          if (!channel.ready) ...[
            ChannelStateTag(channel: channel),
            SizedBox(height: AppSize.gap)
          ],
          _Sources(channel: channel)
        ]
      )
    );
  }

  /// Opens the channel's side panel: what it is, everything about it that can
  /// be changed, and the two ways of undoing it.
  ///
  /// It slides from the right and leaves the grid in view next to it, the
  /// same as a table's settings: the card is what was being looked at when it
  /// was tapped, so it stays reachable while the panel is open.
  ///
  /// The network's name goes with it instead of being looked up again on the
  /// other side: it was already resolved here, fallback included, and the
  /// panel titling itself differently from the card that opened it would read
  /// as another channel.
  void _open(BuildContext context, String label) => showChannelDetail(
    context,
    channel: channel,
    label: label
  );
}

/// What the channel answers from, at the foot of its card.
///
/// The tables are **named**, each on its own surface: a channel carries no
/// name of its own any more, so the table is the only thing on the card
/// written by the company, and a count ("1 table") threw away the one word
/// that told two cards apart. The surface is what makes them read as things
/// and not as a sentence — a channel can hold more than one.
///
/// With no source it says exactly that, in words and not as an empty row:
/// that a channel reads from nothing is the single most important thing this
/// card can report, because it is what makes an agent invent prices.
class _Sources extends StatelessWidget {
  const _Sources({required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    if (channel.tables.isEmpty) {
      return Row(children: [
        Icon(CI.list, size: AppSize.text, color: scheme.text.secondary),
        SizedBox(width: AppSize.gap * 0.5),
        Expanded(child: TextSmall(
          S.of(context).channel_source_none,
          ellipsis: true,
          color: scheme.text.secondary
        ))
      ]);
    }

    // Every tag is flexible and none of them wraps: the card's height is
    // fixed so that every row of the grid measures the same, so what does not
    // fit is cut inside its own surface instead of pushing a second line the
    // card has no room for.
    return Row(children: [
      for (final (index, table) in channel.tables.indexed) ...[
        if (index > 0) SizedBox(width: AppSize.gap * 0.5),
        Flexible(child: Surface(
          color: scheme.surface,
          radius: AppSize.cornerInset(AppSize.spaceXS),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.gap,
            vertical: AppSize.gap * 0.4
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(CI.list, size: AppSize.text, color: scheme.text.secondary),
            SizedBox(width: AppSize.gap * 0.5),
            Flexible(child: TextSmall(table.name, ellipsis: true))
          ])
        ))
      ]
    ]);
  }
}

/// The company's switch, where the card's options button used to be: pausing
/// a channel does not lose its configuration, and is reversible with the same
/// click.
///
/// It sits inside the card's own [FeedbackButton] but is not swallowed by its
/// tap: Flutter resolves nested gesture regions from the inside out, so the
/// switch's own recognizer wins over the card's and opening the panel never
/// fires when the switch is what was pressed.
///
/// WhatsApp Personal has no `ENABLED` of its own worth flipping here — the
/// thing to turn on and off is the `baileys_server` session itself — so this
/// delegates to [BaileysChannelSwitch] for that one provider instead of
/// branching internally: the two controls share nothing but their position
/// on the card.
class _EnabledSwitch extends StatelessWidget {
  const _EnabledSwitch({required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) {
    if (channel.provider == ChannelProviderModel.whatsappPersonalCode) {
      return BaileysChannelSwitch(channel: channel);
    }

    return _channelToggle(context);
  }

  Widget _channelToggle(BuildContext context) => Tooltip(
    message: channel.enabled
      ? S.of(context).channel_pause
      : S.of(context).channel_resume,
    child: Switch(
      value: channel.enabled,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeThumbColor: ThemeColor.of(context).primary,
      onChanged: (_) => _toggle(context)
    )
  );

  /// Pauses or resumes the channel. Nothing is asked: it is reversible with
  /// the same click and not a piece of data is lost, the configuration stays
  /// intact.
  Future<void> _toggle(BuildContext context) async {
    // The message is built before: the service fixes the card on the spot
    // and this context may repaint while the change is in transit.
    final message = channel.enabled
      ? S.of(context).channel_paused
      : S.of(context).channel_resumed;

    final changed = await context.read<ChannelsService>().toggle(
      context,
      channel
    );

    // If it failed, the service already brought the card back to how it was
    // and showed the error.
    if (!changed) return;

    FloatFlag.of().message(message);
  }
}
