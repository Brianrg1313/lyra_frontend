import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/channel_list/channel_state_tag.dart';

/// Which channel this panel is, above everything that can be changed in it.
///
/// It repeats the card that opened it —the network's icon and name, the job
/// it does there, its state— and that repetition is the point: the panel
/// slides over a grid where several cards can share a network, so what
/// confirms the right one was opened is seeing the card again at the top.
///
/// It is drawn from the list's row and not from the detail, so it is there
/// from the first frame: everything it shows was already on the card, and
/// waiting for a read to repaint it would leave the panel blank while it
/// arrives.
class ChannelIdentity extends StatelessWidget {
  const ChannelIdentity({
    super.key,
    required this.channel,
    required this.label
  });

  final ChannelLiteModel channel;

  /// The network's name, as the card resolved it against the catalog.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // Only the icon is taken from the catalog: the name arrived already
    // resolved, and the catalog does not change once loaded, so this stops
    // listening as soon as it answered.
    final icon = context.select<ChannelCatalogService, IconData>(
      (catalog) => catalog.byCode(channel.provider)?.icon ?? CI.link
    );

    return Row(children: [
      Container(
        width: AppSize.button,
        height: AppSize.button,
        decoration: BoxDecoration(
          color: scheme.surfaceOver,
          borderRadius: BorderRadius.circular(
            AppSize.cornerInset(AppSize.spaceXS)
          )
        ),
        child: Center(child: Icon(
          icon,
          size: AppSize.text * 1.2,
          // Dimmed while paused, same as on the card: it is the first thing
          // looked at in both.
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
      SizedBox(width: AppSize.spaceS),
      ChannelStateTag(channel: channel)
    ]);
  }
}
