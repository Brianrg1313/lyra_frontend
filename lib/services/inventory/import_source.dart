import 'package:flutter/material.dart' show BuildContext, IconData, Icons;

import 'package:app/toolkit/toolkit.dart';

/// Where the content of an imported table can come from.
///
/// It is only the catalog of what is offered to the user when they tap to import:
/// what each source is called, what it brings and whether it can already be used. None of this
/// talks to the backend —the only one that does something today is [spreadsheet], and what it does
/// is open the file dialog ([pickImportFile])—, so it lives with the
/// rest of the inventory catalog and not in a service.
///
/// The ones that are not ready yet ([ready] in `false`) are shown anyway, disabled,
/// with their "coming soon" tag: the whole listing is the promise of where the inventory will
/// come in from, and hiding the missing ones would make asking the only way to
/// find out. They light up one by one as the
/// backend supports them, changing [ready] and adding their flow in the modal.
class ImportSource {
  const ImportSource({
    required this.value,
    required this.label,
    required this.hint,
    required this.icon,
    this.ready = false
  });

  /// Source code. It does not travel anywhere: it is what the modal answers
  /// with to say which was chosen, and what the section looks at to know which flow to open.
  final String value;

  /// What the source is called in the list.
  final String label;

  /// What that source brings, in one line. It is what separates two options that are
  /// similarly named: "Google Sheets" and "OpenDocument" are both a spreadsheet
  /// and not the same thing.
  ///
  /// It is also how it is found when searching: whoever has their inventory
  /// in an Excel types "excel" and not "spreadsheet", and that word is here.
  final String hint;

  final IconData icon;

  /// Whether the source already works. The one that does not is drawn disabled and cannot be
  /// touched.
  final bool ready;

  /// Upload a team spreadsheet: the only source that works today.
  static const spreadsheet = "SPREADSHEET";

  /// Whether this source matches a search of [query], which arrives in lowercase and
  /// without spaces on the edges.
  ///
  /// It looks at the name and also at what the source says it brings, which is where the
  /// words one actually searches by are: "excel", "csv", "store".
  bool matches(String query) =>
    query.isEmpty ||
    label.toLowerCase().contains(query) ||
    hint.toLowerCase().contains(query);

  /// The sources grouped, **in the order they are shown**.
  ///
  /// The order is half the screen and it is neither alphabetical nor by format: it goes
  /// from what anyone recognizes to what only someone who knows what it is recognizes.
  /// First the team spreadsheet, which is where most inventories come from today
  /// (and the only one that already works); then the applications and
  /// stores, from the most used to the least; and at the end the loose formats.
  ///
  /// `JSON` and `XML` go last on purpose: they are two acronyms that say nothing to someone who
  /// does not program, and on top of everything they would make reading the whole list
  /// feel technical.
  static List<ImportSourceGroup> groups(BuildContext context) => [
    ImportSourceGroup(
      label: S.of(context).import_source_device,
      sources: [
        ImportSource(
          value: spreadsheet,
          label: S.of(context).import_source_spreadsheet,
          hint: S.of(context).import_source_spreadsheet_hint,
          icon: Icons.file_upload_outlined,
          ready: true
        )
      ]
    ),
    ImportSourceGroup(
      label: S.of(context).import_source_apps,
      sources: [
        ImportSource(
          value: "GOOGLE_SHEETS",
          label: S.of(context).import_source_google_sheets,
          hint: S.of(context).import_source_google_sheets_hint,
          icon: CI.google
        ),
        ImportSource(
          value: "SHOPIFY",
          label: S.of(context).import_source_shopify,
          hint: S.of(context).import_source_shopify_hint,
          icon: CI.shop
        ),
        ImportSource(
          value: "NOTION",
          label: S.of(context).import_source_notion,
          hint: S.of(context).import_source_notion_hint,
          icon: Icons.article_outlined
        ),
        ImportSource(
          value: "WOOCOMMERCE",
          label: S.of(context).import_source_woocommerce,
          hint: S.of(context).import_source_woocommerce_hint,
          icon: CI.cart_shopping
        ),
        ImportSource(
          value: "AIRTABLE",
          label: S.of(context).import_source_airtable,
          hint: S.of(context).import_source_airtable_hint,
          icon: Icons.grid_on_outlined
        ),
        ImportSource(
          value: "TRELLO",
          label: S.of(context).import_source_trello,
          hint: S.of(context).import_source_trello_hint,
          icon: Icons.dashboard_outlined
        ),
        ImportSource(
          value: "MAGENTO",
          label: S.of(context).import_source_magento,
          hint: S.of(context).import_source_magento_hint,
          icon: CI.store
        ),
        ImportSource(
          value: "SMARTSHEET",
          label: S.of(context).import_source_smartsheet,
          hint: S.of(context).import_source_smartsheet_hint,
          icon: Icons.grid_view_outlined
        )
      ]
    ),
    ImportSourceGroup(
      label: S.of(context).import_source_formats,
      sources: [
        // It deliberately overlaps with [spreadsheet], which already accepts `.ods` in the
        // dialog: when it exists, it will be the path for whoever comes from
        // LibreOffice and looks for their format by name, not another parser.
        ImportSource(
          value: "ODS",
          label: S.of(context).import_source_ods,
          hint: S.of(context).import_source_ods_hint,
          icon: Icons.table_chart_outlined
        ),
        ImportSource(
          value: "JSON",
          label: S.of(context).import_source_json,
          hint: S.of(context).import_source_json_hint,
          icon: Icons.data_object
        ),
        ImportSource(
          value: "XML",
          label: S.of(context).import_source_xml,
          hint: S.of(context).import_source_xml_hint,
          icon: Icons.code
        )
      ]
    )
  ];
}

/// A group of sources with the title that heads it in the list.
///
/// The groups are what make the list readable at a glance: where the file comes from,
/// which application it is brought from, and —at the end— the formats for those who
/// know them.
class ImportSourceGroup {
  const ImportSourceGroup({required this.label, required this.sources});

  final String label;
  final List<ImportSource> sources;

  /// The group with only the sources that match the search. Returns `null`
  /// if none remain: that group is not drawn, and without this its title would remain
  /// alone, heading nothing.
  ImportSourceGroup? search(String query) {
    if (query.isEmpty) return this;

    final found = sources.where((source) => source.matches(query)).toList();

    return found.isEmpty
      ? null
      : ImportSourceGroup(label: label, sources: found);
  }
}
