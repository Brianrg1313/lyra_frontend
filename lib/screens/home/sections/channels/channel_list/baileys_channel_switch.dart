import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/baileys/baileys_client.dart';
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/baileys/baileys_session_status.dart';
import 'package:app/services/channels/channel_lite_model.dart';

// WIDGETS
import 'package:app/screens/modals/channels/baileys_pairing/_baileys_pairing.dart';

/// The switch of a WhatsApp Personal channel's card.
///
/// It replaces [ChannelCard]'s usual enabled/disabled switch for this one
/// provider: there is no `ENABLED` flag to flip here, the switch **is** the
/// control for `baileys_server`'s session — on starts it (scanning a QR the
/// first time, or resuming silently if it was already linked), off stops it
/// without losing the pairing (`BaileysService.deactivate`, a soft stop).
///
/// The switch's own state and color double as the status indicator: the
/// thumb color and its tooltip read directly off [BaileysSessionState], not
/// off a separate tag, because the switch is the one thing on this card that
/// is already looked at to know whether the channel is live.
class BaileysChannelSwitch extends StatefulWidget {
  const BaileysChannelSwitch({super.key, required this.channel});

  final ChannelLiteModel channel;

  @override
  State<BaileysChannelSwitch> createState() => _BaileysChannelSwitchState();
}

class _BaileysChannelSwitchState extends State<BaileysChannelSwitch> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final status = context
      .watch<BaileysService>()
      .statusOf(widget.channel.id);

    final scheme = ThemeColor.of(context);
    final (label, color) = _presentation(context, status.state, scheme);

    return Tooltip(
      message: label,
      child: Switch(
        value: status.state.isActive,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeThumbColor: color,
        // Locked while a call is in flight: tapping again mid-request would
        // race a second `activate`/`deactivate` against the first.
        onChanged: _busy ? null : (_) => _toggle(context, status)
      )
    );
  }

  (String, Color) _presentation(
    BuildContext context,
    BaileysSessionState state,
    SchemeColor scheme
  ) => switch (state) {
    BaileysSessionState.starting =>
      (S.of(context).baileys_status_starting, scheme.accent),
    BaileysSessionState.qrPending =>
      (S.of(context).baileys_status_qr_pending, scheme.accent),
    BaileysSessionState.connected =>
      (S.of(context).baileys_status_connected, scheme.primary),
    BaileysSessionState.reconnecting =>
      (S.of(context).baileys_status_reconnecting, scheme.accent),
    BaileysSessionState.error =>
      (S.of(context).baileys_status_error, scheme.snackBar.error),
    BaileysSessionState.loggedOut =>
      (S.of(context).baileys_status_logged_out, scheme.text.secondary),
    // The color is moot for these two — the switch is off, so Flutter draws
    // its inactive thumb and never reads [activeThumbColor] — but the label
    // still stays neutral rather than implying anything is amiss.
    BaileysSessionState.stopped =>
      (S.of(context).baileys_status_stopped, scheme.text.secondary),
    BaileysSessionState.unknown =>
      (S.of(context).baileys_status_unknown, scheme.text.secondary)
  };

  Future<void> _toggle(
    BuildContext context,
    BaileysSessionStatus current
  ) async {
    final service = context.read<BaileysService>();
    final turningOn = !current.state.isActive;

    setState(() => _busy = true);

    try {
      if (turningOn) {
        await linkBaileysChannel(context, widget.channel.id);
      } else {
        await service.deactivate(widget.channel.id);
      }
    } on BaileysClientException catch (_) {
      if (!context.mounted) return;

      FloatFlag.of(context).error(
        message: turningOn
          ? S.of(context).baileys_start_error
          : S.of(context).baileys_stop_error
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
