import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_provider_model.dart';

import '../state/channel_form_controller.dart';

/// What a channel is missing to be able to work, above its form.
///
/// It only appears when editing an incomplete one, which is the normal case
/// and not an anomaly: a channel is registered before Meta issues its tokens
/// and is returned to later to finish it. When it is returned to, this is
/// what says **what for**, without having to go through fifteen fields
/// looking for which one was left empty.
///
/// The names come from the provider's schema and not from the raw keys: the
/// backend responds `missing: ["access_token", "app_secret"]` and what has to
/// be read is "Access token" and "App secret".
class MissingBanner extends StatelessWidget {
  const MissingBanner({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail;

    if (detail == null || detail.ready || detail.missing.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = ThemeColor.of(context);
    final schema = detail.schema;

    // The raw key is the last resort: if the schema did not come, "access_token"
    // says less than "Access token" but is still the right clue.
    final labels = [
      for (final key in detail.missing) _labelOf(schema, key)
    ];

    return Container(
      margin: EdgeInsets.only(bottom: AppSize.spaceM),
      padding: EdgeInsets.all(AppSize.spaceS),
      decoration: BoxDecoration(
        color: scheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CI.info, size: AppSize.text * 1.2, color: scheme.accent),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(S.of(context).channel_missing_title, bold: true),
              SizedBox(height: AppSize.gap),
              TextSmall(
                labels.join(" · "),
                lines: 2,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ))
        ]
      )
    );
  }

  /// Label of a key according to the provider's schema.
  static String _labelOf(ChannelProviderModel? schema, String key) {
    for (final field in schema?.fields ?? const <ChannelProviderField>[]) {
      if (field.key == key) return field.label;
    }

    return key;
  }
}
