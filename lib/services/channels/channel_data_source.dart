import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/channels/channel_agent_role.dart';

/// Where the AI model gets what it knows when it handles a channel.
///
/// A channel without a source answers from memory, which is the same as saying
/// it makes things up: this is what ties it to the company's real data.
///
/// Today only one is built. The other two are shown just as well, disabled, and
/// not because it is pretty: whoever connects a channel needs to know that
/// scheduling appointments and answering from documents are things that will
/// exist, so as not to set up the channel twice.
///
/// **It travels inside `SETTINGS`** ([settingKey]), together with the chosen
/// table ([tableSettingKey]) when applicable. See [ChannelAgentRole] for why
/// the backend does not know these keys.
enum ChannelDataSource {
  /// A product table from the products section: the model answers prices,
  /// stock and sheets reading from there.
  productTable("table", available: true),

  /// A services calendar, for scheduling appointments. It does not exist yet.
  serviceCalendar("calendar", available: false),

  /// A knowledge base: loose information with which the model answers questions
  /// or builds marketing pieces. It does not exist yet.
  knowledgeBase("knowledge", available: false);

  const ChannelDataSource(this.value, {required this.available});

  /// Code stored in the channel.
  final String value;

  /// `false` while the source is not built. The selector shows it disabled and
  /// the form does not let it be chosen.
  final bool available;

  /// Key of the setting inside `SETTINGS`.
  static const String settingKey = "data_source";

  /// Key where **which** product table was chosen is stored, when the source
  /// is [productTable]. It is the table's id, not its name: renaming it cannot
  /// disconnect the channel.
  static const String tableSettingKey = "data_table_id";

  static const ChannelDataSource initial = productTable;

  static ChannelDataSource from(String? raw) {
    final code = raw?.trim().toLowerCase();

    for (final source in values) {
      if (source.value == code) return source;
    }

    return initial;
  }

  /// What a channel with [role] may read from.
  ///
  /// A seller reads product data — a table today, a services calendar once it
  /// exists. Support and general agents are not there to sell: what they read
  /// is a knowledge base, not the catalog, so the two product sources are not
  /// even offered to them.
  static List<ChannelDataSource> allowedFor(ChannelAgentRole role) =>
    switch (role) {
      ChannelAgentRole.seller => const [productTable, serviceCalendar],
      ChannelAgentRole.support ||
      ChannelAgentRole.agent => const [knowledgeBase]
    };

  /// `true` if, when choosing this source, you also have to say which one:
  /// the product tables are several, and the channel reads from one.
  bool get needsTable => this == productTable;

  String title(BuildContext context) => switch (this) {
    productTable => S.of(context).channel_source_table,
    serviceCalendar => S.of(context).channel_source_calendar,
    knowledgeBase => S.of(context).channel_source_knowledge
  };

  String subtitle(BuildContext context) => switch (this) {
    productTable => S.of(context).channel_source_table_hint,
    serviceCalendar => S.of(context).channel_source_calendar_hint,
    knowledgeBase => S.of(context).channel_source_knowledge_hint
  };

  IconData get icon => switch (this) {
    productTable => CI.list,
    serviceCalendar => CI.calendar,
    knowledgeBase => CI.bookmark
  };
}
