import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES

// WIDGETS


/// A section of the permission catalog (`PermissionCatalog.sections`, the backend's
/// `catalog.js`) as the editor draws it. The name is the catalog key, never renamed:
/// `test/permissions_test.dart` keeps this list and the catalog equal.
enum PermissionSection {
  inventory(CI.warehouse),
  reservations(CI.bookmark),
  pos(CI.cashbox),
  sales(CI.sale),
  shipments(CI.delivery_square),
  money(CI.wallet),
  employees(CI.employee),
  permissions(CI.safe_user),
  products(CI.product),
  chats(CI.chat),
  channels(CI.ia),
  appointments(CI.calendar),
  knowledge(CI.documents),
  branches(CI.shop),
  delivery(CI.delivery),
  business(CI.store),
  server(CI.cloud_network);

  const PermissionSection(this.icon);

  final IconData icon;

  /// Its actions, in the catalog's order.
  List<String> get actions => PermissionCatalog.sections[name] ?? const [];

  String title(BuildContext context) => switch (this) {
    inventory => S.of(context).permission_inventory_title,
    reservations => S.of(context).permission_reservations_title,
    pos => S.of(context).permission_pos_title,
    sales => S.of(context).permission_sales_title,
    shipments => S.of(context).permission_shipments_title,
    money => S.of(context).permission_money_title,
    employees => S.of(context).permission_employees_title,
    permissions => S.of(context).permission_permissions_title,
    products => S.of(context).permission_products_title,
    chats => S.of(context).permission_chats_title,
    channels => S.of(context).permission_channels_title,
    appointments => S.of(context).permission_appointments_title,
    knowledge => S.of(context).permission_knowledge_title,
    branches => S.of(context).permission_branches_title,
    delivery => S.of(context).permission_delivery_title,
    business => S.of(context).permission_business_title,
    server => S.of(context).permission_server_title
  };

  String description(BuildContext context) => switch (this) {
    inventory => S.of(context).permission_inventory_description,
    reservations => S.of(context).permission_reservations_description,
    pos => S.of(context).permission_pos_description,
    sales => S.of(context).permission_sales_description,
    shipments => S.of(context).permission_shipments_description,
    money => S.of(context).permission_money_description,
    employees => S.of(context).permission_employees_description,
    permissions => S.of(context).permission_permissions_description,
    products => S.of(context).permission_products_description,
    chats => S.of(context).permission_chats_description,
    channels => S.of(context).permission_channels_description,
    appointments => S.of(context).permission_appointments_description,
    knowledge => S.of(context).permission_knowledge_description,
    branches => S.of(context).permission_branches_description,
    delivery => S.of(context).permission_delivery_description,
    business => S.of(context).permission_business_description,
    server => S.of(context).permission_server_description
  };

  /// What [action] lets the person do; the key itself for one this app has no words for yet.
  String action(BuildContext context, String action) {
    final s = S.of(context);

    return switch ("$name.$action") {
      "inventory.restock" => s.permission_inventory_restock,
      "inventory.remove" => s.permission_inventory_remove,
      "inventory.return" => s.permission_inventory_return,
      "inventory.hold" => s.permission_inventory_hold,
      "inventory.transfer" => s.permission_inventory_transfer,
      "inventory.receive" => s.permission_inventory_receive,
      "inventory.configure" => s.permission_inventory_configure,
      "inventory.pictures" => s.permission_inventory_pictures,
      "reservations.create" => s.permission_reservations_create,
      "reservations.manage" => s.permission_reservations_manage,
      "pos.sell" => s.permission_pos_sell,
      "pos.cancel" => s.permission_pos_cancel,
      "sales.fulfill" => s.permission_sales_fulfill,
      "shipments.dispatch" => s.permission_shipments_dispatch,
      "shipments.configure" => s.permission_shipments_configure,
      "money.charge" => s.permission_money_charge,
      "money.void" => s.permission_money_void,
      "money.accounts" => s.permission_money_accounts,
      "money.export" => s.permission_money_export,
      "employees.manage" => s.permission_employees_manage,
      "permissions.assign" => s.permission_permissions_assign,
      "permissions.templates" => s.permission_permissions_templates,
      "products.create" => s.permission_products_create,
      "products.edit" => s.permission_products_edit,
      "products.delete" => s.permission_products_delete,
      "products.price" => s.permission_products_price,
      "products.import" => s.permission_products_import,
      "products.structure" => s.permission_products_structure,
      "chats.reply" => s.permission_chats_reply,
      "chats.manage" => s.permission_chats_manage,
      "chats.assign" => s.permission_chats_assign,
      "chats.bot" => s.permission_chats_bot,
      "channels.create" => s.permission_channels_create,
      "channels.edit" => s.permission_channels_edit,
      "channels.delete" => s.permission_channels_delete,
      "channels.connect" => s.permission_channels_connect,
      "appointments.book" => s.permission_appointments_book,
      "appointments.configure" => s.permission_appointments_configure,
      "knowledge.create" => s.permission_knowledge_create,
      "knowledge.edit" => s.permission_knowledge_edit,
      "knowledge.delete" => s.permission_knowledge_delete,
      "branches.create" => s.permission_branches_create,
      "branches.edit" => s.permission_branches_edit,
      "branches.delete" => s.permission_branches_delete,
      "delivery.create" => s.permission_delivery_create,
      "delivery.edit" => s.permission_delivery_edit,
      "delivery.delete" => s.permission_delivery_delete,
      "business.edit" => s.permission_business_edit,
      "business.emails" => s.permission_business_emails,
      "server.devices" => s.permission_server_devices,
      "server.backups" => s.permission_server_backups,
      "server.stop" => s.permission_server_stop,
      final key => key
    };
  }
}
