import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/business_listener.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

import 'blocks/agent_picker.dart';
import 'blocks/credentials_block.dart';
import 'blocks/data_picker.dart';
import 'blocks/payment_picker.dart';
import 'blocks/provider_picker.dart';
import 'blocks/tools_picker.dart';
import 'widgets/missing_banner.dart';
import 'state/channel_form_controller.dart';

/// Editing an already-connected channel. It is a sub-page of the `channels`
/// section (`parents: ["channels"]`): it opens from the table settings panel
/// (which channel reads this table) and shares the home shell, so the
/// sidebar option stays highlighted.
///
/// **Creating one is not here any more.** It moved to a side panel
/// (`showCreateChannel`, in `lib/screens/modals/channels/create_channel`): a create
/// starts from nothing and fits a panel; an edit opens against a channel that
/// already has credentials, a role, sources and possibly things missing, and
/// reads better as its own page. The two used to be the same screen, told
/// apart by whether the URL carried an id.
///
/// It is a page and not a modal because it is a whole credentials form: what
/// the answering agent does, where it gets its data, what it can process and
/// with what tokens it logs in — those tokens are copied and pasted from the
/// Meta console, in another window, and a modal closes with a click outside.
///
/// The channel id is read from [Navis.currentArgs] and not by constructor
/// because the sub-page reuses the shell's single page and the `Navigator`
/// does not rebuild the tree on navigation. The screen waits for it to arrive
/// before drawing anything: its configuration is what fills the fields, and
/// mounting the empty form to fill it later would make it jump a frame later.
///
/// What **cannot** be done here is changing the network. The stored secrets
/// were gathered for one, and pointing them at another would leave values
/// that mean nothing there: the other network is a new channel.
///
/// The state lives in [ChannelFormController], outside the widgets, so each
/// block only listens to its own: choosing a tool cannot repaint the fifteen
/// credential fields next to it.
class ChannelFormSection extends StatefulWidget {
  const ChannelFormSection({super.key});

  /// Route key of the edit (`/home/channels/:id`).
  static const String editRouteKey = "channel_detail";

  @override
  State<ChannelFormSection> createState() => _ChannelFormSectionState();
}

