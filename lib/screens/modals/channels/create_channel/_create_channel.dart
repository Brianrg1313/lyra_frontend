import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:core/button.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

import 'package:app/screens/home/sections/channels/form/blocks/agent_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/credentials_block.dart';
import 'package:app/screens/home/sections/channels/form/blocks/data_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/payment_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/provider_picker.dart';
import 'package:app/screens/home/sections/channels/form/blocks/tools_picker.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// Opens the creation of a channel in a side panel, over the `channels`
/// section.
///
/// It used to be a whole sub-page ([ChannelFormSection]'s old create route):
/// that made sense back when a channel needed a name and a description typed
/// in, network credentials and every other decision on the same screen.
/// Neither is asked for any more, and what is left — pick a network, pick a
/// role, pick a source, paste the tokens once they exist — fits a panel the
/// same way creating a table does.
///
/// Editing stays a page (`ChannelFormSection`): it opens against a channel
/// that already has credentials, a role, sources and possibly things missing,
/// and that reads better with room of its own.
///
/// Returns `true` if a channel was created, so the list knows to reload;
/// `false` if the panel was closed without saving.
Future<bool> showCreateChannel(BuildContext context) async {
  final width = math.min(_panelWidth, MediaQuery.of(context).size.width * .55);

  final created = await showSideModal(
    context: context,
    title: S.of(context).create_channel,
    minWidth: width,
    maxWidth: width,
    builder: (context) => const CreateChannelModal()
  );

  return created == true;
}

/// Width of the panel in a window that is enough for it: room for two columns
/// of option cards ([OptionGrid]'s own minimum, `AppSize.action * 4.5`, twice
/// over) plus the panel's margins.
double get _panelWidth => AppSize.action * 10 + AppSize.padding * 2;

/// The form itself: what network, its credentials once a network is chosen,
/// what the agent does, where it reads from and what it can process.
///
/// A single column, unlike the edit page's two: the panel is narrower than a
/// full page on purpose (the list stays visible next to it), and splitting
/// five short blocks into two columns of two-and-a-half each reads worse than
/// just stacking them.
class CreateChannelModal extends StatefulWidget {
  const CreateChannelModal({super.key});

  @override
  State<CreateChannelModal> createState() => _CreateChannelModalState();
}

class _CreateChannelModalState extends State<CreateChannelModal> {
  // Owned by the panel: a create starts from nothing, so unlike the edit page
  // there is no detail read to wait for.
  late final _controller = ChannelFormController(channelId: "");

  // The company's payment accounts, which are the payment block's options.
  // Owned here rather than read from a provider because there is none to read
  // from: the accounts belong to the finance section, which lives *under* the
  // navigator this panel is opened on, so its services are not in scope. A
  // fresh instance per panel is also the right lifetime — an account added in
  // finance a minute ago has to be offerable now.
  final _methods = MoneyMethodsService();

  @override
  void initState() {
    super.initState();

    // Deferred to the first frame so a rebuild is not triggered while the
    // tree is still mounting, same as the rest of the screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The catalog draws the credentials block once a network is chosen.
      // Normally the section already requested it before this panel opens.
      context.read<ChannelCatalogService>().load();

      // The product tables are the selectable data source, from the same
      // cache the products section uses.
      context.read<TablesService>().load(
        context.read<BusinessService>().active.id
      );

      // What the channel may tell a customer to pay into.
      _methods.load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _methods.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<MoneyMethodsService>
    .value(value: _methods, child: _form());

  /// The blocks themselves, under the accounts provider.
  Widget _form() => ScrollableWidget(children: [
    ProviderPicker(controller: _controller),
    // The credentials depend on the network: until one is chosen there are no
    // fields to draw, because each network asks for its own.
    ValueListenableBuilder<String>(
      valueListenable: _controller.provider,
      builder: (context, code, _) {
        final schema = _schemaOf(code);

        if (schema == null) return const SizedBox.shrink();

        return CredentialsBlock(controller: _controller, schema: schema);
      }
    ),
    AgentPicker(controller: _controller),
    DataPicker(controller: _controller),
    PaymentPicker(controller: _controller),
    ToolsPicker(controller: _controller),
    SizedBox(height: AppSize.gap),
    Button(
      title: S.of(context).create_channel,
      loading: _controller.saving,
      action: _submit
    )
  ]);

  ChannelProviderModel? _schemaOf(String code) =>
    code.isEmpty ? null : context.read<ChannelCatalogService>().byCode(code);

  /// Creates the channel.
  ///
  /// The network is the only real requirement — the rest can be left
  /// half-filled on purpose, because a channel is registered before Meta
  /// issues its tokens and is finished being configured afterwards. What is
  /// asked for is that the data source be complete: choosing "product table"
  /// and not saying which leaves the agent with nothing to read, and that is
  /// not a half-configured channel but a misconfigured one.
  Future<void> _submit() async {
    if (_controller.saving.value) return;

    final schema = _schemaOf(_controller.provider.value);

    if (schema == null) {
      FloatFlag.of(context).error(
        message: S.of(context).channel_type_missing
      );
      return;
    }

    if (_controller.source.value.needsTable && _controller.tableId.isEmpty) {
      FloatFlag.of(context).error(
        message: S.of(context).channel_source_missing
      );
      return;
    }

    _controller.busy(true);

    try {
      await context.read<ChannelsService>().create(
        context,
        _controller.payload(schema)
      );
    } catch (_) {
      // The error was already shown by the service; the panel stays open with
      // everything typed, which is the only reasonable thing when someone
      // just pasted four tokens.
      if (mounted) _controller.busy(false);
      return;
    }

    if (!mounted) return;

    _controller.busy(false);

    FloatFlag.of(context).message(S.of(context).channel_created);

    Navigator.pop(context, true);
  }
}
