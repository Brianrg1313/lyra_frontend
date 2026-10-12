import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/channels/channel_list/_channel_list.dart';
import 'package:app/screens/modals/channels/create_channel/_create_channel.dart';

/// Channels: the content of the home's `channels` section.
///
/// A channel is an account on a network (a WhatsApp number, a Facebook page,
/// an Instagram profile) connected to the business, with an AI model answering
/// on the other side. The channel **is** the bot: there is no one without the
/// other.
///
/// A channel no longer carries a name or a description the company has to
/// type in: what identifies it is what it already has for free —its network
/// and the table it answers from— which is why the screen is a single panel
/// and not two: there is nothing left that needs a wide list of its own next
/// to a conversations panel that does not exist yet. The grid shows every
/// channel at a glance, with a switch on each one to pause it without opening
/// its form.
class ChannelsSection extends StatefulWidget {
  const ChannelsSection({super.key});

  @override
  State<ChannelsSection> createState() => _ChannelsSectionState();
}

class _ChannelsSectionState extends State<ChannelsSection> {
  @override
  void initState() {
    super.initState();

    // Loads notify their listeners; they are deferred to the first frame so a
    // rebuild is not triggered while the tree is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _load();

      // The catalog gives each card the name and icon of its network. It does
      // not belong to this screen: it is the same cache the create form uses,
      // so this only primes it if nobody did yet.
      context.read<ChannelCatalogService>().load();
    });
  }

  /// Requests the channels of the active business. The service caches per
  /// business, so this call does not hit the backend again if they are
  /// already loaded.
  void _load({bool force = false}) => context.read<ChannelsService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      SizedBox(
        height: AppSize.button,
        child: Row(children: [
          Expanded(child: TextMedium(
            S.of(context).channels,
            bold: true,
            ellipsis: true
          )),
          SizedBox(width: AppSize.gap),
          Button(
            width: null,
            title: S.of(context).create_channel,
            leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
            action: _create
          )
        ])
      ),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: ChannelGrid(onRetry: () => _load(force: true)))
    ])
  );

  /// Opens the creation panel. Unlike editing, a create starts from nothing —
  /// no name, no description to type, no existing configuration to wait
  /// for — so it fits a side panel instead of a whole sub-page.
  Future<void> _create() async {
    final created = await showCreateChannel(context);
    if (created != null) _load(force: true);
  }
}
