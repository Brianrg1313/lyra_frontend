import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_preset.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/form/blocks/provider_picker.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

import './step_art.dart';
import './step_bodies.dart';

/// Opens the creation of a channel as a [ModalSteps]: one question per page,
/// under an image, with back and next.
///
/// It was one long form, every block a row. Whoever connects their first
/// channel is often not at ease with software, and a page of ten decisions
/// with tokens in the middle read as a wall; one question at a time, each
/// answer explained where it is picked, reads as a conversation. The same
/// controller underneath, so what is sent did not change.
///
/// Editing stays a page (`ChannelFormSection`) and a detail panel: they open
/// against a channel that already exists and is read next to the others.
///
/// The network's keys (or a WhatsApp Personal QR) are not asked here: they
/// are the step that stalls a newcomer, and a channel is registered before
/// Meta issues its tokens anyway. They are added on the channel's page.
///
/// A [preset] opens it already filled (network, role, tools, and the
/// company's main table to read from), on the step after the network, which
/// the preset already chose; back still reaches it.
///
/// Returns the new channel's id, so the caller reloads its list (and can pair
/// a WhatsApp Personal one); `null` if the modal was closed without saving.
Future<String?> showCreateChannel(
  BuildContext context, {
  ChannelPreset? preset
}) async {
  final created = await showStepModal(
    context: context,
    builder: (context) => CreateChannelModal(preset: preset)
  );

  return created is String ? created : null;
}

/// The steps: network, the agent's job, what it reads, where
/// customers pay, and what else it understands. Only the network and the
/// table (when reading one) stop the way forward; the rest can be left as it
/// comes.
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
    if (_controller.tableIds.isNotEmpty || tables.tables.isEmpty) return;

    final main = tables.tables.firstWhere(
      (table) => table.primary,
      orElse: () => tables.tables.first
    );

    _controller.tables.value = {main.id};
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
    .value(value: _methods, child: _steps());

  Widget _steps() {
    final s = S.of(context);

    return ModalSteps(
      initialStep: widget.preset == null ? 0 : 1,
      height: AppSize.action * 8,
      stepLabel: (step, count) => s.channel_step_label(step, count),
      nextText: s.next,
      backText: s.back,
      cancelText: s.cancel,
      finishText: s.create_channel,
      onFinish: _submit,
      steps: [
        ModalStep(
          title: s.channel_step_network_title,
          subtitle: s.channel_step_network_subtitle,
          image: const StepArt(gradient: "gradient-1.png", icon: CI.chat),
          validate: _hasNetwork,
          builder: (_) => ProviderPicker(controller: _controller, labeled: false)
        ),
        ModalStep(
          title: s.channel_step_role_title,
          subtitle: s.channel_step_role_subtitle,
          image: const StepArt(gradient: "gradient-2.png", icon: CI.ia),
          builder: (_) => RoleStep(controller: _controller)
        ),
        ModalStep(
          title: s.channel_step_source_title,
          subtitle: s.channel_step_source_subtitle,
          image: const StepArt(gradient: "gradient-3.png", icon: CI.inventory),
          validate: _hasTable,
          builder: (_) => SourceStep(controller: _controller)
        ),
        ModalStep(
          title: s.channel_step_payments_title,
          subtitle: s.channel_step_payments_subtitle,
          image: const StepArt(gradient: "gradient-1.png", icon: CI.wallet),
          builder: (_) => PaymentsStep(controller: _controller)
        ),
        ModalStep(
          title: s.channel_step_tools_title,
          subtitle: s.channel_step_tools_subtitle,
          image: const StepArt(gradient: "gradient-2.png", icon: CI.microphone),
          builder: (_) => ToolsStep(controller: _controller)
        )
      ]
    );
  }

  /// Everything else follows from the network: without one there is nothing
  /// to connect.
  bool _hasNetwork() {
    if (_schemaOf(_controller.provider.value) != null) return true;

    FloatFlag.of(context).error(message: S.of(context).channel_type_missing);
    return false;
  }

  /// Reading "a product table" without saying which leaves the agent with
  /// nothing to read: not half-configured, misconfigured.
  bool _hasTable() {
    if (!_controller.source.value.needsTable || _controller.tableIds.isNotEmpty) return true;

    FloatFlag.of(context).error(message: S.of(context).channel_source_missing);
    return false;
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

    // Checked again: a preset opens past the network step.
    if (!_hasNetwork() || !_hasTable()) return;
    final schema = _schemaOf(_controller.provider.value)!;

    _controller.busy(true);

    final String id;

    try {
      id = await context.read<ChannelsService>().create(
        context,
        _controller.payload(schema)
      );
    } catch (_) {
      // The error was already shown by the service; the modal stays open with
      // every answer as it was, to retry.
      if (mounted) _controller.busy(false);
      return;
    }

    if (!mounted) return;

    _controller.busy(false);

    FloatFlag.of(context).message(S.of(context).channel_created);

    Navigator.pop(context, id);
  }
}
