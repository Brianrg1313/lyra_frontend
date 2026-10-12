import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

/// The state of the records reading and of the search, top right.
///
/// It goes on top and not below the sheet because the sheet never ends: it
/// keeps going as you scroll down, so there is no end to rest a bar on. And
/// while typing it is convenient that what is on top does not move, which the
/// bottom edge cannot promise.
///
/// There is no save button here: written rows save themselves on leaving them
/// (see `SheetController`), so there is nothing pending left to gather in a
/// button.
///
/// It is the only thing on the screen that listens to the coming and going of
/// the reading: the chunks that enter and leave move this spinner, not the
/// grid.
class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // The spinner covers the two waits that do not cover the sheet: a chunk of
    // records entering and a re-read of the structure (a column change). The
    // second matters since the screen stopped unmounting to re-read it: without
    // this, the only notice that the change travels would be that cell's dimmed
    // title.
    final (loading, failed) = context.select<TableViewService, (bool, bool)>(
      (service) => (
        service.isLoadingRows || service.isReloading,
        service.status == TableViewStatus.error
      )
    );

    // How many rows match what was searched, or `null` if nothing is being
    // searched. It is the only thing that says the sheet is filtered: without
    // this, a thousand-row table showing three would be read as a three-row
    // table.
    final matches = context.select<TableViewService, int?>(
      (service) => service.isSearching ? service.records : null
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // While the chunk travels nothing is said: until it arrives the count is
        // zero, and announcing that there are no results only to show them
        // later is worse than saying nothing. The spinner next to it already
        // explains the wait.
        if (matches != null && !loading) ...[
          TextSmall(
            S.of(context).product_table_view_search_count(matches),
            color: scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap)
        ],
        if (loading) ...[
          SizedBox(
            width: AppSize.text,
            height: AppSize.text,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.spaceS)
        ],
        if (failed) ...[
          TextSmall(
            S.of(context).product_table_view_error_title,
            color: scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap),
          _ActionButton(
            icon: Icons.refresh,
            message: S.of(context).product_tables_retry,
            action: context.read<TableViewService>().retry
          ),
          SizedBox(width: AppSize.spaceS)
        ]
      ]
    );
  }
}

/// Icon button of the top bar. Dimmed (gray, no action) when [action] is null.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;
  final String message;
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      width: AppSize.button,
      height: AppSize.button,
      color: scheme.surfaceOver,
      message: message,
      child: Center(child: Icon(
        icon,
        color: action == null ? scheme.text.secondary : scheme.text.primary
      ))
    );
  }
}
