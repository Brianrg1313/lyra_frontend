import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';

/// With which role the AI model that answers on a channel handles it.
///
/// It is not a technical capability but the assignment: the same WhatsApp
/// channel sells or gives support depending on what is chosen here, and on that
/// depend the tone, what it does when faced with a question it cannot answer,
/// and where it pushes the conversation.
///
/// **It travels as `ROLE`, a real column on the channel** (`channels`.`role`)
/// and not app-invented settings — the backend's own catalog is `sales`,
/// `support`, `marketing`, `services`, `billing`, `general`
/// (`Channels.roles()`, `model:/channels/channels.js`). This app only offers
/// three of those six today: the rest have no picture of what this section
/// would do with them yet (a marketing or billing persona needs its own data
/// source story, not just a label). An unknown role — or one of the three not
/// offered here — falls back to `general` on the backend, which is why
/// [agent] carries that code.
enum ChannelAgentRole {
  /// Sells: presents products, builds the order and closes.
  seller("sales"),

  /// Gives support: solves problems with something the client already bought.
  support("support"),

  /// Handles in general: answers whatever comes without pushing toward the
  /// sale.
  agent("general");

  const ChannelAgentRole(this.value);

  /// Code sent as `ROLE` and read back from it. It is what stays written on
  /// the channel, so it is not changed without migrating what is already
  /// stored.
  final String value;

  /// The one that starts chosen: selling is what a channel is connected for
  /// the first time.
  static const ChannelAgentRole initial = seller;

  /// Reads the stored value. The unknown (or the missing, in a channel created
  /// before this setting existed) falls into [initial].
  static ChannelAgentRole from(String? raw) {
    final code = raw?.trim().toLowerCase();

    for (final role in values) {
      if (role.value == code) return role;
    }

    return initial;
  }

  String title(BuildContext context) => switch (this) {
    seller => S.of(context).channel_role_seller,
    support => S.of(context).channel_role_support,
    agent => S.of(context).channel_role_agent
  };

  String subtitle(BuildContext context) => switch (this) {
    seller => S.of(context).channel_role_seller_hint,
    support => S.of(context).channel_role_support_hint,
    agent => S.of(context).channel_role_agent_hint
  };

  IconData get icon => switch (this) {
    seller => CI.cart_shopping,
    support => CI.support,
    agent => CI.user_circle
  };
}
