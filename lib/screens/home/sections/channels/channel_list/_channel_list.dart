import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import 'channel_card.dart';

/// Body of the channels section: the business's channels, in a grid.
///
/// It is the only thing that listens to [ChannelsService], so loading,
/// failing or fetching the channels does not rebuild the header above it.
///
/// Each state says what happened, and **not the same thing in different
/// words**: that the channels could not be read and that the business does
/// not have any yet are two situations with nothing in common —one is
/// retried, the other is solved by connecting an account— and confusing them
/// sends someone who is just starting out to check the connection.
class ChannelGrid extends StatelessWidget {
  const ChannelGrid({super.key, required this.onRetry});

  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ChannelsService>();

    return switch (service.status) {
      ChannelsStatus.loading || ChannelsStatus.idle =>
        const Center(child: Loading()),
      ChannelsStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).channels_error_title,
        subtitle: S.of(context).channels_error_subtitle,
        action: onRetry,
        actionLabel: S.of(context).channels_retry
      ),
      // The create button lives in the header above and stays in view, so
      // repeating it here would only add noise to a message that already
      // said everything it had to say.
      ChannelsStatus.empty => SectionMessage(
        icon: CI.ia,
        title: S.of(context).channels_empty_title,
        subtitle: S.of(context).channels_empty_subtitle
      ),
      ChannelsStatus.ready => _Grid(channels: service.channels)
    };
  }
}

/// The channels laid out in a grid: as many columns as fit without a card
/// going past [ChannelCard.maxWidth], all of them stretched to fill the row.
///
/// Also where WhatsApp Personal channels get their first status read: as
/// soon as the list is drawn, their switches ask [BaileysService] what
/// `baileys_server` currently says about each one, so a channel already
/// linked shows as connected without anyone having to touch its switch
/// first. Stateful only for that — the grid itself has nothing else to keep
/// across rebuilds.
class _Grid extends StatefulWidget {
  const _Grid({required this.channels});

  final List<ChannelLiteModel> channels;

  @override
  State<_Grid> createState() => _GridState();
}

class _GridState extends State<_Grid> {
  @override
  void initState() {
    super.initState();
    _refreshBaileys();
  }

  @override
  void didUpdateWidget(_Grid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only when the set of channels actually changed (a create, a delete):
    // re-reading on every rebuild would poll `baileys_server` far more than
    // the switches need.
    if (!listEquals(
      _whatsappPersonalIds(oldWidget.channels),
      _whatsappPersonalIds(widget.channels)
    )) {
      _refreshBaileys();
    }
  }

  void _refreshBaileys() {
    final ids = _whatsappPersonalIds(widget.channels);
    if (ids.isEmpty) return;

    // Deferred to the first frame, same as the rest of the section's loads:
    // triggering it mid-build would rebuild the tree while it is still
    // mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BaileysService>().refresh(ids);
    });
  }

  List<String> _whatsappPersonalIds(List<ChannelLiteModel> channels) => [
    for (final channel in channels)
      if (channel.provider == ChannelProviderModel.whatsappPersonalCode)
        channel.id
  ];

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: EdgeInsets.zero,
    itemCount: widget.channels.length,
    gridDelegate: ChannelCard.grid,
    itemBuilder: (context, index) => ChannelCard(channel: widget.channels[index])
  );
}
