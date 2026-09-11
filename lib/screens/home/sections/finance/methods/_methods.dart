import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_methods_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/finance/payment_method_form/_payment_method_form.dart';

import 'method_card.dart';

/// Payment methods tab: how this company can be paid.
///
/// It is the one tab that does not read money — it is what the other three
/// depend on. Every account here is a rail the company turned on plus the data
/// only the shop can fill in, and it is what a customer is told when they ask
/// where to send the transfer.
///
/// **Turning one off does not erase it.** Payments were recorded against the
/// account, and a history that cannot say where money came in is one nobody can
/// reconcile against a bank statement, so the row is soft-deleted on the other
/// side: it stops being offered and the movements that name it still read.
class FinanceMethodsTab extends StatefulWidget {
  const FinanceMethodsTab({super.key});

  @override
  State<FinanceMethodsTab> createState() => _FinanceMethodsTabState();
}

class _FinanceMethodsTabState extends State<FinanceMethodsTab> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoneyMethodsService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyMethodsService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The action is drawn on every state but the empty one, which offers it
        // in the middle of the sheet instead: with nothing on screen, a button
        // in the corner is easy to miss.
        if (service.status != MoneyMethodsStatus.empty) _Bar(onAdd: _add),
        if (service.status != MoneyMethodsStatus.empty)
          SizedBox(height: AppSize.spaceXS),
        Expanded(child: _body(context, service))
      ]
    );
  }

  Widget _body(BuildContext context, MoneyMethodsService service) =>
    switch (service.status) {
      MoneyMethodsStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).finance_methods_error_title,
        subtitle: S.of(context).finance_methods_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).finance_retry
      ),
      // No account is the normal state on the first day and not a failure: a
      // company that has not told anybody how to pay it simply has not got
      // round to it.
      MoneyMethodsStatus.empty => SectionMessage(
        icon: CI.discount_card,
        title: S.of(context).finance_methods_empty_title,
        subtitle: S.of(context).finance_methods_empty_subtitle,
        action: _add,
        actionLabel: S.of(context).finance_methods_add,
        actionIcon: CI.plus
      ),
      MoneyMethodsStatus.ready => ScrollableWidget(
        children: [
          Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: [
              for (final method in service.methods) MoneyMethodCard(
                method: method,
                fields: service.fields(method.code),
                onEdit: () => _edit(method),
                onRemove: () => _remove(method)
              )
            ]
          )
        ]
      ),
      _ => const Center(child: Loading())
    };

  Future<void> _add() => _form();

  Future<void> _edit(MoneyMethod method) => _form(method: method);

  /// Opens the form and writes what it hands back.
  ///
  /// The catalog is read **before** opening it and handed in: the panel is
  /// under a navigator the section's services are not in scope of, and a picker
  /// that fills itself in halfway through a form is a picker somebody has
  /// already scrolled past.
  ///
  /// It is waited for on an **edit** too, and not only when adding. The rail
  /// cannot change, but what it asks for is where the form gets its fields
  /// from, and the bank of a Pago Movil is a code out of the list — without it
  /// the panel would have to draw the account it is editing as four boxes
  /// nobody named. The read answers from what it already has after the first
  /// time, so the second panel opens with no wait at all.
  Future<void> _form({MoneyMethod? method}) async {
    final service = context.read<MoneyMethodsService>();

    await service.loadRails();
    if (!mounted) return;

    final request = await showPaymentMethodForm(
      context,
      rails: service.rails,
      sheets: {
        for (final rail in service.rails) rail.code: service.fields(rail.code),
        if (method != null) method.code: service.fields(method.code)
      },
      options: service.options,
      method: method
    );

    if (request == null || !mounted) return;

    await (method == null
      ? service.create(context, request: request)
      : service.update(context, request: request));
  }

  /// Turns an account off, after asking.
  ///
  /// It is [showAlertModal] and not a modal of its own, like every destructive
  /// confirmation in this app. What it warns about is what actually happens:
  /// the account stops being offered, and the payments that name it stay.
  Future<void> _remove(MoneyMethod method) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).finance_method_remove_title,
      message: S.of(context).finance_method_remove_message(method.title),
      confirmText: S.of(context).finance_method_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    await context.read<MoneyMethodsService>().remove(context, method.id);
  }
}

/// The one action of the tab.
class _Bar extends StatelessWidget {
  const _Bar({required this.onAdd});

  final void Function() onAdd;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Button(
        width: null,
        title: S.of(context).finance_methods_add,
        leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
        action: onAdd
      )
    ]
  );
}
