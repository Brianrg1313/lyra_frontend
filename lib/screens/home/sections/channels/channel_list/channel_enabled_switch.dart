import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';

import './baileys_channel_switch.dart';

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
class ChannelEnabledSwitch extends StatelessWidget {
  const ChannelEnabledSwitch({super.key, required this.channel});

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
