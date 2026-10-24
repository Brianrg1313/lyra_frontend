import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/deployment.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/money/money_currencies_service.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_methods_service.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_notes.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/finance/exchange_currency_form/_exchange_currency_form.dart';
import 'package:app/screens/modals/finance/payment_method_form/_payment_method_form.dart';
import 'package:app/screens/modals/server/master_password/_master_password.dart';

import './currencies_block.dart';
import './method_card.dart';
import './methods_heading.dart';

/// Payment methods tab: what money this company takes, and how it can be paid.
///
/// It is the one tab that does not read money — it is what the other three
/// depend on. It comes in two halves, in the order one depends on the other:
///
/// 1. **Currencies** ([MoneyCurrenciesBlock]): the main one the catalog is
///    priced in, and the exchange currencies the company also takes, each at
///    the official rate or at its own.
/// 2. **Payment methods**: every account is a rail the company turned on plus
///    the data only the shop can fill in, the currency money comes into it in,
///    and the commission it adds to the charge. It is what a customer is told
///    when they ask where to send the transfer.
///
/// Each half loads and fails on its own: a feed that did not answer is no
/// reason to hide the accounts, nor the other way round.
///
/// **Turning an account off does not erase it.** Payments were recorded against
/// it, and a history that cannot say where money came in is one nobody can
/// reconcile against a bank statement, so the row is soft-deleted on the other
/// side: it stops being offered and the movements that name it still read. The
/// same goes for an exchange currency.
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
      if (!mounted) return;

      context.read<MoneyCurrenciesService>().load();
      context.read<MoneyMethodsService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencies = context.watch<MoneyCurrenciesService>();
    final methods = context.watch<MoneyMethodsService>();

    return ScrollableWidget(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BadgeNotes(
          place: BadgePlace.financeMethods,
          padding: EdgeInsets.only(bottom: AppSize.spaceM)
        ),
        MoneyCurrenciesBlock(
          service: currencies,
          onAdd: _addCurrency,
          onEdit: _editCurrency,
          onRemove: _removeCurrency
        ),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceM)
        ),
        MethodsHeading(
          title: S.of(context).finance_methods_title,
          subtitle: S.of(context).finance_methods_subtitle,
          // The empty state offers it in the middle of the half instead: with
          // nothing on screen, a button in the corner is easy to miss.
          actionLabel: methods.status == MoneyMethodsStatus.ready
            ? S.of(context).finance_methods_add
            : null,
          onAction: _add
        ),
        SizedBox(height: AppSize.spaceS),
        _methods(context, methods, _main(currencies))
      ]
    );
  }

  Widget _methods(
    BuildContext context,
    MoneyMethodsService service,
    String main
  ) => switch (service.status) {
    MoneyMethodsStatus.error => Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
      child: SectionMessage(
        icon: CI.info,
        title: S.of(context).finance_methods_error_title,
        subtitle: S.of(context).finance_methods_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).finance_retry
      )
    ),
    MoneyMethodsStatus.locked => Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
      child: SectionMessage(
        icon: CI.key,
        title: S.of(context).finance_methods_locked_title,
        subtitle: S.of(context).finance_methods_locked_subtitle,
        action: _unseal,
        actionLabel: S.of(context).finance_methods_unlock
      )
    ),
    // No account is the normal state on the first day and not a failure: a
    // company that has not told anybody how to pay it simply has not got
    // round to it.
    MoneyMethodsStatus.empty => Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
      child: SectionMessage(
        icon: CI.discount_card,
        title: S.of(context).finance_methods_empty_title,
        subtitle: S.of(context).finance_methods_empty_subtitle,
        action: _add,
        actionLabel: S.of(context).finance_methods_add,
        actionIcon: CI.plus
      )
    ),
    MoneyMethodsStatus.ready => Wrap(
      spacing: AppSize.gap,
      runSpacing: AppSize.gap,
      children: [
        for (final method in service.methods) MoneyMethodCard(
          method: method,
          fields: service.fields(method.code),
          main: main,
          onEdit: () => _edit(method),
          onRemove: () => _remove(method)
        )
      ]
    ),
    _ => Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
      child: const Center(child: Loading())
    )
  };

  /// The main currency: the setup's, else the business's own (`/init`), which
  /// is what the catalog is priced in even while the setup has not answered.
  String _main(MoneyCurrenciesService service) =>
    service.currencies.main.isNotEmpty
      ? service.currencies.main
      : context.read<BusinessService>().currencyCode;

  /// The password opens the session's sealed details (`session.md` S-13); the list is read again.
  Future<void> _unseal() async {
    if (await showUnseal(context) && mounted) await context.read<MoneyMethodsService>().retry();
  }

  Future<void> _add() => _form();

  Future<void> _edit(MoneyMethod method) => _form(method: method);

  /// Opens the account form and writes what it hands back.
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
  ///
  /// The currencies go in for the same reason: the account's currency is
  /// picked out of them.
  Future<void> _form({MoneyMethod? method}) async {
    final service = context.read<MoneyMethodsService>();
    final currencies = context.read<MoneyCurrenciesService>();

    final (_, _, doorDelivery) = await (service.loadRails(), currencies.load(), _doorDelivery()).wait;
    if (!mounted) return;

    final request = await showPaymentMethodForm(
      context,
      rails: service.rails,
      sheets: {
        for (final rail in service.rails) rail.code: service.fields(rail.code),
        if (method != null) method.code: service.fields(method.code)
      },
      options: service.options,
      currencies: currencies.currencies,
      doorDelivery: doorDelivery,
      method: method
    );

    if (request == null || !mounted) return;

    await (method == null
      ? service.create(context, request: request)
      : service.update(context, request: request));
  }

  /// Whether the company delivers through its own riders or a platform's: only those
  /// orders can be paid when they arrive, a parcel courier is paid before it ships.
  /// Cloud only, where the assistant takes orders; a read that fails reads no.
  Future<bool> _doorDelivery() async {
    if (Deployment.mode != DeploymentMode.cloud) return false;

    final delivery = BusinessDeliveryService();
    await delivery.load();
    final answer = delivery.delivery;
    delivery.dispose();

    if (answer == null || answer.delivers == false) return false;

    return answer.options.any((option) => option.mode != DeliveryMode.courier);
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

  Future<void> _addCurrency() => _currencyForm();

  Future<void> _editCurrency(MoneyExchange exchange) =>
    _currencyForm(exchange: exchange);

  /// Opens the exchange currency form and writes what it hands back.
  Future<void> _currencyForm({MoneyExchange? exchange}) async {
    final service = context.read<MoneyCurrenciesService>();
    final setup = service.currencies;

    final request = await showExchangeCurrencyForm(
      context,
      main: _main(service),
      taken: [for (final row in setup.exchanges) row.currency],
      exchange: exchange
    );

    if (request == null || !mounted) return;

    await service.save(context, request: request);
  }

  /// Takes an exchange currency off, after asking. The warning names what
  /// depends on it: an account in that currency stays, with nothing to convert
  /// its charge into.
  Future<void> _removeCurrency(MoneyExchange exchange) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).finance_currency_remove_title,
      message: S.of(context).finance_currency_remove_message(exchange.currency),
      confirmText: S.of(context).finance_currency_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    await context.read<MoneyCurrenciesService>().remove(
      context,
      exchange.currency
    );
  }
}
