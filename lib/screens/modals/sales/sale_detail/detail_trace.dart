import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **Where this sale comes from and what happened to it when.**
///
/// It is the block somebody reads when the money and the products are not the
/// question: which till rang it up, which assistant arranged it, who sold it,
/// and the three moments a sale has — when the first product went on it, when
/// it was charged, and when it last moved. They are three different instants
/// and one figure cannot carry all of them: on a one-shot checkout the first
/// two are the same second, and on an invoice somebody kept open they are
/// twenty minutes apart.
///
/// **Nothing here is invented when it is absent.** A sale too old to carry an
/// origin block, a conversation with no seller and a ticket with no note are
/// all rows that are simply not drawn, rather than rows that say zero.
class SaleDetailTrace extends StatelessWidget {
  const SaleDetailTrace({
    super.key,
    required this.sale,
    required this.catalog
  });

  final SaleDetailModel sale;

  /// What the channel codes are called. Passed in and not read off a provider:
  /// the sales section that owns it lives *under* the navigator this panel is
  /// opened on, which is the same reason the handover panel takes its modes as
  /// a parameter.
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final origin = sale.origin;

    return SettingsBlock(
      title: S.of(context).sales_detail_trace,
      child: SettingsList(rows: [
        SettingsValue(
          icon: CI.network,
          label: S.of(context).sales_detail_channel,
          value: catalog.channelName(sale.channel),
          empty: S.of(context).sales_detail_none
        ),
        if (origin != null && origin.terminal.isNotEmpty) SettingsValue(
          icon: CI.store,
          label: S.of(context).sales_detail_terminal,
          value: origin.terminal
        ),
        if (origin != null && origin.bot.isNotEmpty) SettingsValue(
          icon: CI.ia,
          label: S.of(context).sales_detail_bot,
          value: origin.bot,
          hint: origin.address.isEmpty
            ? null
            : "${S.of(context).sales_detail_address}: ${origin.address}"
        ),
        if (sale.seller.isNotEmpty) SettingsValue(
          icon: CI.employee_badge,
          label: S.of(context).sales_detail_seller,
          value: sale.seller
        ),
        if (sale.contact.isNotEmpty) SettingsValue(
          icon: CI.phone,
          label: S.of(context).sales_detail_contact,
          value: sale.contact,
          // It is dialled or pasted into a message, not read.
          selectable: true
        ),
        if (sale.note.isNotEmpty) SettingsValue(
          icon: CI.pen,
          label: S.of(context).sales_detail_note,
          value: sale.note
        ),
        if (sale.since != null) SettingsValue(
          icon: CI.task_list,
          label: S.of(context).sales_detail_stage_since,
          value: saleDateLabel(context, sale.since),
          // The stage is measured on every read, so the panel says both what it
          // is and how long it has been that — the figure the board is scanned
          // by, written out here as the moment it happened.
          hint: saleWaitLabel(context, sale.since)
        ),
        if (sale.opened != null) SettingsValue(
          icon: CI.calendar,
          label: S.of(context).sales_detail_opened,
          value: saleDateLabel(context, sale.opened)
        ),
        if (sale.closed != null) SettingsValue(
          icon: CI.chack_circle,
          label: S.of(context).sales_detail_closed,
          value: saleDateLabel(context, sale.closed)
        ),
        if (sale.updated != null) SettingsValue(
          icon: CI.chart,
          label: S.of(context).sales_detail_updated,
          value: saleDateLabel(context, sale.updated)
        ),
        SettingsValue(
          icon: CI.key,
          // What identifies the sale outside this screen: it is what goes in a
          // support message, so it is selectable and it is last — nobody reads
          // a panel for it.
          label: sale.isDeal
            ? S.of(context).sales_detail_chat
            : S.of(context).sales_detail_id,
          value: sale.id,
          selectable: true
        )
      ])
    );
  }
}
