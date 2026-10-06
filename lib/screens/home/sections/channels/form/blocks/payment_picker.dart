import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:core/button.dart';

// SERVICES
import 'package:app/services/money/money_methods_service.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/screens/home/badges/badge_mark.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// Which of the company's accounts this channel may tell a customer to pay
/// into.
///
/// **Several can be chosen and choosing none is normal.** A company charges
/// through accounts that are not all public —the owner's personal Zelle, the
/// account a distributor pays into— so a channel hands out the ones it was
/// given and no others; a channel given none simply never brings up paying.
/// That is why the block has no "all of them" shortcut: the whole point is
/// that this list is narrower than the company's.
///
/// The options are the accounts as the money screen wrote them
/// ([MoneyMethodsService]), which is also why an account turned off there
/// disappears from here on its own. Adding one is not solved from this form —
/// it is a whole other sheet, with the bank and the number a customer is
/// actually told — so when there are none this says where to go instead of
/// drawing an empty grid.
class PaymentPicker extends StatelessWidget {
  const PaymentPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyMethodsService>();

    return FormBlock(
      title: S.of(context).channel_payments_title,
      subtitle: S.of(context).channel_payments_subtitle,
      child: switch (service.status) {
        // The accounts are their own read, so failing to get them takes this
        // block down and nothing else: the rest of the channel is still
        // editable and saving it leaves the selection as it was.
        MoneyMethodsStatus.error => _Note(
          text: S.of(context).channel_payments_error,
          action: service.retry,
          actionLabel: S.of(context).finance_retry
        ),
        MoneyMethodsStatus.empty => _Note(
          text: S.of(context).channel_payments_empty,
          badge: BadgePlace.paymentMethodField
        ),
        MoneyMethodsStatus.ready => ValueListenableBuilder<Set<String>>(
          valueListenable: controller.methods,
          builder: (context, selected, _) => OptionGrid(children: [
            for (final method in service.methods) OptionCard(
              // Cash is the one account with nothing to write down, and the
              // one a customer is told about rather than sent to.
              icon: method.method == _cash ? CI.cashbox : CI.discount_card,
              title: method.title,
              // The institution and the number, which is what tells two
              // accounts of the same rail apart. A rail with nothing to write
              // down falls back to its own name so the card is not left with
              // a title and a blank line under it.
              subtitle: method.subtitle.isNotEmpty ? method.subtitle : method.name,
              selected: selected.contains(method.id),
              multiple: true,
              action: () => controller.toggleMethod(method.id)
            )
          ])
        ),
        _ => Padding(
          padding: EdgeInsets.only(top: AppSize.spaceXS),
          child: const Center(child: Loading())
        )
      }
    );
  }

  /// Settlement kind of the accounts money is handed over in person for.
  static const String _cash = "cash";
}

/// What is said in place of the grid: there is nothing to choose from yet, or
/// the accounts could not be read.
class _Note extends StatelessWidget {
  const _Note({required this.text, this.action, this.actionLabel, this.badge});

  final String text;
  final void Function()? action;
  final String? actionLabel;

  /// The company-wide alert behind an empty list (no way of being paid), on the icon.
  final BadgePlace? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final retry = action;
    final label = actionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (badge != null) BadgeCorner(
            place: badge!,
            dot: true,
            outside: true,
            child: Icon(CI.info, size: AppSize.text * 1.2, color: scheme.icon)
          )
          else Icon(CI.info, size: AppSize.text * 1.2, color: scheme.icon),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextSmall(
            text,
            lines: 3,
            ellipsis: true,
            color: scheme.text.secondary
          ))
        ]),
        if (retry != null && label != null) ...[
          SizedBox(height: AppSize.spaceXS),
          Button(width: null, title: label, action: retry)
        ]
      ]
    );
  }
}
