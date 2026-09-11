import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

// WIDGETS
import 'package:core/form.dart';

import './stage_tag.dart';

/// **The bar above the board**: what the list is showing on the left, what
/// narrows it on the right.
///
/// It is one row. The count and the controls answer two halves of the same
/// question —how much there is, and of what— and reading them as two stacked
/// strips cost the board a line it needed for rows.
///
/// **Every control here is the service's and travels to the backend**, none of
/// them is applied over the rows already read. That is not a preference: a
/// stage is measured on read and not stored, so the page that comes back is
/// already the answer to the whole question, and filtering it again here would
/// hide rows the count beside it still includes. The one thing that does narrow
/// the rows on screen is the header's search, which is not a control of this
/// bar and is the reason the bar carries a caption for it ([_SearchCaption]).
///
/// **The states are a dropdown.** They were a strip of chips, one per state
/// with its own dot, and a dozen words on a board that is read at a glance is
/// a line and a half of controls plus a horizontal scroll to reach the last
/// one. Folded into a list, the states are still the words the backend wrote
/// and still carry their dots — the open list is where they are read, and the
/// closed control says which one is on.
class SalesFilters extends StatelessWidget {
  const SalesFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SalesService>();
    final catalog = context.watch<SalesCatalogService>();

    return Padding(
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            // **Both halves flex, and the controls get four fifths of it.** The
            // count is one short sentence and the controls wear the backend's
            // words, so the space belongs to the side that can run out of it; a
            // control that lost half its label is a control nobody can read,
            // while a count with room to spare is just a count.
            _Count(service: service),
            SizedBox(width: AppSize.gap),
            Expanded(child: _Controls(service: service, catalog: catalog))
          ]),
          // The backend answers a request that names a till-only filter with
          // tickets alone: a conversation the assistant is in the middle of has
          // no seller and no channel of the kind being asked about, and filing it
          // under one would be inventing an answer. A list that quietly drops
          // half its rows is a list nobody trusts, so it says so.
          //
          // Under the row and not in it: it is a caption about what was just
          // asked for, not a fourth control.
          if (service.isTicketsOnly) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: TextSmall(
              S.of(context).sales_tickets_only,
              lines: 2,
              color: ThemeColor.of(context).text.secondary
            )
          ),
          const _SearchCaption()
        ]
      )
    );
  }
}

/// What the header's search is doing to the board, while it is doing it.
///
/// The one control on this screen that is not the backend's: the list is read a
/// page at a time and `GET /sales` takes no search, so what is typed narrows
/// the rows that have been read and nothing further down. Said out loud for the
/// same reason the tickets-only line is: somebody who searches a ticket code
/// and finds nothing has to know whether that means "not in this company" or
/// "not on this page".
///
/// It listens to the search on its own so that typing rebuilds this line and
/// the rows, and not the controls above them.
class _SearchCaption extends StatelessWidget {
  const _SearchCaption();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: context.read<HomeService>().searchQuery,
    builder: (context, query, _) => query.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: TextSmall(
            S.of(context).sales_search_scope,
            lines: 2,
            color: ThemeColor.of(context).text.secondary
          )
        )
  );
}

/// What narrows the board, at the right end of the bar.
///
/// **It scrolls from the right rather than wrapping or overflowing.** The bar
/// is one row, the labels are the backend's, and a window narrow enough turns
/// four controls into five when something is filtered — so the strip is
/// anchored at its right edge (`reverse`) and gives way leftwards. Where there
/// is room, which is every desktop, the scroll never moves and the controls sit
/// flush right.
class _Controls extends StatelessWidget {
  const _Controls({required this.service, required this.catalog});

