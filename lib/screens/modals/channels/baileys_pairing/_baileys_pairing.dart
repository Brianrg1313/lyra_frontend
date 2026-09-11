import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/baileys/baileys_session_status.dart';

/// Opens the QR pairing modal for a WhatsApp Personal channel and watches
/// its session until it links (or the modal is dismissed).
///
/// [initial] is the status [BaileysService.activate] already returned —
/// normally `qr_pending` with the QR ready, which is why this is only ever
/// opened right after a successful `activate`, never on its own.
Future<void> showBaileysPairing(
  BuildContext context, {
  required String channelId,
  required BaileysSessionStatus initial
}) => showModal(
  context: context,
  title: S.of(context).baileys_pairing_title,
  builder: (context) => BaileysPairingModal(
    channelId: channelId,
    initial: initial
  )
);

/// Content of the pairing modal: the QR while waiting, a confirmation once
/// linked, or the error if the session could not come up.
///
/// It watches [BaileysService.watch] on its own instead of relying on
/// whatever else might poll the session, because it is the one place that
/// actually needs sub-second freshness — everywhere else in the channels
/// list, a status a few seconds stale is fine.
class BaileysPairingModal extends StatefulWidget {
  const BaileysPairingModal({
    super.key,
    required this.channelId,
    required this.initial
  });

  final String channelId;
  final BaileysSessionStatus initial;

  @override
  State<BaileysPairingModal> createState() => _BaileysPairingModalState();
}

class _BaileysPairingModalState extends State<BaileysPairingModal> {
  late BaileysSessionStatus _status = widget.initial;
  StreamSubscription<BaileysSessionStatus>? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = context
      .read<BaileysService>()
      .watch(
        widget.channelId,
        // Stops watching only once there is truly nothing left to wait for.
        // `reconnecting` is not one of those: right after the QR is scanned,
        // WhatsApp always closes the socket once with a "restart required"
        // reason before the real connection opens, which `WhatsappSession`
        // reports as `reconnecting` while it retries on its own — treating
        // that as terminal (as `!= qrPending && != starting` did) stopped
        // this watch a moment before the actual `connected` update arrived,
        // leaving the modal stuck on its loading state forever even though
        // the session went on to link successfully underneath it.
        until: (status) => status.state == BaileysSessionState.connected ||
          status.state == BaileysSessionState.error ||
          status.state == BaileysSessionState.loggedOut ||
          status.state == BaileysSessionState.stopped
      )
      .listen((status) {
        if (!mounted) return;

        setState(() => _status = status);

        if (status.state == BaileysSessionState.connected) {
          // A beat to actually see the confirmation before the modal closes
          // on its own — closing the instant it connects would read as the
          // modal glitching shut rather than as "done".
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSize.action * 6,
    child: Center(child: _content(context))
  );

  Widget _content(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return switch (_status.state) {
      BaileysSessionState.qrPending => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextSmall(
            S.of(context).baileys_pairing_instructions,
            lines: 3,
            ellipsis: true,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceM),
          _qrImage(context)
        ]
      ),
      BaileysSessionState.connected => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.check, size: AppSize.action, color: scheme.primary),
          SizedBox(height: AppSize.spaceS),
          TextMedium(S.of(context).baileys_pairing_connected, bold: true)
        ]
      ),
      BaileysSessionState.error || BaileysSessionState.loggedOut => TextSmall(
        S.of(context).baileys_pairing_error(_status.lastError ?? ""),
        lines: 4,
        ellipsis: true,
        color: scheme.text.secondary
      ),
      _ => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Loading(),
          SizedBox(height: AppSize.spaceS),
          TextSmall(
            S.of(context).baileys_pairing_waiting,
            color: scheme.text.secondary
          )
        ]
      )
    };
  }

  Widget _qrImage(BuildContext context) {
    final data = _status.qrImage;

    if (data == null) return const Loading();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSize.corner),
      child: Image.memory(
        _decode(data),
        width: AppSize.action * 5,
        height: AppSize.action * 5
      )
    );
  }

  /// `qrImage` travels as a `data:image/png;base64,...` URI — only the part
  /// after the comma is the actual PNG.
  Uint8List _decode(String dataUri) =>
    base64Decode(dataUri.split(",").last);
}
