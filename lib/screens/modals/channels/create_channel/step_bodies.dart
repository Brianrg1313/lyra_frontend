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

/// WhatsApp Personal has no keys to paste: in their place, what happens once
/// the channel is created, in three numbered lines.
class QrStep extends StatelessWidget {
  const QrStep({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = [
      (CI.check, S.of(context).channel_step_qr_create),
      (CI.qr_code, S.of(context).channel_step_qr_scan),
      (CI.chat, S.of(context).channel_step_qr_done)
    ];

    return Column(children: [
      for (final (index, (icon, text)) in lines.indexed) _QrLine(
        number: index + 1,
        icon: icon,
        text: text
      )
    ]);
  }
}

class _QrLine extends StatelessWidget {
  const _QrLine({required this.number, required this.icon, required this.text});

  final int number;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Row(children: [
        Container(
          width: AppSize.button,
          height: AppSize.button,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: scheme.surfaceOver, shape: BoxShape.circle),
          child: TextMedium("$number", bold: true)
        ),
        SizedBox(width: AppSize.spaceXS),
        Icon(icon, size: AppSize.text * 1.3, color: scheme.icon),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: TextMedium(text, lines: 2, ellipsis: true))
      ])
    );
  }
}
