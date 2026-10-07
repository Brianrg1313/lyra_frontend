import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_provider_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// A provider field.
///
/// An already stored secret is shown empty and **it is not an error**: the
/// backend never returns the value of a token, it only says under which key
/// there is one. The field makes it clear ("already configured") and works as
/// a replacement: typing something overwrites it, leaving it blank keeps it.
class ChannelCredentialField extends StatelessWidget {
  const ChannelCredentialField({super.key, required this.controller, required this.field});

  final ChannelFormController controller;
  final ChannelProviderField field;

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
              ? S.of(context).channel_secret_stored
              : field.label,
            controller: controller.field(field),
            leftIcon: Icon(
              field.secret ? CI.key : CI.pen,
              color: scheme.icon
            )
          ),
          // The hint is written by the backend and says **where** to get the value
          // in the provider's console. It is the only thing whoever is
          // configuring has, and without it this form is a list of impossible
          // fields.
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

  /// The field's title, marking the ones the network needs no matter what.
  ///
  /// It is marked with a word and not an asterisk: the asterisk means "you
  /// cannot save without this", and here you can.
  String _title(BuildContext context) => field.required
    ? "${field.label} · ${S.of(context).channel_field_required}"
    : field.label;
}
