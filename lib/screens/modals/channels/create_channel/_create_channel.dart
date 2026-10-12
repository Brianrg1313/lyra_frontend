import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:core/button.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_preset.dart';
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

/// Opens the creation of a channel in a modal centered over the page.
///
/// It used to be a whole sub-page ([ChannelFormSection]'s old create route),
/// then a side panel. Creating is a short task that starts from nothing — pick
/// a network, paste its tokens, leave the rest as it comes — so it gets the
/// window's attention instead of sharing it with the list next to it.
///
/// Editing stays a page (`ChannelFormSection`) and a detail panel: they open
/// against a channel that already exists and is read next to the others.
///
/// A [preset] opens it already filled (network, role, tools, and the
/// company's main table to read from), still editable.
///
/// Returns the new channel's id, so the caller reloads its list (and can pair
/// a WhatsApp Personal one); `null` if the modal was closed without saving.
Future<String?> showCreateChannel(
  BuildContext context, {
  ChannelPreset? preset
}) async {
  final created = await showModal(
    context: context,
    title: S.of(context).create_channel,
    size: ModalSize.large,
    builder: (context) => CreateChannelModal(preset: preset)
  );

  return created is String ? created : null;
}

/// The form itself, one decision per row ([ChannelFormRow]): the connection
/// (network and its credentials) above a line, what the agent does below it,
/// and the button outside the scroll so it is always at hand.
class CreateChannelModal extends StatefulWidget {
  const CreateChannelModal({super.key, this.preset});

  final ChannelPreset? preset;

  @override
  State<CreateChannelModal> createState() => _CreateChannelModalState();
}

class _CreateChannelModalState extends State<CreateChannelModal> {
  // Owned by the modal: a create starts from nothing, so unlike the edit page
  // there is no detail read to wait for.
  late final _controller = ChannelFormController(channelId: "");

  // The company's payment accounts, which are the payment block's options.
  // Owned here rather than read from a provider because there is none to read
  // from: the accounts belong to the finance section, which lives *under* the
  // navigator this modal is opened on, so its services are not in scope. A
  // fresh instance per modal is also the right lifetime — an account added in
  // finance a minute ago has to be offerable now.
  final _methods = MoneyMethodsService();

  @override
  void initState() {
    super.initState();

    final preset = widget.preset;
    if (preset != null) _controller.applyPreset(preset);

    // Deferred to the first frame so a rebuild is not triggered while the
    // tree is still mounting, same as the rest of the screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The catalog draws the credentials block once a network is chosen.
      // Normally the section already requested it before this modal opens.
      context.read<ChannelCatalogService>().load();

      // The product tables are the selectable data source, from the same
      // cache the products section uses.
      final tables = context.read<TablesService>();

      // Listened to and not awaited: a read already in flight (the section
      // asked first) returns at once, before the tables are there.
      if (widget.preset != null) {
        _tables = tables..addListener(_pickMainTable);
      }

      tables.load(context.read<BusinessService>().active.id);
      _pickMainTable();

      // What the channel may tell a customer to pay into.
      _methods.load();
    });
  }

  /// Listened to while a preset waits for the tables ([_pickMainTable]).
  TablesService? _tables;

  /// A preset reads from the company's main table, so its channel can be
  /// created with one tap. Once, when the tables are there, and only if
  /// nothing was picked meanwhile.
  void _pickMainTable() {
    final tables = _tables;
    if (tables == null || tables.status != TablesStatus.ready) return;

    tables.removeListener(_pickMainTable);
    _tables = null;

    if (!_controller.source.value.needsTable) return;
    if (_controller.tableId.isNotEmpty || tables.tables.isEmpty) return;

    final main = tables.tables.firstWhere(
      (table) => table.primary,
      orElse: () => tables.tables.first
    );

    // The name with the id: see [ChannelFormController.apply].
    _controller.table.selectedValue = main.id;
    _controller.table.textController.text = main.title;
  }

  @override
  void dispose() {
    _tables?.removeListener(_pickMainTable);
    _controller.dispose();
    _methods.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<MoneyMethodsService>
    .value(value: _methods, child: _form());

  /// Widest the form gets: the label column and four network tiles beside
  /// it. A narrower window takes what the modal may have.
  static double get _width => AppSize.action * 16;

  /// Tallest the form gets; the rows scroll inside it.
  static double get _height => AppSize.action * 15;

  /// The rows themselves, under the accounts provider.
  Widget _form() {
    final width = math.min(
      _width,
      ModalSize.large.maxWidth(context) - AppSize.padding * 2
    ).floorToDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: _height
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(child: ScrollableWidget(
            padding: EdgeInsets.only(bottom: AppSize.padding),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProviderPicker(controller: _controller),
              // The credentials depend on the network: until one is chosen
              // there are no fields to draw, because each network asks for
              // its own.
              ValueListenableBuilder<String>(
                valueListenable: _controller.provider,
                builder: (context, code, _) {
                  final schema = _schemaOf(code);

                  if (schema == null) return const SizedBox.shrink();

                  return CredentialsBlock(controller: _controller, schema: schema);
                }
              ),
              Separator.horizontal(
                color: ThemeColor.of(context).line,
                margin: EdgeInsets.only(bottom: AppSize.spaceM)
              ),
              AgentPicker(controller: _controller),
              DataPicker(controller: _controller),
              PaymentPicker(controller: _controller),
              ToolsPicker(controller: _controller)
            ]
          )),
          SizedBox(height: AppSize.spaceS),
          Button(
            title: S.of(context).create_channel,
            loading: _controller.saving,
            action: _submit
          )
        ]
      )
    );
  }

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

    final String id;

    try {
      id = await context.read<ChannelsService>().create(
        context,
        _controller.payload(schema)
      );
    } catch (_) {
      // The error was already shown by the service; the modal stays open with
      // everything typed, which is the only reasonable thing when someone
      // just pasted four tokens.
      if (mounted) _controller.busy(false);
      return;
    }

    if (!mounted) return;

    _controller.busy(false);

    FloatFlag.of(context).message(S.of(context).channel_created);

    Navigator.pop(context, id);
  }
}
