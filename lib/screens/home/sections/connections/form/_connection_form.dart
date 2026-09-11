import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_provider_model.dart';
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'blocks/credentials_block.dart';
import 'blocks/provider_picker.dart';
import 'widgets/form_block.dart';
import 'widgets/missing_banner.dart';
import 'state/connection_form_controller.dart';

/// Creation and editing of a connection. It's a sub-page of the `connections`
/// section (`parents: ["connections"]`): it opens from the list and shares the
/// home's shell, so the sidebar option stays highlighted.
///
/// There are three decisions and nothing else: what the account is called,
/// which service it belongs to, and which credentials it logs in with. **What
/// the account does is not decided here**: there's no agent role, no table to
/// read from, no tools; that's a bot on this connection and it's built
/// elsewhere. An account authenticates once and is shared by all the bots that
/// run on top of it.
///
/// It's a page and not a modal even though there are three blocks: the tokens
/// are copied and pasted from the service's console, in another window, and a
/// modal closes with a single click outside. Losing seven manually-pasted
/// fields because of a click to the side is not an option.
///
/// **It's the same screen for both things.** Whether it's a creation or an
/// edit is decided by the URL: `/home/connections/new` brings no id and
/// `/home/connections/:id` does. The id is read from [Navis.currentArgs] and
/// not through a constructor because the sub-page reuses the shell's single
/// page and the `Navigator` doesn't rebuild the tree when navigating.
///
/// When editing, the screen waits for the connection to arrive before drawing
/// anything: its configuration is what fills the fields, and mounting the empty
/// form to fill it afterwards would make the text jump a frame later. A
/// creation waits for nothing.
///
/// What **cannot** be done when editing is changing the service. The stored
/// secrets were gathered for one, and pointing them at another would leave
/// values that mean nothing there: the other service is a new connection.
///
/// The state lives in [ConnectionFormController], outside the widgets, so each
/// block only listens to its own thing: choosing the service cannot repaint the
/// fields being typed into next to it.
class ConnectionFormSection extends StatefulWidget {
  const ConnectionFormSection({super.key});

  /// Key of the creation route (`/home/connections/new`).
  static const String createRouteKey = "connection_new";

  /// Key of the edit route (`/home/connections/:id`).
  static const String editRouteKey = "connection_detail";

  @override
  State<ConnectionFormSection> createState() => _ConnectionFormSectionState();
}

