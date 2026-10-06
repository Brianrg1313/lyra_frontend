import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_model.dart';

/// The line a badge says, from the l10n key the backend names it by (`title`). `S` has no lookup
/// by name, so each key the catalog sends is listed here; one the app does not know yet still
/// says that something needs attention instead of showing a key.
String pendingTitle(BuildContext context, BadgeModel badge) {
  final text = S.of(context);

  return switch (badge.title) {
    "badge_chats_attention" => text.badge_chats_attention,
    "badge_appointments_upcoming" => text.badge_appointments_upcoming,
    "badge_reservations_pending" => text.badge_reservations_pending,
    "badge_pos_invoices" => text.badge_pos_invoices,
    "badge_money_receivables" => text.badge_money_receivables,
    "badge_notifications_unseen" => text.badge_notifications_unseen,
    "badge_setup_country" => text.badge_setup_country,
    "badge_setup_payments" => text.badge_setup_payments,
    "badge_setup_catalog" => text.badge_setup_catalog,
    "badge_setup_channels" => text.badge_setup_channels,
    "badge_setup_logo" => text.badge_setup_logo,
    "badge_legal_terms" => text.badge_legal_terms,
    "badge_news_money" => text.badge_news_money,
    _ => text.badge_unknown
  };
}
