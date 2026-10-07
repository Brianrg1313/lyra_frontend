import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connections/connection_provider_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/connections/form/state/connection_form_controller.dart';

/// What an account is missing to be able to work, above its form.
///
/// It only appears when editing an incomplete one, which is the normal case
/// and not an anomaly: a connection is registered before Meta issues its
/// tokens and is come back to later to finish it. When coming back, this is
/// what says **what** it came back for, without having to go through seven
/// fields looking for which one was left empty.
///
/// The names come from the provider's schema and not from the raw keys: the
/// backend responds `missing: ["access_token", "app_secret"]` and what has to
/// be read is "Access token" and "App secret".
class MissingBanner extends StatelessWidget {
  const MissingBanner({super.key, required this.controller});

  final ConnectionFormController controller;

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail;

    if (detail == null || detail.ready || detail.missing.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = ThemeColor.of(context);
    final schema = detail.schema;

    // The raw key is the last resort: if the schema didn't come, "access_token"
    // says less than "Access token" but it's still the right clue.
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
              TextMedium(S.of(context).connection_missing_title, bold: true),
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
  static String _labelOf(ConnectionProviderModel? schema, String key) {
    for (final field in schema?.fields ?? const <ConnectionProviderField>[]) {
      if (field.key == key) return field.label;
    }

    return key;
  }
}