class _ChannelFormSectionState extends State<ChannelFormSection>
    with BusinessListener<ChannelFormSection> {
  late final ChannelFormController _controller;

  /// The company's payment accounts, which are the payment block's options.
  ///
  /// Owned by the page and not registered app-wide for the same reason the
  /// finance section owns its own copy: they are the active company's, and a
  /// cache that outlived a company switch would offer another one's accounts.
  /// This page goes back to the list when the company changes anyway.
  final MoneyMethodsService _methods = MoneyMethodsService();

  @override
  void initState() {
    super.initState();

    _controller = ChannelFormController(
      channelId: Navis.currentArgs?["id"] ?? ""
    );

    // Loads notify their listeners; they are deferred to the first frame so a
    // rebuild is not triggered while the tree is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The catalog draws the whole form (what fields each network asks for), so
      // without it there is no screen. Normally the list already requested it.
      context.read<ChannelCatalogService>().load();

      // The product tables are the selectable data source: they are requested
      // from the same cache the products section uses, so if it was already
      // visited this does not hit the backend.
      context.read<TablesService>().load(
        context.read<BusinessService>().active.id
      );

      // What the channel may tell a customer to pay into.
      _methods.load();

      if (_controller.isEditing) _open();
    });
  }

  /// The channel being edited belongs to the previously active business: its id
  /// means nothing in the one just chosen. It goes back to the list, which is
  /// the only thing that can be shown of the new business.
  @override
  void onBusinessChanged(String businessId) => _back();

  @override
  void dispose() {
    _controller.dispose();
    _methods.dispose();
    super.dispose();
  }

  /// Reads the channel to be edited. It brings its configuration, what secrets
  /// it already has stored and its provider's description, all in a single
  /// read.
  Future<void> _open() async {
    final channel = await context
      .read<ChannelsService>()
      .detail(context, _controller.channelId);

    if (!mounted) return;

    if (channel == null) {
      _controller.status.value = ChannelFormStatus.error;
      return;
    }

    _controller.apply(channel);
    _controller.status.value = ChannelFormStatus.ready;
  }

  @override
  Widget build(BuildContext context) =>
    ChangeNotifierProvider<MoneyMethodsService>.value(
      value: _methods,
      child: _page(context)
    );

  /// The page itself, under the accounts provider.
  Widget _page(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      _header(context),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: ValueListenableBuilder<ChannelFormStatus>(
        valueListenable: _controller.status,
        builder: (context, status, _) => switch (status) {
          ChannelFormStatus.loading => const Center(child: Loading()),
          ChannelFormStatus.error => SectionMessage(
            icon: CI.info,
            title: S.of(context).channel_open_error_title,
            subtitle: S.of(context).channel_open_error_subtitle,
            action: _back,
            actionLabel: S.of(context).channels
          ),
          ChannelFormStatus.ready => _body()
        }
      ))
    ])
  );

  /// Top bar: back to the list, the title and the save button.
  ///
  /// The title of an edit is the name the channel had **when opened** and not
  /// what is being typed in the field: if it followed the input, renaming the
  /// channel would rewrite the header letter by letter.
  Widget _header(BuildContext context) => Row(children: [
    FeedbackButton(
      action: _back,
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).channels,
      child: Center(child: Icon(
        CI.arrow_left,
        color: ThemeColor.of(context).text.primary
      ))
    ),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextMedium(
      _controller.initialName.isNotEmpty
        ? _controller.initialName
        : S.of(context).edit_channel,
      bold: true,
      ellipsis: true
    )),
    SizedBox(width: AppSize.spaceS),
    ValueListenableBuilder<ChannelFormStatus>(
      valueListenable: _controller.status,
      builder: (context, status, _) => status != ChannelFormStatus.ready
        // Without the form there is nothing to save: the button is not shown
        // disabled, it is not shown.
        ? const SizedBox.shrink()
        : SizedBox(
            width: AppSize.action * 4,
            child: Button(
              title: S.of(context).save,
              loading: _controller.saving,
              action: _submit
            )
          )
    )
  ]);

  /// Width from which the form opens in two columns.
  static double get _twoColumns => AppSize.action * 16;

  /// The form, split into two halves that read separately: **what it connects
  /// to** (what network, with what credentials) and **how it answers** (what
  /// the agent does, where it gets its data, what it can process).
  ///
  /// The split is not just to fill the width. Five blocks in a single column
  /// force scrolling to the end to reach the credentials, which is what one
  /// comes back to when the channel was left half configured; this way they
  /// stay up top, on the side of the network that asks for them.
  ///
  /// When narrow they stack in the order a channel is decided, which is the
  /// same order as above read straight through.
  ///
  /// Both halves always go in the same [Wrap] and the only thing that changes
  /// with the width is **how much each one measures**: whole they stack one
  /// below the other, at half they fit side by side. A `Row` is not built when
  /// there is room and a `Column` when there is not, and not for fun: changing
  /// the tree's shape when crossing the width unmounts and remounts the
  /// inputs, and an [InputController] does not survive that —the `core`
  /// widgets assign their validation on mount and the field is
  /// single-write—. Stretching the window broke the form.
  Widget _body() => LayoutBuilder(builder: (context, constraints) {
    // An unmeasured width cannot be passed to the halves: the minimum for
    // splitting is taken, which leaves a single column.
    final available = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : _twoColumns - 1;

    final split = available >= _twoColumns;

    // Floored: two halves that add up to a hair over the width due to
    // floating-point rounding do not fit in the same row, and the [Wrap]
    // drops the second one —one column when there was room for two.
    final column = split
      ? ((available - AppSize.spaceM) / 2).floorToDouble()
      : available;

    final connection = <Widget>[
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
      )
    ];

    final agent = <Widget>[
      AgentPicker(controller: _controller),
      DataPicker(controller: _controller),
      PaymentPicker(controller: _controller),
      ToolsPicker(controller: _controller)
    ];

    return ScrollableWidget(
      children: [
        MissingBanner(controller: _controller),
        Wrap(
          spacing: AppSize.spaceM,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(width: column, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: connection
            )),
            SizedBox(width: column, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: agent
            ))
          ]
        )
      ]
    );
  });

  /// Description of the chosen network.
  ///
  /// While editing it comes from the channel itself (it comes attached to the
  /// detail) and otherwise from the catalog. The channel's is preferred
  /// because it is the one that matches what is stored, even if the catalog
  /// has moved.
  ChannelProviderModel? _schemaOf(String code) {
    if (code.isEmpty) return null;

    final schema = _controller.detail?.schema;
    if (schema != null && schema.provider == code) return schema;

    return context.read<ChannelCatalogService>().byCode(code);
  }

  void _back() => Navis.push(context, "/home/channels");

  /// Saves the channel.
  ///
  /// The network is the only real requirement, and it is already fixed —this
  /// page never lets it change—, so [schema] is here for the fields it
  /// declares rather than as a gate. What is asked for is that the data
  /// source be complete: choosing "product table" and not saying which leaves
  /// the agent with nothing to read, and that is not a half-configured
  /// channel but a misconfigured one.
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

    final saved = await context.read<ChannelsService>().edit(
      context,
      _controller.payload(schema)
    );

    if (!mounted) return;

    _controller.busy(false);

    // Failed: the error was already shown by the service and the screen keeps
    // everything typed, which is the only reasonable thing when someone just
    // pasted four tokens.
    if (!saved) return;

    FloatFlag.of(context).message(S.of(context).channel_saved);

    _back();
  }
}
