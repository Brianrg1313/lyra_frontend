import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/money/money_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/finance/accounting_export/_accounting_export.dart';
import 'package:app/toolkit/save_file.dart';

import '../money_format.dart';
import 'bot_block.dart';
import 'breakdown_block.dart';
import 'range_picker.dart';
import 'summary_cards.dart';

/// Overview tab: what came in, what went out, and what that leaves.
///
/// It is the tab the money page opens on because it is the question somebody
/// comes to this section to answer. The three below it are the detail of this
/// one: which movements make up these figures, who still owes part of the
/// credit, and through which accounts the money can arrive at all.
///
/// **The window is chosen here and read there**: the range picker only reports
/// to [MoneyService], which is what asks again. The figures on screen always
/// belong to the window the response came back with, never to a mix of two.
class FinanceOverviewTab extends StatefulWidget {
  const FinanceOverviewTab({super.key});

  @override
  State<FinanceOverviewTab> createState() => _FinanceOverviewTabState();
}

class _FinanceOverviewTabState extends State<FinanceOverviewTab> {
  /// While the master builds the export and it comes down: the button spins
  /// and a second click is ignored.
  final ValueNotifier<bool> _exporting = ValueNotifier(false);

  @override
  void dispose() {
    _exporting.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // It is deferred to the first frame because the load notifies the service,
    // and notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoneyService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MoneyService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The picker stays in view while the summary loads or fails: it is what
        // one reaches for after reading a bad number, and hiding it would leave
        // an error message with no way out but a retry of the same window.
        Row(children: [
          Expanded(child: MoneyRangePicker(
            range: service.range,
            onRange: service.select
          )),
          // Beside the picker and not under the figures: it is the other thing
          // one does with a period, and it doesn't depend on the summary loading.
          if (PermissionsService().can("finance.export")) Button(
            width: null,
            title: S.of(context).finance_export,
            leftIcon: Icon(CI.documents_excel, color: ThemeColor.of(context).button.text),
            loading: _exporting,
            action: _export
          )
        ]),
        SizedBox(height: AppSize.padding),
        Expanded(child: _body(context, service))
      ]
    );
  }

  /// The accounting export (`money.md` M-60): the panel picks, the master
  /// builds the file, and the person chooses where it goes.
  Future<void> _export() async {
    if (_exporting.value) return;

    final picked = await showAccountingExport(context);
    if (picked == null || !mounted) return;

    final service = context.read<MoneyService>();
    final flag = FloatFlag.of(context);
    final saved = S.of(context).finance_export_saved;
    _exporting.value = true;

    try {
      final bytes = await service.exportAccounting(picked.request);
      final kept = await saveFile(
        bytes,
        name: picked.name,
        mimeType: picked.format.mimeType,
        extension: picked.format.extension,
        label: picked.format.extension.toUpperCase()
      );

      if (kept) flag.message(saved);
    } catch (error) {
      FloatFlag.showFromError(error);
    } finally {
      _exporting.value = false;
    }
  }

  Widget _body(BuildContext context, MoneyService service) =>
    switch (service.status) {
      MoneySummaryStatus.error => _page(SizedBox(
        height: _messageHeight,
        child: SectionMessage(
          icon: CI.info,
          title: S.of(context).finance_summary_error_title,
          subtitle: S.of(context).finance_summary_error_subtitle,
          action: service.retry,
          actionLabel: S.of(context).finance_retry
        )
      )),
      MoneySummaryStatus.empty => _page(SizedBox(
        height: _messageHeight,
        child: SectionMessage(
          icon: CI.wallet,
          title: S.of(context).finance_summary_empty_title,
          subtitle: S.of(context).finance_summary_empty_subtitle
        )
      )),
      MoneySummaryStatus.ready => _page(_summary(context, service)),
      _ => const Center(child: Loading())
    };

  /// What a message of the money half reserves when it shares the scroll with
  /// Lyra's block: a [SectionMessage] centres itself in what it is given, and
  /// in a scroll that is nothing.
  static const double _messageHeight = 260;

  /// The tab's scroll: the money of the window, and under it what Lyra cost.
  ///
  /// **Lyra's block is drawn whatever the money did**, failure and quiet day
  /// included: it is a separate read over a separate window, and a company that
  /// answers customers all month without recording a payment would otherwise be
  /// told nothing moved while it is being charged. It is the cloud's measure, so
  /// a master in `local` has none to draw.
  Widget _page(Widget money) => ScrollableWidget(
    // Stretched and not left-aligned, which is the scroll's default: Lyra's
    // block is a sheet of its own and a sheet as wide as its longest line reads
    // as a card that failed to lay out.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      money,
      if (CapabilityService().shows("finance.overview.view_bot_cost")) ...[
        SizedBox(height: AppSize.padding),
        Separator.horizontal(),
        SizedBox(height: AppSize.padding),
        const MoneyBotBlock()
      ]
    ]
  );

  /// The figures of the window: the four cards and, under them, where the money
  /// came in and went out through.
  Widget _summary(BuildContext context, MoneyService service) {
    final summary = service.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MoneySummaryCards(summary: summary),
        SizedBox(height: AppSize.padding),
        MoneyBreakdown(summary: summary),
        SizedBox(height: AppSize.spaceXS),
        // The window the backend actually answered about, which is not always
        // the one that was asked for: today is resolved on its side, against
        // the server's day, so that this screen and the counter never disagree
        // about when the day started.
        TextSmall(
          S.of(context).finance_window(
            moneyDayLabel(context, summary.from),
            moneyDateLabel(context, summary.to)
          ),
          color: ThemeColor.of(context).text.secondary,
          multiplier: 0.9
        )
      ]
    );
  }
}
