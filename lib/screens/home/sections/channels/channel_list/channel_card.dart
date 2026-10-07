import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';

// WIDGETS
import 'package:app/screens/modals/channels/channel_detail/_channel_detail.dart';

import './channel_card_sources.dart';
import './channel_enabled_switch.dart';
import './channel_state_tag.dart';

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
            ChannelEnabledSwitch(channel: channel)
          ]),
          SizedBox(height: AppSize.gap),
          // Only shown when it needs saying: a channel that is whole does not
          // need a "connected" badge repeating what the switch already says.
          if (!channel.ready) ...[
            ChannelStateTag(channel: channel),
            SizedBox(height: AppSize.gap)
          ],
          ChannelCardSources(channel: channel)
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
