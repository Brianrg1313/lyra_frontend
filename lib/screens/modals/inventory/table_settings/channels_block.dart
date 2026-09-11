import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The channels that read this table.
///
/// **They go in two lists and not in one**, because they are two different
/// things and only one is a decision:
///
/// - the ones that **chose** this table as a data source, and
/// - the ones that **did not configure any**, which the runtime reads as "all
///   the tables of the business" and therefore also read this one.
///
/// Showing only the first ones would be the comfortable answer and the wrong
/// one. A business reading "not connected to any channel" while a bot without
/// sources dictates its cost prices by WhatsApp is exactly what this block
/// exists to avoid, so the second ones are shown just as big and with the
/// notice of why they are there.
///
/// From the channel catalog, **only the already-resolved name and icon** of
/// each network are taken and not the whole provider: the catalog is read once
/// and does not change, so this stops listening to it as soon as it arrived.
class TableChannelsBlock extends StatelessWidget {
  const TableChannelsBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final channels = detail.channels;

    return SettingsBlock(
      title: S.of(context).table_settings_channels_title,
      subtitle: S.of(context).table_settings_channels_subtitle,
      child: !channels.reached
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                S.of(context).table_settings_channels_none,
                lines: 2,
                color: scheme.text.secondary
              ),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).table_settings_channels_none_hint,
                lines: 3,
                color: scheme.text.secondary
              )
            ]
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (channels.linked.isNotEmpty) _Group(
                label: S.of(context).table_settings_channels_linked,
                readers: channels.linked
              ),
              if (channels.open.isNotEmpty) ...[
                if (channels.linked.isNotEmpty)
                  SizedBox(height: AppSize.spaceS),
                _Group(
                  label: S.of(context).table_settings_channels_open,
                  hint: S.of(context).table_settings_channels_open_hint,
                  readers: channels.open
                )
              ]
            ]
          )
    );
  }
}

/// One of the two lists, with its title and —when it is necessary to explain
/// why those bots are there— its line below.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.readers, this.hint});

  final String label;
  final String? hint;
  final List<TableChannelReader> readers;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextSmall(label, color: scheme.text.secondary),
        if (hint != null) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(hint!, lines: 4, color: scheme.accent)
        ],
        SizedBox(height: AppSize.gap),
        for (int i = 0; i < readers.length; i++) ...[
          if (i > 0) SizedBox(height: AppSize.gap),
          _ReaderRow(reader: readers[i])
        ]
      ]
    );
  }
}

/// A bot that reads the table: the icon of its network, what it is called, in
/// what state it is and why it counts answers.
///
/// **It is touched and takes to its configuration** (`/home/channels/:id`),
/// which is the only thing that can be done about it: from which channel a
/// table is read is chosen on the channel side, in its data source.
class _ReaderRow extends StatelessWidget {
  const _ReaderRow({required this.reader});

  final TableChannelReader reader;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, icon) = context
      .select<ChannelCatalogService, (String, IconData)>((catalog) {
        final provider = catalog.byCode(reader.provider);

        // Without a catalog (still loading, or failed) the raw code is shown:
        // "whatsapp" says less than "WhatsApp Business" but much more than a
        // hole, and the row does not depend on that read to exist.
        return (provider?.name ?? reader.provider, provider?.icon ?? CI.link);
      });

    // Below the name goes how the bot answers: the account it uses and who
    // answers from it. Without either one the network stays, which is the only
    // thing that is always there: a blank line would misalign the row against
    // the rest.
    final subtitle = [
      if (reader.connectionName.isNotEmpty) reader.connectionName,
      if (reader.scopeName.isNotEmpty) reader.scopeName
    ].join(" · ");

    return FeedbackButton(
      action: () => Navis.push(context, "/home/channels/${reader.id}"),
      padding: EdgeInsets.all(AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.spaceS),
      color: scheme.surface,
      message: S.of(context).edit_channel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.5),
            child: Icon(
              icon,
              size: AppSize.text,
              // A paused channel looks dimmed also in its icon: it is the
              // first thing looked at of the row.
              color: reader.enabled ? scheme.icon : scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: TextMedium(
                  reader.name,
                  bold: true,
                  ellipsis: true
                )),
                SizedBox(width: AppSize.gap),
                _ReaderStateTag(reader: reader)
              ]),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                subtitle.isNotEmpty ? subtitle : label,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ))
        ]
      )
    );
  }
}

/// In which state the bot is, with the same three signs of the channels list
/// and in the same order: paused wins over the rest —if it is off it does not
/// matter that it is complete—, then "needs configuring" and only if it is
/// whole and on, "connected".
///
/// It matters here as much as there: a bot connected to this table but paused
/// is not answering with it, and a half-configured one neither.
class _ReaderStateTag extends StatelessWidget {
  const _ReaderStateTag({required this.reader});

  final TableChannelReader reader;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, color) = switch (reader) {
      TableChannelReader(enabled: false) => (
        S.of(context).channel_state_paused,
        scheme.text.secondary
      ),
      TableChannelReader(ready: false) => (
        // The notice color and not a red: it has to be finished, nothing
        // broke.
        S.of(context).channel_state_pending,
        scheme.accent
      ),
      _ => (S.of(context).channel_state_ready, scheme.primary)
    };

    return SettingsTag(label: label, color: color);
  }
}