class _ConnectionFormSectionState extends State<ConnectionFormSection>
    with BusinessListener<ConnectionFormSection> {
  late final ConnectionFormController _controller;

  /// Name of the connection. It's the only thing the backend really requires,
  /// with the same length and the same characters it accepts on the other end:
  /// letters, numbers, spaces, hyphens and underscore. A name with parentheses
  /// or slashes would be rejected by the api, so it's stopped here with a
  /// message that's understandable.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 _\\-]";

  late final _name = InputController(
    key: "NAME",
    form: _controller.headerForm,
    pattern: _namePattern,
    min: 2,
    max: 64,
    obligatory: true,
    initial: _controller.initialName,
    customErrors: {
      InputError.empty:
        S.of(context).form_empty_ma(S.of(context).connection_name_input),
      InputError.invalid:
        S.of(context).form_invalid_ma(S.of(context).connection_name_input),
      InputError.long:
        S.of(context).form_long_ma(S.of(context).connection_name_input),
      InputError.incomplete:
        S.of(context).form_incomplete_ma(S.of(context).connection_name_input)
    }
  );

  /// Optional description: without `obligatory`, only the length is validated.
  late final _description = InputController(
    key: "DESCRIPTION",
    form: _controller.headerForm,
    max: 255,
    initial: _controller.initialDescription,
    customErrors: {
      InputError.long:
        S.of(context).form_long_ma(S.of(context).connection_description_input)
    }
  );

  @override
  void initState() {
    super.initState();

    // The id lives in the URL: without it, this is a creation.
    _controller = ConnectionFormController(
      connectionId: Navis.currentArgs?["id"] ?? ""
    );

    // The loads notify their listeners; they're deferred to the first frame so
    // a rebuild isn't triggered while the tree is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The catalog draws the whole form (which fields each service asks for),
      // so without it there's no screen. Normally the list already fetched it.
      context.read<ConnectionCatalogService>().load();

      if (_controller.isEditing) _open();
    });
  }

  /// The connection being edited belongs to the company that was active: its id
  /// means nothing in the one that was just chosen. It goes back to the list,
  /// which is the only thing that can be shown of the new company.
  @override
  void onBusinessChanged(String businessId) => _back();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reads the connection to be edited. It brings its configuration, which
  /// secrets it already has stored, and its provider's description, all in one
  /// read.
  Future<void> _open() async {
    final connection = await context
      .read<ConnectionsService>()
      .detail(context, _controller.connectionId);

    if (!mounted) return;

    if (connection == null) {
      _controller.status.value = ConnectionFormStatus.error;
      return;
    }

    _controller.apply(connection);
    _controller.status.value = ConnectionFormStatus.ready;
  }

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      _header(context),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: ValueListenableBuilder<ConnectionFormStatus>(
        valueListenable: _controller.status,
        builder: (context, status, _) => switch (status) {
          ConnectionFormStatus.loading => const Center(child: Loading()),
          ConnectionFormStatus.error => SectionMessage(
            icon: CI.info,
            title: S.of(context).connection_open_error_title,
            subtitle: S.of(context).connection_open_error_subtitle,
            action: _back,
            actionLabel: S.of(context).connections
          ),
          ConnectionFormStatus.ready => _body()
        }
      ))
    ])
  );

  /// Top bar: back to the list, the title and the save button.
  ///
  /// The title of an edit is the name the connection had **when it was opened**
  /// and not what's being typed into the field: if it followed the input,
  /// renaming it would rewrite the header letter by letter.
  Widget _header(BuildContext context) => Row(children: [
    FeedbackButton(
      action: _back,
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).connections,
      child: Center(child: Icon(
        CI.arrow_left,
        color: ThemeColor.of(context).text.primary
      ))
    ),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextMedium(
      _controller.isEditing && _controller.initialName.isNotEmpty
        ? _controller.initialName
        : S.of(context).create_connection,
      bold: true,
      ellipsis: true
    )),
    SizedBox(width: AppSize.spaceS),
    ValueListenableBuilder<ConnectionFormStatus>(
      valueListenable: _controller.status,
      builder: (context, status, _) => status != ConnectionFormStatus.ready
        // Without a form there's nothing to save: the button isn't shown dimmed,
        // it isn't shown.
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

  /// Maximum form width.
  ///
  /// The three blocks go in a single column —they're few and read straight
  /// through— and this is the only measure needed: on a wide monitor, a
  /// full-width text field to paste an account id reads worse, and the service
  /// picker ends up with cards wider than they are tall. What's left over
  /// becomes air on the sides.
  static double get _maxWidth => AppSize.action * 15;

  /// The form: what the account is called, which service it belongs to and its
  /// credentials, in that order.
  ///
  /// The order isn't arbitrary: the service decides **which fields exist**
  /// below, so before choosing it the credentials block can't be drawn. The
  /// name goes first because it's the only thing that can be filled without
  /// having opened anyone's console.
  Widget _body() => ScrollableWidget(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.isEditing) MissingBanner(controller: _controller),
            FormBlock(
              title: S.of(context).connection_identity_title,
              subtitle: S.of(context).connection_identity_subtitle,
              child: Column(children: [
                Input(
                  title: S.of(context).connection_name_input,
                  placeholder: S.of(context).connection_name_placeholder,
                  controller: _name,
                  leftIcon: Icon(CI.tems, color: ThemeColor.of(context).icon),
                  next: _description.focus
                ),
                Input(
                  title: S.of(context).connection_description_input,
                  placeholder: S.of(context).connection_description_placeholder,
                  controller: _description,
                  leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
                )
              ])
            ),
            ProviderPicker(controller: _controller),
            // The credentials depend on the service: until one is chosen there are
            // no fields to draw, because each one asks for its own.
            ValueListenableBuilder<String>(
              valueListenable: _controller.provider,
              builder: (context, code, _) {
                final schema = _schemaOf(code);

                if (schema == null) return const SizedBox.shrink();

                return CredentialsBlock(
                  controller: _controller,
                  schema: schema
                );
              }
            )
          ]
        )
      )
    ]
  );

  /// Description of the chosen service.
  ///
  /// When editing it comes from the connection itself (it comes attached to the
  /// detail) and otherwise from the catalog. The connection's is preferred
  /// because it's the one that matches what it has stored, even if the catalog
  /// has moved on.
  ConnectionProviderModel? _schemaOf(String code) {
    if (code.isEmpty) return null;

    final schema = _controller.detail?.schema;
    if (schema != null && schema.provider == code) return schema;

    return context.read<ConnectionCatalogService>().byCode(code);
  }

  void _back() => Navis.push(context, "/home/connections");

  /// Saves the connection.
  ///
  /// The only things required are the name and the service: **the rest can be
  /// left half-filled on purpose**, because an account is registered before the
  /// service issues its tokens and gets finished configuring later. It stays
  /// as "needs configuration" in the list until then, which is exactly what it
  /// is.
  Future<void> _submit() async {
    if (_controller.saving.value) return;

    final schema = _schemaOf(_controller.provider.value);

    if (schema == null) {
      FloatFlag.of(context).error(
        message: S.of(context).connection_provider_missing
      );
      return;
    }

    if (!_controller.headerForm.validate()) return;

    _controller.busy(true);

    final saved = await _write(_controller.payload(schema));

    if (!mounted) return;

    _controller.busy(false);

    // Failed: the error was already shown by the service and the screen keeps
    // everything written, which is the only reasonable thing when someone has
    // just pasted four tokens.
    if (!saved) return;

    FloatFlag.of(context).message(
      _controller.isEditing
        ? S.of(context).connection_saved
        : S.of(context).connection_created
    );

    _back();
  }

  /// Sends the corresponding write and answers only whether it came out or not.
  ///
  /// The service's two operations notify differently —the edit returns a
  /// boolean and the creation returns the id or rethrows— and this screen
  /// doesn't care which one it was: in both, the error was already shown and
  /// the only thing that changes afterwards is the notification text.
  Future<bool> _write(Map<String, dynamic> data) async {
    final service = context.read<ConnectionsService>();

    if (_controller.isEditing) return service.edit(context, data);

    try {
      await service.create(context, data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
