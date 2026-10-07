import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_provider_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/form/form_block.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/channels/form/widgets/channel_credential_field.dart';

/// The network's credentials: the account id, the access token, the app
/// secret, the webhook verification token.
///
/// **None of this is written in this app.** The fields, their order, which is
/// secret, which is obligatory and where to find each value in the Meta
/// console come from the backend catalog, which is also the one that decides
/// in which of the two objects each travels (`SETTINGS` or `CREDENTIALS`). A
/// network added on the other side appears with its form done, without
/// touching this.
///
/// A channel can be saved with this half-filled, and it is not carelessness:
/// it is registered as "Instagram — Sales" today and the tokens are pasted
/// when Meta issues them. That is why the obligatory ones are marked but do
/// not stop the save; what they do is leave the channel as "needs configuring"
/// in the list.
class CredentialsBlock extends StatelessWidget {
  const CredentialsBlock({
    super.key,
    required this.controller,
    required this.schema
  });

  final ChannelFormController controller;
  final ChannelProviderModel schema;

  @override
  Widget build(BuildContext context) {
    // WhatsApp Personal has no fields at all — there is nothing to paste, the
    // number links by scanning a QR code after the channel exists — so
    // drawing the usual empty title-and-column would be a box with nothing
    // in it. A short notice pointing at where the pairing actually happens
    // (the channel's switch in the list) says something instead of nothing.
    if (schema.provider == ChannelProviderModel.whatsappPersonalCode) {
      return FormBlock(
        title: S.of(context).channel_whatsapp_personal_notice_title,
        subtitle: S.of(context).channel_whatsapp_personal_notice_subtitle,
        child: const SizedBox.shrink()
      );
    }

    return FormBlock(
      title: S.of(context).channel_credentials_title,
      subtitle: S.of(context).channel_credentials_subtitle(schema.name),
      child: Column(children: [
        // The fields are drawn in the catalog's order: the account ids first
        // and the secrets at the end, which is the order they are obtained
        // in.
        //
        // The key is the field's key and not its position: when switching
        // networks the lists cross —`app_secret` is the seventh field of
        // WhatsApp and the fifth of Messenger, but it is the same field with
        // the same value— and without a key Flutter would pair by position,
        // leaving an input drawing another field's controller. With it, the
        // ones that repeat between two networks do not even notice the
        // change and the ones that do not, leave and come back whole.
        for (final field in schema.fields) ChannelCredentialField(
          key: ValueKey(field.key),
          controller: controller,
          field: field
        )
      ])
    );
  }
}
