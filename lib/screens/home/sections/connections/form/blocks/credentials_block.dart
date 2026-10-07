import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connections/connection_provider_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/form/form_block.dart';
import 'package:app/screens/home/sections/connections/form/state/connection_form_controller.dart';
import 'package:app/screens/home/sections/connections/form/widgets/connection_credential_field.dart';

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
      for (final field in schema.fields) ConnectionCredentialField(
        key: ValueKey(field.key),
        controller: controller,
        field: field
      )
    ])
  );
}
