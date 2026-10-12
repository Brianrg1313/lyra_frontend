import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_data_source.dart';
import 'package:app/services/channels/channel_tools.dart';
import 'package:app/services/money/money_methods_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/channels/form/widgets/data_table_select.dart';
import 'package:app/screens/home/sections/channels/form/widgets/payment_picker_note.dart';

import './choice_card.dart';

/// What the agent does on the channel, each role with what it means. The
/// same choice as the form's `AgentPicker`, written out for a first time.
class RoleStep extends StatelessWidget {
  const RoleStep({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChannelAgentRole>(
    valueListenable: controller.role,
    builder: (context, selected, _) => Column(children: [
      for (final role in ChannelAgentRole.values) ChoiceCard(
        icon: role.icon,
        title: role.title(context),
        detail: role.subtitle(context),
        selected: role == selected,
        action: () => controller.role.value = role
      )
    ])
  );
}

/// Where the agent reads from, filtered by the role (as the form's
/// `DataPicker`), and which table once a product table is picked.
class SourceStep extends StatelessWidget {
  const SourceStep({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChannelAgentRole>(
    valueListenable: controller.role,
    builder: (context, role, _) => ValueListenableBuilder<ChannelDataSource>(
      valueListenable: controller.source,
      builder: (context, selected, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final source in ChannelDataSource.allowedFor(role)) ChoiceCard(
            icon: source.icon,
            title: source.title(context),
            detail: source.subtitle(context),
            selected: source == selected,
            enabled: source.available,
            badge: source.available ? null : S.of(context).channel_source_soon,
            action: () => controller.source.value = source
          ),
          if (selected.needsTable) Padding(
            padding: EdgeInsets.only(top: AppSize.spaceXS),
            child: DataTableSelect(controller: controller)
          )
        ]
      )
    )
  );
}

/// The company's accounts the channel may hand out; none is fine. Same states
/// as the form's `PaymentPicker`.
class PaymentsStep extends StatelessWidget {
  const PaymentsStep({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyMethodsService>();

    return switch (service.status) {
      MoneyMethodsStatus.error => PaymentPickerNote(
        text: S.of(context).channel_payments_error,
        action: service.retry,
        actionLabel: S.of(context).finance_retry
      ),
      MoneyMethodsStatus.empty => PaymentPickerNote(
        text: S.of(context).channel_payments_empty,
        badge: BadgePlace.paymentMethodField
      ),
      MoneyMethodsStatus.ready => ValueListenableBuilder<Set<String>>(
        valueListenable: controller.methods,
        builder: (context, selected, _) => Column(children: [
          for (final method in service.methods) ChoiceCard(
            // Cash is handed over in person: nothing to send the customer to.
            icon: method.method == "cash" ? CI.cashbox : CI.discount_card,
            title: method.title,
            detail: method.subtitle,
            selected: selected.contains(method.id),
            multiple: true,
            action: () => controller.toggleMethod(method.id)
          )
        ])
      ),
      _ => const Center(child: Loading())
    };
  }
}

/// What the agent handles besides text, each with what it does.
class ToolsStep extends StatelessWidget {
  const ToolsStep({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<ChannelTool>>(
    valueListenable: controller.tools,
    builder: (context, selected, _) => Column(children: [
      for (final tool in ChannelTool.values) ChoiceCard(
        icon: tool.icon,
        title: tool.title(context),
        detail: tool.subtitle(context),
        selected: selected.contains(tool),
        multiple: true,
        action: () => controller.toggleTool(tool)
      )
    ])
  );
}
