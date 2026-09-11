import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';

// WIDGETS
import 'package:app/screens/modals/inventory/edit_table_details/_edit_table_details.dart';
import 'package:app/screens/modals/inventory/edit_table_details/table_detail_field.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';
import 'settings_format.dart';
import 'settings_id.dart';

/// The header of the settings: which table it is about and how big it is.
///
/// It starts with the three figures that are come to look at —how many
/// records, how many columns, how many bots read it— because they are the
/// answer to the "how is this table" that brings someone to this screen. The
/// data points read word by word (the description, the identifier) go below.
///
/// **The records may not be known.** The rows live in another database than
/// the columns, so the count can fail on its own: when that happens the figure
/// is not zero but a hole, and below appears the row that explains it.
/// Saying "0 records" of a full table would be lying right where someone
/// decides whether to delete it.
///
/// It is the only block that is **written**. The title and the description
/// are the two data points of the table that someone writes —the rest is
/// counted by the backend, or decided in another screen— and they are
/// corrected here, in the row where they are read, with a single-field form
/// (see [EditTableDetailsModal]).
class TableSummaryBlock extends StatelessWidget {
  const TableSummaryBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final records = detail.records;

    // How many bots reach the table, whichever the way: the ones that chose
    // it and the ones that read it for not having chosen any. It is the same
    // count that the channels block explains, which is where it is broken
    // down.
    final readers = detail.channels.linked.length + detail.channels.open.length;

    return SettingsBlock(
      title: S.of(context).table_settings_summary_title,
      subtitle: S.of(context).table_settings_summary_subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: SettingsStat(
              icon: CI.list,
              // The hole is a data point: see the class note.
              value: records == null
                ? "—"
                : settingsNumber(context, records),
              label: S.of(context).table_settings_stat_records
            )),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: SettingsStat(
              icon: CI.documents,
              value: settingsNumber(context, detail.columns.total),
              label: S.of(context).table_settings_stat_columns
            )),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: SettingsStat(
              icon: CI.ia,
              value: settingsNumber(context, readers),
              label: S.of(context).table_settings_stat_channels,
              // Painted only when there is any: a zero in brand color would be
              // read as a state and not as the absence of one.
              tint: readers > 0 ? scheme.primary : null
            ))
          ]),
          SizedBox(height: AppSize.spaceS),
          SettingsList(rows: [
            if (records == null) SettingsRow(
              icon: CI.info,
              label: S.of(context).table_settings_stat_records,
              hint: S.of(context).table_settings_records_unknown_hint,
              child: TextMedium(
                S.of(context).table_settings_unknown,
                color: scheme.text.secondary
              )
            ),
            // The title goes first because it is what everything else talks
            // about: until now the table was only named in the bar above,
            // which is where it is read and not where it is corrected.
            SettingsValue(
              icon: CI.list,
              label: S.of(context).table_settings_name,
              value: detail.name,
              hint: S.of(context).table_settings_name_hint,
              action: _edit(context, TableDetailField.title, detail.name)
            ),
            SettingsValue(
              icon: CI.pen,
              label: S.of(context).table_settings_description,
              value: detail.description,
              empty: S.of(context).table_settings_description_empty,
              action: _edit(
                context,
                TableDetailField.description,
                detail.description
              )
            ),
            // The identifier is not written nor read in a row: it is
            // uncovered, copied and pasted outside. That is why it goes in its
            // own box with what is done with it (see [TableSettingsId]) and
            // not as one more row.
            SettingsRow(
              icon: CI.key,
              label: S.of(context).table_settings_id,
              hint: S.of(context).table_settings_id_hint,
              child: TableSettingsId(id: detail.id)
            )
          ])
        ]
      )
    );
  }

  /// The button that corrects a written data point, or that loads it if it is
  /// not there.
  ///
  /// Over an empty row the pencil lies —there is nothing to correct—, so it is
  /// the same action with the name and the icon of what is really going to
  /// happen. It is the same thing the business card does, for the same
  /// reason.
  ///
  /// The service is passed to the modal by constructor: it is provided by this
  /// page and a dialog mounts above the `Navigator`, where that provider is no
  /// longer there. What is saved does not come back through here —the service
  /// already repainted the card—, so there is nothing to do when it closes.
  Widget _edit(BuildContext context, TableDetailField field, String value) {
    final label = field.label(context);
    final blank = value.trim().isEmpty;

    return SettingsAction(
      icon: blank ? CI.plus : CI.edit,
      message: blank
        ? S.of(context).table_settings_add(label)
        : S.of(context).table_settings_edit(label),
      action: () => showModal(
        context: context,
        title: blank
          ? S.of(context).table_settings_add(label)
          : S.of(context).table_settings_edit(label),
        builder: (_) => EditTableDetailsModal(
          field: field,
          service: context.read<TableDetailService>()
        )
      )
    );
  }
}

/// The two dates of the table and the one of its last data point.
///
/// **They are two different things and that is why they are two rows.**
/// `updated` is the last structure change —the table or any of its columns—,
/// and the last record is when the last data point came in. A price list
/// imported in March and reloaded this morning has the first old and the
/// second from today: joining them in a single date would lose precisely the
/// one that was being asked.
class TableDatesBlock extends StatelessWidget {
  const TableDatesBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) => SettingsBlock(
    title: S.of(context).table_settings_dates_title,
    subtitle: S.of(context).table_settings_dates_subtitle,
    child: SettingsList(rows: [
      SettingsValue(
        icon: CI.calendar,
        label: S.of(context).table_settings_created,
        value: settingsDate(context, detail.date),
        empty: S.of(context).table_settings_unknown
      ),
      SettingsValue(
        icon: CI.edit,
        label: S.of(context).table_settings_updated,
        value: settingsDate(context, detail.updated),
        hint: S.of(context).table_settings_updated_hint,
        empty: S.of(context).table_settings_unknown
      ),
      SettingsValue(
        icon: CI.save,
        label: S.of(context).table_settings_last_record,
        value: settingsDate(context, detail.lastRecord),
        hint: S.of(context).table_settings_last_record_hint,
        // A table without rows does not have an unknown date: it has no date,
        // and they are two things that are answered differently.
        empty: detail.records == null
          ? S.of(context).table_settings_unknown
          : S.of(context).table_settings_no_records
      )
    ])
  );
}