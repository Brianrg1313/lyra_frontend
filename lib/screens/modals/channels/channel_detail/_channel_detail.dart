import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/home/sections/channels/form/blocks/agent_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/credentials_block.dart';
import 'package:app/screens/home/sections/channels/form/blocks/data_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/payment_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/tools_picker.dart';
import 'package:app/screens/home/sections/channels/form/widgets/missing_banner.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

import 'channel_account.dart';
import 'channel_danger.dart';
import 'channel_identity.dart';
import 'edit_bar.dart';

/// Opens a channel's panel: what it is, what it is configured with, and the
/// three things that can be done to it — change it, unlink the number behind
/// it, disconnect it.
///
/// It opens from the channel's card and slides in from the right, leaving the
/// grid in view next to it: the card is what was being looked at when it was
/// tapped, so it stays reachable while the panel is open. Same as a table's
/// settings.
///
/// It returns nothing, unlike the create panel. What it writes it also
/// **refreshes on its own** (see [ChannelDetailModal]), because a panel that
/// can be closed by clicking outside cannot promise the caller an answer: a
/// channel saved and then dismissed with a click on the grid would report
/// "nothing happened" over a change that did.
Future<void> showChannelDetail(
  BuildContext context, {
  required ChannelLiteModel channel,
  required String label
}) async {
  final width = math.min(_panelWidth, MediaQuery.of(context).size.width * .55);

  await showSideModal(
    context: context,
    title: label,
    minWidth: width,
    maxWidth: width,
    builder: (context) => ChannelDetailModal(channel: channel, label: label)
  );
}

/// Width of the panel in a window with room for it: two columns of option
/// cards (`OptionGrid`'s own minimum, `AppSize.action * 4.5`, twice over)
/// plus the panel's margins — the same measurement the create panel takes,
/// because it draws the same blocks.
double get _panelWidth => AppSize.action * 10 + AppSize.padding * 2;

/// Everything about one channel, in the panel its card opens.
///
/// **It is edited here, in place.** The blocks are the very ones the create
/// panel and the edit page draw ([AgentPicker], [DataPicker], [ToolsPicker],
/// [CredentialsBlock]) rather than a read-only copy of them with a pencil
/// next to each row: what someone opens a channel to change is what it
/// answers as and what it reads from, and sending them through a second modal
/// to change either would be two panels deep for one dropdown.
///
/// Nothing is written as it is touched, which is the difference with the
/// table settings panel next door. A channel's blocks are one write on the
/// backend (`PUT /channels/`, which patches the settings and replaces the
/// table links in the same call), and someone correcting a badly pasted token
/// usually corrects the role in the same sitting: saving per row would be
/// four round trips for one visit, each able to fail on its own and leave the
/// channel half changed. So the panel keeps a **confirm/cancel pair**, and it
/// only exists once something actually differs from what the channel holds —
/// see [ChannelFormController.dirty].
///
/// The read is [ChannelsService.detail], the same one the edit page makes: it
/// brings the configuration, which secrets are already stored (by name, never
/// their value) and what the channel is still missing, all at once. It is not
/// cached anywhere — this is opened to see how the channel is *now*.
class ChannelDetailModal extends StatefulWidget {
  const ChannelDetailModal({
    super.key,
    required this.channel,
    required this.label
  });

  /// The row the card was drawn from. It is what lets the panel say which
  /// channel this is before the detail arrives.
  final ChannelLiteModel channel;

  /// The network's name as the catalog resolved it, already on the card. It
  /// is passed in rather than looked up again so the fallback to the raw code
  /// is the same one the card decided.
  final String label;

  @override
  State<ChannelDetailModal> createState() => _ChannelDetailModalState();
}

class _ChannelDetailModalState extends State<ChannelDetailModal> {
  // Owned by the panel: created when it opens, released when it closes.
  late final _controller = ChannelFormController(
    channelId: widget.channel.id
  );

  // The company's payment accounts, which are the payment block's options.
  // Owned here for the same reason the create panel owns its own: the finance
  // section that holds them lives *under* the navigator this panel is opened
  // on, so there is no provider to read them from.
  final _methods = MoneyMethodsService();

  @override
  void initState() {
    super.initState();

    // Deferred to the first frame so a rebuild is not triggered while the
    // tree is still mounting, same as the rest of the screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The catalog draws the credentials block. Normally the section already
      // requested it before this panel opened.
      context.read<ChannelCatalogService>().load();

      // The product tables are the selectable data source, from the same
      // cache the products section uses.
      context.read<TablesService>().load(
        context.read<BusinessService>().active.id
      );

      // What the channel may tell a customer to pay into.
      _methods.load();

      _open();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _methods.dispose();
    super.dispose();
  }

