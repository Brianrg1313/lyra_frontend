import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/baileys/baileys_client.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_preset.dart';
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:app/screens/modals/channels/baileys_pairing/_baileys_pairing.dart';
import 'package:app/screens/modals/channels/create_channel/_create_channel.dart';

import './preset_card.dart';

/// What the messages section shows a company with no channel: without one no
/// conversation can arrive, so the desk would be an inbox that stays empty.
///
/// It offers ready-made channels ([ChannelPreset]) that open the create panel
/// already filled, and a blank one. A WhatsApp Personal channel goes straight
/// on to its QR, so the number is linked without visiting the channels
/// section. Once a channel exists the list reloads and the section turns into
/// the desk.
class MessagesStart extends StatefulWidget {
  const MessagesStart({super.key});

  @override
  State<MessagesStart> createState() => _MessagesStartState();
}

class _MessagesStartState extends State<MessagesStart> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChannelCatalogService>().load();
    });
  }

  Future<void> _create([ChannelPreset? preset]) async {
    final channels = context.read<ChannelsService>();
    final businessId = context.read<BusinessService>().active.id;

    final id = await showCreateChannel(context, preset: preset);
    if (id == null || !mounted) return;

    // Paired before reloading: the reload swaps this page for the desk, and
    // the pairing needs a mounted context to open on.
    if (preset == ChannelPreset.whatsappPersonal) {
      try {
        await linkBaileysChannel(context, id);
      } on BaileysClientException catch (_) {
        // The channel exists; its switch in the channels section retries.
        if (mounted) FloatFlag.of(context).error(message: S.of(context).baileys_start_error);
      }
    }

    channels.load(businessId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final catalog = context.watch<ChannelCatalogService>();

    final offers = {for (final preset in ChannelPreset.values) preset: preset.offerIn(catalog)};

    // What can be created first, what is coming after.
    final presets = [
      for (final MapEntry(:key, :value) in offers.entries) if (value == ChannelPresetOffer.ready) key,
      for (final MapEntry(:key, :value) in offers.entries) if (value == ChannelPresetOffer.soon) key
    ];

    final cards = <Widget>[
      for (final preset in presets) PresetCard(
        preset: preset,
        action: offers[preset] == ChannelPresetOffer.ready ? () => _create(preset) : null
      ),
      BlankPresetCard(action: _create)
    ];

    return Surface(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSize.padding),
        child: Center(child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppSize.action * 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSize.spaceL),
              TextLarge(S.of(context).messages_start_title, textAlign: TextAlign.center, lines: 2),
              SizedBox(height: AppSize.gap),
              // Narrower than the cards: a line that reads in one sweep.
              Center(child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: AppSize.action * 14),
                child: TextMedium(
                  S.of(context).messages_start_subtitle,
                  color: scheme.text.secondary,
                  textAlign: TextAlign.center,
                  lines: 4
                )
              )),
              SizedBox(height: AppSize.spaceL),
              if (catalog.status == ChannelCatalogStatus.loading) Padding(
                padding: EdgeInsets.only(bottom: AppSize.spaceM),
                child: const Center(child: Loading())
              ),
              if (catalog.status == ChannelCatalogStatus.error) Padding(
                padding: EdgeInsets.only(bottom: AppSize.spaceM),
                child: _CatalogError(onRetry: () => catalog.load(force: true))
              ),
              LayoutBuilder(builder: (context, constraints) {
                // As many columns as fit at a card's minimum width, every row
                // as tall as its tallest card so the exchanges line up.
                final columns = (constraints.maxWidth / (AppSize.action * 6.5)).floor().clamp(1, 3);

                return Column(children: [
                  for (int start = 0; start < cards.length; start += columns) Padding(
                    padding: EdgeInsets.only(top: start == 0 ? 0 : AppSize.spaceS),
                    child: IntrinsicHeight(child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = start; i < start + columns; i++) ...[
                          if (i > start) SizedBox(width: AppSize.spaceS),
                          Expanded(child: i < cards.length ? cards[i] : const SizedBox.shrink())
                        ]
                      ]
                    ))
                  )
                ]);
              })
            ]
          )
        ))
      )
    );
  }
}

/// The catalog did not load: only WhatsApp Personal and the blank card can be
/// offered until it does.
class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});

  final void Function() onRetry;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(child: TextSmall(
        S.of(context).channel_catalog_error,
        color: ThemeColor.of(context).text.secondary
      )),
      SizedBox(width: AppSize.gap),
      FeedbackButton(
        action: onRetry,
        color: ThemeColor.of(context).surfaceOver,
        height: AppSize.button,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
        child: Center(child: TextSmall(S.of(context).channels_retry))
      )
    ]
  );
}
