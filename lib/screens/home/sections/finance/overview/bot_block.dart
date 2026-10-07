import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/money/money_bot_model.dart';
import 'package:app/services/money/money_bot_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';
import 'package:app/screens/home/sections/finance/overview/widgets/money_bot_row.dart';

import './range_picker.dart';

/// What Lyra costs the company.
///
/// Lyra is the bot that answers this company's customers, and the card reads as
/// what it did —replies, images and voice notes, lookups, reading the tables it
/// answers from— and not as a bill for "the AI": the four figures are its work,
/// which is the thing somebody can actually act on.
///
/// **It sits under the money and not among it.** Nobody records this as a
/// payment —it is measured from the providers' own counters— and it is billed
/// in dollars while the rest of the section is in the company's currency, so
/// adding it to an expense would be adding two currencies and a figure nobody
/// entered. It is drawn where the credit is drawn, and for the same reason: a
/// real number the screen has to show that no movement backs.
///
/// **It carries its own window.** The money above is usually read for today
/// while "how much is the bot costing me" is a question about the month, and
/// one shared picker would force somebody to move the whole screen to answer
/// one card (see [MoneyBotService]).
///
/// The four areas —answering messages, reading tables, the search index, and
/// what could not be attributed— are disjoint and add up to the total, which is why
/// they are drawn as lines under one figure instead of as four cards of their
/// own: they are the composition of the total, not four totals.
class MoneyBotBlock extends StatefulWidget {
  const MoneyBotBlock({super.key});

  @override
  State<MoneyBotBlock> createState() => _MoneyBotBlockState();
}

class _MoneyBotBlockState extends State<MoneyBotBlock> {
  /// What the states that are not the figures reserve. The block lives in the
  /// same scroll as the summary, so its message needs a height of its own: a
  /// [SectionMessage] centres itself in what it is given, and in a scroll that
  /// is nothing.
  static const double _messageHeight = 220;

  @override
  void initState() {
    super.initState();

    // Deferred to the first frame for the same reason the summary's read is:
    // loading notifies the service, and notifying while the tree mounts is a
    // rebuild in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoneyBotService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyBotService>();

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context, service),
          SizedBox(height: AppSize.padding),
          _body(context, service)
        ]
      )
    );
  }

  /// The title and the window it is read over. They wrap instead of shrinking:
  /// on a narrow body the picker goes onto its own line rather than losing the
  /// options at its right edge.
  Widget _header(BuildContext context, MoneyBotService service) => Wrap(
    spacing: AppSize.gap,
    runSpacing: AppSize.gap,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          CI.message_ai,
          size: AppSize.text,
          color: ThemeColor.of(context).primary
        ),
        SizedBox(width: AppSize.gap),
        TextMedium(S.of(context).finance_bot_title, bold: true)
      ]),
      MoneyRangePicker(range: service.range, onRange: service.select)
    ]
  );

  Widget _body(BuildContext context, MoneyBotService service) =>
    switch (service.status) {
      MoneyBotStatus.error => SizedBox(
        height: _messageHeight,
        child: SectionMessage(
          icon: CI.info,
          title: S.of(context).finance_bot_error_title,
          subtitle: S.of(context).finance_bot_error_subtitle,
          action: service.retry,
          actionLabel: S.of(context).finance_retry
        )
      ),
      MoneyBotStatus.empty || MoneyBotStatus.ready =>
        _spend(context, service.spend),
      _ => const SizedBox(
        height: _messageHeight,
        child: Center(child: Loading())
      )
    };

  /// The total, what it is made of, and the window it belongs to.
  ///
  /// A window with no spend keeps the total —a zero that was measured is an
  /// answer— and drops the lines: four noughts say nothing that the sentence
  /// under them does not.
  Widget _spend(BuildContext context, MoneyBotSpend spend) {
    final scheme = ThemeColor.of(context);
    final currency = spend.currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The figure the card exists for, so it is written in the plain text
        // colour —white on the dark theme, black on the light one— and in bold.
        // The brand colour it used to carry made it one more accent on a screen
        // already full of them; a price is read faster than it is decoded.
        // A [TextMedium] at the large size and not a [TextLarge]: that one does
        // not carry `bold`, and the weight is half of what makes this figure
        // findable.
        TextMedium(
          moneyFineLabel(spend.total, currency),
          bold: true,
          multiplier: 2,
          color: scheme.text.primary,
          ellipsis: true
        ),
        SizedBox(height: AppSize.gap),
        TextSmall(
          S.of(context).finance_bot_hint(currency),
          color: scheme.text.secondary,
          multiplier: 0.9
        ),
        if (spend.isEmpty) ...[
          SizedBox(height: AppSize.padding),
          TextSmall(
            S.of(context).finance_bot_empty,
            color: scheme.text.secondary
          )
        ] else
          ..._lines(context, spend),
        SizedBox(height: AppSize.padding),
        // The window the backend answered about and the work that was billed in
        // it: the cost of a month only means something beside how much was
        // answered in it.
        TextSmall(
          "${S.of(context).finance_window(
            moneyDayLabel(context, spend.from),
            moneyDateLabel(context, spend.to)
          )}"
          "  ·  ${S.of(context).finance_bot_activity(
            moneyCount(context, spend.answers.conversations),
            moneyCount(context, spend.answers.messages)
          )}",
          color: scheme.text.secondary,
          multiplier: 0.9
        )
      ]
    );
  }

  /// The composition of the total.
  ///
  /// Unattributed spend is only drawn when there is any: it is money that
  /// happened and the backend reports it rather than dropping it, but a nought
  /// beside three real figures reads as a fourth area of the product.
  List<Widget> _lines(BuildContext context, MoneyBotSpend spend) {
    final currency = spend.currency;
    final strings = S.of(context);

    return [
      SizedBox(height: AppSize.spaceXS),
      MoneyBotRow(
        icon: CI.chat,
        title: strings.finance_bot_answers,
        amount: moneyFineLabel(spend.answers.total, currency),
        // What answering is made of —writing the reply, reading what was
        // sent in, looking something up— named and not priced: the split is
        // what the line covers, and a figure beside each one is three more
        // prices competing with the one that is being looked for.
        detail: _detail([
          strings.finance_bot_text,
          strings.finance_bot_media,
          strings.finance_bot_research
        ])
      ),
      MoneyBotRow(
        icon: CI.tables,
        title: strings.finance_bot_tables,
        amount: moneyFineLabel(spend.tables.total, currency),
        detail: strings.finance_bot_tables_hint(
          moneyCount(context, spend.tables.count)
        )
      ),
      MoneyBotRow(
        icon: CI.search,
        title: strings.finance_bot_vectors,
        amount: moneyFineLabel(spend.vectors.total, currency),
        detail: _detail([
          strings.finance_bot_catalog,
          strings.finance_bot_queries
        ])
      ),
      if (spend.other > 0)
        MoneyBotRow(
          icon: CI.info,
          title: strings.finance_bot_other,
          amount: moneyFineLabel(spend.other, currency),
          detail: strings.finance_bot_other_hint
        )
    ];
  }

  static String _detail(List<String> parts) => parts.join("  ·  ");
}
