import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './channel_grid_view.dart';

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
      ChannelsStatus.ready => ChannelGridView(channels: service.channels)
    };
  }
}
