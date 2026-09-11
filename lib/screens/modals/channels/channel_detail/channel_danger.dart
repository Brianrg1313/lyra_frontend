import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/baileys/baileys_client.dart';
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';

/// The two things that undo a channel instead of correcting it: unlinking the
/// number behind it and disconnecting it altogether.
///
/// They live at the foot of the panel, after everything that is edited, for
/// the same reason the company's deletion sits at the end of its profile: they
/// are not a value to fix, they are the end of everything above, and whoever
/// came in to change the agent's role should not run into them on the way.
///
/// Neither goes through the confirm/cancel bar. That bar is for the form,
/// which is one write held back until it is complete; these two happen the
/// moment they are confirmed and cannot be taken back by pressing cancel, so
/// each asks on its own instead ([showAlertModal], as every destructive
/// confirmation in this app does).
///
/// **Unlinking is not disconnecting**, and the two being next to each other is
/// exactly why the difference is spelled out on each one. Unlinking drops the
/// phone's WhatsApp link and leaves the channel standing —its role, its data
/// source, its place in the grid— ready for another QR; disconnecting takes
/// the channel and its stored credentials with it. Only WhatsApp Personal
/// channels have the first: every other network is linked by a token that is
/// replaced by typing over it, not by scanning anything.
class ChannelDanger extends StatefulWidget {
  const ChannelDanger({
    super.key,
    required this.channel,
    required this.label,
    required this.onUnlinked,
    required this.onDeleted
  });

  final ChannelLiteModel channel;

  /// The network's name, for the confirmation to say which channel is going.
  final String label;

  /// Called once the number is unlinked, so the panel rereads the channel.
  final Future<void> Function() onUnlinked;

  /// Called once the channel is gone. The panel closes: there is nothing left
  /// behind it to look at.
  final void Function() onDeleted;

  @override
  State<ChannelDanger> createState() => _ChannelDangerState();
}

class _ChannelDangerState extends State<ChannelDanger> {
  bool _busy = false;

  bool get _isPersonal =>
    widget.channel.provider == ChannelProviderModel.whatsappPersonalCode;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextSmall(
              S.of(context).channel_danger_section,
              color: scheme.text.secondary
            ),
            SizedBox(height: AppSize.spaceS),
            if (_isPersonal) ...[
              _Action(
                icon: CI.qr_code,
                title: S.of(context).baileys_unlink_action,
                explanation: S.of(context).baileys_unlink_explanation,
                // The unlink is severe but not final: the channel survives it
                // and a new QR undoes it, so it is not painted in red.
                tint: scheme.accent,
                busy: _busy,
                action: _unlink
              ),
              Separator.horizontal(
                margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
              )
            ],
            _Action(
              icon: CI.trash,
              title: S.of(context).delete_channel,
              explanation: S.of(context).channel_delete_explanation,
              tint: scheme.snackBar.error,
              busy: _busy,
              action: _delete
            )
          ]
        )
      )
    );
  }

  /// Drops the phone's link to this channel.
  ///
  /// The channel is reread afterwards and not just repainted: the pairing is
  /// held by the local sidecar, but whether the channel counts as ready is
  /// the backend's answer.
  Future<void> _unlink() async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).baileys_unlink_title,
      message: S.of(context).baileys_unlink_message,
      confirmText: S.of(context).baileys_unlink_action,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    setState(() => _busy = true);

    try {
      await context.read<BaileysService>().unlink(widget.channel.id);

      if (!mounted) return;

      FloatFlag.of(context).message(S.of(context).baileys_unlinked);

      await widget.onUnlinked();
    } on BaileysClientException catch (_) {
      if (mounted) {
        FloatFlag.of(context).error(
          message: S.of(context).baileys_unlink_error
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Disconnects the channel. The service removes the row from the list on
  /// its own, so the grid behind the panel is already right when it closes.
  Future<void> _delete() async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).channel_delete_title,
      message: S.of(context).channel_delete_message(widget.label),
      confirmText: S.of(context).delete_channel,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    setState(() => _busy = true);

    final removed = await context
      .read<ChannelsService>()
      .remove(context, widget.channel);

    if (!mounted) return;

    setState(() => _busy = false);

    // Failed: the service already showed why, and the channel is still there.
    if (!removed) return;

    FloatFlag.of(context).message(S.of(context).channel_deleted);

    widget.onDeleted();
  }
}

/// One irreversible action: what it does, in the line above, and the button
/// that does it.
///
/// The explanation goes **above** the button and not inside the confirmation:
/// what is lost is what makes the decision, and in the modal it would arrive
/// once the decision was already made. The modal only asks again.
///
/// The button is not painted solid in its colour. On a panel meant for
/// reading, a block of colour pulls the eye before any of the values above
/// it; the tint is where it has to be —the icon and the text— and the
/// background only lights up when it is pointed at.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.explanation,
    required this.tint,
    required this.busy,
    required this.action
  });

  final IconData icon;
  final String title;
  final String explanation;
  final Color tint;

  /// `true` while any of this block's actions is in flight. Both lock
  /// together: they are two ways of undoing the same channel and running one
  /// while the other is mid-flight has no meaning.
  final bool busy;

  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextSmall(
          explanation,
          lines: 4,
          ellipsis: true,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceXS),
        Align(alignment: Alignment.centerLeft, child: FeedbackButton(
          action: busy ? null : action,
          height: AppSize.button,
          message: title,
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
          radius: AppSize.cornerInset(AppSize.gap),
          color: scheme.surface,
          feedbackColor: tint.withValues(alpha: 0.15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppSize.text,
                color: busy ? scheme.text.secondary : tint
              ),
              SizedBox(width: AppSize.gap),
              TextSmall(title, color: busy ? scheme.text.secondary : tint)
            ]
          )
        ))
      ]
    );
  }
}