  /// Reads the channel. Brings its configuration, which secrets it already
  /// holds and its provider's description in a single call.
  Future<void> _open() async {
    final channel = await context
      .read<ChannelsService>()
      .detail(context, widget.channel.id);

    if (!mounted) return;

    if (channel == null) {
      _controller.status.value = ChannelFormStatus.error;
      return;
    }

    _controller.apply(channel);
    _controller.status.value = ChannelFormStatus.ready;
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<MoneyMethodsService>
    .value(value: _methods, child: _panel());

  /// The panel itself, under the accounts provider.
  Widget _panel() => Column(children: [
    ChannelIdentity(channel: widget.channel, label: widget.label),
    Separator.horizontal(
      margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
    ),
    Expanded(child: ValueListenableBuilder<ChannelFormStatus>(
      valueListenable: _controller.status,
      builder: (context, status, _) => switch (status) {
        ChannelFormStatus.loading => const Center(child: Loading()),
        ChannelFormStatus.error => SectionMessage(
          icon: CI.info,
          title: S.of(context).channel_open_error_title,
          subtitle: S.of(context).channel_open_error_subtitle
        ),
        ChannelFormStatus.ready => _body()
      }
    )),
    ChannelEditBar(
      controller: _controller,
      onCancel: _cancel,
      onSave: _save
    )
  ]);

  /// The channel as it can be changed, in one column.
  ///
  /// A single column and not the edit page's two: the panel is deliberately
  /// narrower than a page (the grid stays visible next to it), and four short
  /// blocks split in half read worse than stacked.
  ///
  /// The danger block goes last for the same reason the company's does: it is
  /// not a value to correct, it is the end of everything else, and whoever
  /// came in to change the role does not run into it.
  Widget _body() => ScrollableWidget(
    children: [
      MissingBanner(controller: _controller),
      // Only in the `ready` branch, which is the only one that has a detail
      // to read it from.
      if (_controller.detail != null)
        ChannelAccount(detail: _controller.detail!),
      AgentPicker(controller: _controller),
      DataPicker(controller: _controller),
      PaymentPicker(controller: _controller),
      ToolsPicker(controller: _controller),
      // Until the network is known there are no fields to draw: each one asks
      // for its own. Here it is known as soon as the detail lands, which is
      // before this is ever built.
      if (_schema != null)
        CredentialsBlock(controller: _controller, schema: _schema!),
      ChannelDanger(
        channel: widget.channel,
        label: widget.label,
        onUnlinked: _reload,
        onDeleted: () => Navigator.pop(context)
      )
    ]
  );

  /// Description of this channel's network.
  ///
  /// The channel's own is preferred over the catalog's: it comes attached to
  /// the detail and is the one that matches what is stored, even if the
  /// catalog has moved since.
  ChannelProviderModel? get _schema {
    final code = _controller.provider.value;
    if (code.isEmpty) return null;

    final schema = _controller.detail?.schema;
    if (schema != null && schema.provider == code) return schema;

    return context.read<ChannelCatalogService>().byCode(code);
  }

  /// Discards everything that was touched.
  ///
  /// The `setState` is not idle: [ChannelFormController.revert] puts the
  /// values back, but core's select only notices which option is chosen again
  /// when it is rebuilt, and undoing nothing but the table changes no
  /// notifier that would have rebuilt it. **Rebuilt, not remounted** — the
  /// inputs share their controllers with the widgets that would replace them,
  /// and a fresh select writing its label into one of them while the old one
  /// still listens is a `setState() during build` on a widget nobody is
  /// building.
  void _cancel() {
    _controller.revert();
    setState(() {});
  }

  /// Rereads the channel after something changed it, and puts the fresh
  /// values into the inputs.
  ///
  /// The form is locked while the read is in flight: leaving it typeable
  /// would let someone start correcting a field that is about to be
  /// overwritten by what comes back.
  Future<void> _reload() async {
    _controller.busy(true);

    await _open();

    if (!mounted) return;

    _controller.busy(false);

    // Same reason as [_cancel]: the values came back changed and the select
    // has to be rebuilt to notice which option they point at now.
    setState(() {});
  }

  /// Rereads the grid behind the panel.
  ///
  /// The panel does it itself instead of reporting back on close: it can be
  /// dismissed with a click on the grid, and a channel saved and then
  /// dismissed that way would tell the caller nothing happened. What the list
  /// shows —whether the channel is ready, which table it answers from— is
  /// decided by the backend on the write, so it is a real reread and not a
  /// row patched in memory.
  void _reloadList() => context.read<ChannelsService>().load(
    context.read<BusinessService>().active.id,
    force: true
  );

  /// Saves what was touched.
  ///
  /// The network cannot change here and the credentials may be left
  /// half-filled on purpose — a channel is registered before Meta issues its
  /// tokens — so the only thing asked for is that the data source be
  /// complete: choosing "product table" and not saying which leaves the agent
  /// with nothing to read, which is not a half-configured channel but a
  /// misconfigured one.
  Future<void> _save() async {
    if (_controller.saving.value) return;

    final schema = _schema;

    if (schema == null) {
      FloatFlag.of(context).error(message: S.of(context).channel_type_missing);
      return;
    }

    if (_controller.source.value.needsTable && _controller.tableId.isEmpty) {
      FloatFlag.of(context).error(
        message: S.of(context).channel_source_missing
      );
      return;
    }

    _controller.busy(true);

    final saved = await context.read<ChannelsService>().edit(
      context,
      _controller.payload(schema)
    );

    if (!mounted) return;

    // Failed: the service already showed the error and the panel keeps
    // everything typed, which is the only reasonable thing when someone just
    // pasted four tokens.
    if (!saved) {
      _controller.busy(false);
      return;
    }

    FloatFlag.of(context).message(S.of(context).channel_saved);

    _reloadList();

    // Reread instead of settling on what was sent: whether the channel ended
    // up ready is decided by the backend against what that network asks for,
    // and which secrets it now holds is only knowable from its answer.
    await _reload();
  }
}
