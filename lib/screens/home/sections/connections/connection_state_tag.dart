import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connections/connection_lite_model.dart';

/// The state tag of a connection, in the list row.
///
/// A connected account has **two states that are not the same thing** and
/// confusing them wastes time:
///
/// - `ready` — whether it has everything its service asks for loaded. A newly
///   registered account with no tokens yet is normal (it's registered before
///   Meta issues them) and it's simply not ready. It's not an error: it just
///   needs to be finished.
/// - `enabled` — the company's switch. A complete account can be paused
///   without losing its configuration or the bots running on it.
///
/// Hence the three labels: paused wins over everything —if it's turned off it
/// doesn't matter that it's complete—, then "needs configuration", and only if
/// it's whole and turned on, "connected".
class ConnectionStateTag extends StatelessWidget {
  const ConnectionStateTag({super.key, required this.connection});

  final ConnectionLiteModel connection;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, color) = switch (connection) {
      // Paused first: it's what explains why a complete account doesn't answer.
      ConnectionLiteModel(enabled: false) => (
        S.of(context).connection_state_paused,
        scheme.text.secondary
      ),
      ConnectionLiteModel(ready: false) => (
        S.of(context).connection_state_pending,
        // The brand color and not a red: it needs finishing, nothing broke.
        scheme.accent
      ),
      _ => (S.of(context).connection_state_ready, scheme.primary)
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        // A slightly tinted background instead of a solid one: the tag accompanies
        // the account's name, it doesn't compete with it.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(label, color: color)
    );
  }
}