  final SalesService service;
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    // Zero is the right end, which is both where the strip starts and where it
    // stays: the last control is the one that must never be the one cut off.
    reverse: true,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (service.pending > 0) ...[
        _Pending(service: service),
        SizedBox(width: AppSize.gap)
      ],
      _StageFilter(service: service, catalog: catalog),
      SizedBox(width: AppSize.gap),
      _ChannelFilter(service: service, catalog: catalog),
      SizedBox(width: AppSize.gap),
      _Chip(
        icon: service.mine ? CI.chekmark : CI.employee,
        title: S.of(context).sales_mine,
        isActive: service.mine,
        action: () => service.filterMine(!service.mine)
      ),
      if (service.isFiltered) ...[
        SizedBox(width: AppSize.gap),
        _Chip(
          icon: CI.delete,
          title: S.of(context).sales_clear,
          isActive: false,
          action: service.clearFilters
        )
      ],
      // The board still draws without the catalog —every row carries its own
      // label and colour— so a failed read is not an error state, it is a
      // missing control. It is offered back rather than retried on its own:
      // nothing on screen is wrong while it is gone.
      if (catalog.status == SalesCatalogStatus.error) ...[
        SizedBox(width: AppSize.gap),
        _Chip(
          icon: CI.info,
          title: S.of(context).sales_catalog_error,
          isActive: false,
          action: catalog.retry
        )
      ]
    ])
  );
}

/// How many sales the **section** holds.
///
/// It is not how many are listed, and it is not adjusted for the state filter:
/// a stage narrows the page and not the query on the other side, so a count
/// that pretended otherwise would be this app inventing a number nobody
/// measured.
class _Count extends StatelessWidget {
  const _Count({required this.service});

  final SalesService service;

  @override
  Widget build(BuildContext context) => TextSmall(
    S.of(context).sales_count(service.total),
    ellipsis: true,
    color: ThemeColor.of(context).text.secondary
  );
}

/// Sales moved while the list was somewhere it could not follow them.
///
/// It only ever appears past the first page, or after a catch-up that failed:
/// on the first page the board picks the movements up by itself. It is a button
/// and not an automatic reload for one reason — rebuilding a list from the top
/// takes away the row somebody was reading, and on a work list that is the row
/// they were about to act on.
class _Pending extends StatelessWidget {
  const _Pending({required this.service});

  final SalesService service;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: service.refresh,
      height: AppSize.button,
      message: S.of(context).sales_pending(service.pending),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.line,
      feedbackColor: scheme.lineOver,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(CI.notification, size: AppSize.text, color: scheme.text.primary),
        SizedBox(width: AppSize.gap),
        TextMedium(
          S.of(context).sales_pending(service.pending),
          bold: true,
          multiplier: 0.9,
          color: scheme.text.primary
        )
      ])
    );
  }
}

/// Where the sale stands, out of the states of the **open section**.
///
/// A tab must not be able to filter itself down to a state that belongs to the
/// other one, which is why the options are `SalesCatalogService.of(section)`
/// and not every stage there is.
///
/// Each option keeps its dot, so the list is read by colour the way the rows
/// are; the closed control carries the chosen one's, which is what says at a
/// glance that the board is narrowed and to what phase.
class _StageFilter extends StatelessWidget {
  const _StageFilter({required this.service, required this.catalog});

  final SalesService service;
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final stages = catalog.of(service.section);
    final current = catalog.stage(service.stage);

    return _MenuChip(
      icon: current == null ? CI.task_list : null,
      // The stage's own colour, on the control as well as in the list: a
      // dropdown that painted the choice only while open would say a different
      // thing about the same value depending on whether somebody is looking.
      leading: current == null
        ? null
        : SaleStageDot(
            color: saleStageColor(context, current.stage, current.level)
          ),
      title: current?.name ?? S.of(context).sales_all_stages,
      isActive: service.stage.isNotEmpty,
      selected: service.stage,
      // Offered and empty rather than hidden while the catalog is missing: a
      // control that comes and goes as a read lands is harder to read than one
      // that says it has nothing.
      options: [
        SelectOption(
          value: "",
          placeholder: S.of(context).sales_all_stages
        ),
        for (final stage in stages) SelectOption(
          value: stage.stage,
          placeholder: stage.name,
          leading: SaleStageDot(
            color: saleStageColor(context, stage.stage, stage.level)
          )
        )
      ],
      // A section has around a dozen states and they are the classification
      // this screen is about: the list opens showing as many as fit rather
      // than five and a scroll.
      maxOptions: 10,
      onSelected: service.filterStage
    );
  }
}

