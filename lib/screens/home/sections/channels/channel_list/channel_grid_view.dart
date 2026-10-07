import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';

import './channel_card.dart';

/// The channels laid out in a grid: as many columns as fit without a card
/// going past [ChannelCard.maxWidth], all of them stretched to fill the row.
///
/// Also where WhatsApp Personal channels get their first status read: as
/// soon as the list is drawn, their switches ask [BaileysService] what
/// `baileys_server` currently says about each one, so a channel already
/// linked shows as connected without anyone having to touch its switch
/// first. Stateful only for that — the grid itself has nothing else to keep
/// across rebuilds.
class ChannelGridView extends StatefulWidget {
  const ChannelGridView({super.key, required this.channels});

  final List<ChannelLiteModel> channels;

  @override
  State<ChannelGridView> createState() => _ChannelGridViewState();
}

class _ChannelGridViewState extends State<ChannelGridView> {
  @override
  void initState() {
    super.initState();
    _refreshBaileys();
  }

  @override
  void didUpdateWidget(ChannelGridView oldWidget) {
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
