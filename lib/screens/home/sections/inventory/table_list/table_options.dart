import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/inventory/transfers/_transfers.dart';
import 'package:app/screens/modals/inventory/rename_table/_rename_table.dart';
import 'package:app/screens/modals/inventory/table_settings/_table_settings.dart';

/// The open table's options, first of the inventory bar's actions (before import and
/// create), with the dropdown it deploys (anchored to the button, which is why it is its
/// own widget).
///
/// It also carries the way to the transfers between branches, last and only with another
/// branch and `inventory.transfers` (cloud only): a page of the section, not an action of
/// the bar. The shipments waiting to be received here mark the button itself, or they would
/// go unseen behind the menu.
///
/// It offers the three things that can be done to a table without opening it:
///
/// - **Rename it**, which is the only thing of its header read from here.
/// - **Open its settings**, which is everything else: the description, the
///   columns, the channels and the dates.
/// - **Delete it**.
///
/// Renaming and configuring are the same thing seen up close and from afar, and
/// that's why they're two options and not one: changing a table's name is one
/// field and one Enter, and sending it to the whole settings card for that
/// would be changing screens to write one word.
class TableOptionsButton extends StatelessWidget {
  const TableOptionsButton({super.key, required this.table, this.size});

  final TableLiteModel table;

  /// How much the button measures; by default that of a button, like the rest of the bar.
  final double? size;

  /// Listens to the singleton itself: the bar is drawn in places (tests, the sheet) that don't
  /// provide it.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BranchService(),
    builder: (context, _) {
      final button = FeedbackButton(
        action: () => _open(context),
        width: size ?? AppSize.button,
        height: size ?? AppSize.button,
        color: ThemeColor.of(context).surfaceOver,
        message: S.of(context).table_options,
        child: Center(child: Icon(
          CI.dots_horizontal,
          size: AppSize.text * 1.2,
          color: ThemeColor.of(context).icon
        ))
      );

      return _transfers
        ? BadgeCorner(place: BadgePlace.inventoryTransfers, dot: true, outside: true, child: button)
        : button;
    }
  );

  /// Whether the transfers between branches are offered here.
  static bool get _transfers =>
    BranchService().choosable && CapabilityService().shows("inventory.transfers");

  /// Opens the dropdown anchored to the button. Without a search box and
  /// without a form's size ([dense]): they're three options, not a list.
  Future<void> _open(BuildContext context) async {
    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        SelectOption(
          value: "rename",
          placeholder: S.of(context).rename_table,
          icon: CI.edit
        ),
        SelectOption(
          value: "settings",
          placeholder: S.of(context).table_settings_title,
          icon: CI.setting
        ),
        SelectOption(
          value: "delete",
          placeholder: S.of(context).delete_table,
          icon: CI.trash
        ),
        if (_transfers) SelectOption(
          value: "transfers",
          placeholder: S.of(context).inventory_transfers_open,
          leading: BadgeCorner(
            place: BadgePlace.inventoryTransfers,
            dot: true,
            outside: true,
            child: Icon(CI.store, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon)
          )
        )
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "rename":
        await _rename(context);
      case "settings":
        await _settings(context);
      case "delete":
        await _delete(context);
      case "transfers":
        Navis.push(context, StockTransfersSection.path);
    }
  }

  /// Opens the name modal. Whatever changes it saves, the modal itself against
  /// the service, which corrects the cached table: there's nothing left to do
  /// here when it closes.
  Future<void> _rename(BuildContext context) => showModal(
    context: context,
    title: S.of(context).rename_table,
    builder: (BuildContext context) => RenameTableModal(table: table)
  );

  /// Opens the table settings: everything there is of it except its rows.
  ///
  /// It opens to the side, so the table stays in view next to it and is just as
  /// it was on closing.
  Future<void> _settings(BuildContext context) =>
    showTableSettings(context, table.id);

  /// Deletes the table, after confirmation.
  ///
  /// It's asked here and not in the service because what the deletion carries
  /// away is the table, its columns and everything loaded in them. The notice
  /// names the table so it isn't confirmed over the wrong one.
  Future<void> _delete(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).table_delete_title,
      message: S.of(context).table_delete_message(table.title),
      confirmText: S.of(context).delete_table,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // The notice is built **before** the deletion: when it goes well, this
    // button goes with its table —the section opens another— and its context
    // won't even serve to read the text.
    final message = S.of(context).table_deleted;

    final deleted = await context.read<TablesService>().remove(context, table);

    // If it failed, the error was already shown in the service and the table
    // stays, which is what's right: nothing was deleted.
    if (!deleted) return;

    // Without context: the button's was unmounted. The floating flag hangs
    // off the navigator, which is still there.
    FloatFlag.of().message(message);
  }
}
