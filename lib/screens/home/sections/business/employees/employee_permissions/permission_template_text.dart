import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/permission_member_model.dart';

// WIDGETS


/// A template's name and description in this app's words: the platform's by code, a company's
/// as its people wrote them.
({String name, String? description}) permissionTemplateText(BuildContext context, PermissionTemplateModel template) {
  final s = S.of(context);
  if (!template.global) return (name: template.name, description: template.description);

  return switch (template.id) {
    "owner" => (name: s.permission_preset_owner, description: s.permission_preset_owner_description),
    "manager" => (name: s.permission_preset_manager, description: s.permission_preset_manager_description),
    "marketing" => (name: s.permission_preset_marketing, description: s.permission_preset_marketing_description),
    "seller" => (name: s.permission_preset_seller, description: s.permission_preset_seller_description),
    "auditor" => (name: s.permission_preset_auditor, description: s.permission_preset_auditor_description),
    "billing" => (name: s.permission_preset_billing, description: s.permission_preset_billing_description),
    "finance" => (name: s.permission_preset_finance, description: s.permission_preset_finance_description),
    _ => (name: template.name, description: template.description)
  };
}
