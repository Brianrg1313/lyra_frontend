import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connections/connection_provider_model.dart';

// WIDGETS
import 'package:core/form.dart';

import '../widgets/form_block.dart';
import '../state/connection_form_controller.dart';

/// The account's credentials: the account id, the access token, the app
/// secret, the webhook's verification token.
///
/// It's the block this section exists for. The credentials belong to the
/// **account** and not to what the account does: an Instagram login
/// authenticates once and is then shared by the bots that answer its messages,
/// its comments, and its ads', without asking for three tokens.
///
/// **None of this is written in this app.** The fields, their order, which one
/// is a secret, which is required and where to find each value in the service's
/// console all come from the backend's catalog, which is also the one that
/// decides in which of the two objects each one travels (`SETTINGS` or
/// `CREDENTIALS`). A service added on the other end shows up with its form
/// already built, without touching this.
///
/// A connection can be saved with this half-filled, and it's not neglect: you
/// register "Instagram — Ventas" today and paste the tokens when Meta issues
/// them. That's why the required ones are marked but don't block saving; what
/// they do is leave the account as "needs configuration" in the list.
class CredentialsBlock extends StatelessWidget {
  const CredentialsBlock({
    super.key,
    required this.controller,
    required this.schema
  });

  final ConnectionFormController controller;
  final ConnectionProviderModel schema;

  @override
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).connection_credentials_title,
    subtitle: S.of(context).connection_credentials_subtitle(schema.name),
    child: Column(children: [
      // The fields are drawn in the catalog's order: the account ids first
      // and the secrets last, which is the order they're obtained in.
      //
      // The key is the field's key and not its position: when changing
      // service the lists cross over —`app_secret` is the seventh field of
      // WhatsApp and the fifth of Messenger, but it's the same field with the
      // same value— and without a key Flutter would pair by position, leaving
      // an input drawing another field's controller. With it, the ones that
      // repeat between two services don't even notice the change and the ones
      // that don't, go away and come back whole.
      for (final field in schema.fields) _Field(
        key: ValueKey(field.key),
        controller: controller,
        field: field
      )
    ])
  );
}

/// A field of the provider.
///
/// A secret already stored is shown empty and **it's not an error**: the
/// backend never returns a token's value, it only says under which key there
/// is one. The field makes it clear ("already configured") and works as a
/// replacement: writing something overwrites it, leaving it blank keeps it.
class _Field extends StatelessWidget {
  const _Field({super.key, required this.controller, required this.field});

  final ConnectionFormController controller;
  final ConnectionProviderField field;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final stored = controller.detail?.hasCredential(field.key) ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Input(
            title: _title(context),
            placeholder: stored
              ? S.of(context).connection_secret_stored
              : field.label,
            controller: controller.field(field),
            leftIcon: Icon(
              field.secret ? CI.key : CI.pen,
              color: scheme.icon
            )
          ),
          // The hint is written by the backend and says **where** to get the value
          // in the provider's console. It's the only thing whoever is configuring
          // has, and without it this form is a list of impossible fields.
          if (field.hint.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: AppSize.spaceS,
                bottom: AppSize.gap
              ),
              child: TextSmall(
                field.hint,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            )
        ]
      )
    );
  }

  /// The field's title, marking the ones the service needs no matter what.
  ///
  /// It's marked with a word and not an asterisk: the asterisk means "you can't
  /// save without this", and here you can.
  String _title(BuildContext context) => field.required
    ? "${field.label} · ${S.of(context).connection_field_required}"
    : field.label;
}