/// Where the sale came in through, out of the same closed vocabulary the
/// checkout's own picker is drawn from.
class _ChannelFilter extends StatelessWidget {
  const _ChannelFilter({required this.service, required this.catalog});

  final SalesService service;
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final current = service.channel;

    return _MenuChip(
      icon: CI.cloud_connected,
      title: current.isEmpty
        ? S.of(context).sales_channel
        : catalog.channelName(current),
      isActive: current.isNotEmpty,
      selected: current,
      options: [
        SelectOption(
          value: "",
          placeholder: S.of(context).sales_any_channel
        ),
        for (final channel in catalog.channels) SelectOption(
          value: channel.channel,
          placeholder: channel.name
        )
      ],
      onSelected: service.filterChannel
    );
  }
}

/// A chip that opens its list anchored to itself. Same reasoning as the money
/// history's: an input would need a controller to hold a value the service
/// already owns.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.title,
    required this.isActive,
    required this.selected,
    required this.options,
    required this.onSelected,
    this.icon,
    this.leading,
    this.maxOptions = 5
  });

  final IconData? icon;

  /// Drawn instead of [icon] when the chosen value has a mark of its own — a
  /// state's dot. See [_StageFilter].
  final Widget? leading;

  final String title;
  final bool isActive;

  /// The value currently on, so the open list shows its tick.
  final String selected;

  final List<SelectOption> options;

  /// How many options the list shows before it scrolls.
  final int maxOptions;

  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context) => _Chip(
    icon: icon,
    leading: leading,
    title: title,
    isActive: isActive,
    trailing: CI.arrow_down,
    action: () async {
      final option = await showSelectMenu(
        context: context,
        options: options,
        selected: selected,
        maxOptions: maxOptions,
        emptyText: S.of(context).sales_select_empty
      );

      if (option != null) onSelected(option.value);
    }
  );
}

/// One control of the bar. The active ones are filled with the line colour: the
/// table below is where the colour that means something lives.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.title,
    required this.isActive,
    required this.action,
    this.icon,
    this.leading,
    this.trailing
  });

  final IconData? icon;

  /// A mark of the value's own, in place of [icon]. It is drawn as it arrives:
  /// what identifies a value is not the chip's business.
  final Widget? leading;

  final String title;
  final bool isActive;
  final void Function() action;
  final IconData? trailing;

  /// Longest a control's label gets before it is cut.
  ///
  /// A chip is sized by its text, and the labels here are the backend's —a
  /// state's name, a channel's— so one long one would push the whole bar off
  /// the right edge of a narrow window. Cut at a width that still holds the
  /// longest state anybody wrote, with the full wording in the tooltip.
  static double get _maxTitle => AppSize.action * 4;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = isActive ? scheme.text.primary : scheme.text.secondary;

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: title,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.line : scheme.surfaceOver,
      feedbackColor: scheme.lineOver,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: AppSize.gap)
          ] else if (icon != null) ...[
            Icon(icon, size: AppSize.text, color: color),
            SizedBox(width: AppSize.gap)
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxTitle),
            child: TextMedium(
              title,
              bold: isActive,
              multiplier: 0.9,
              ellipsis: true,
              color: color
            )
          ),
          if (trailing != null) ...[
            SizedBox(width: AppSize.gap),
            Icon(trailing, size: AppSize.text * 0.8, color: color)
          ]
        ]
      )
    );
  }
}
