import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';

// WIDGETS
import 'package:core/form.dart';

import 'item_line.dart';

/// **Everything on one sale**, in a panel of its own.
///
/// The lines used to be a block of the sale's detail, and they are not a block:
/// a ticket has one line or it has three hundred, and three hundred of them
/// under the money pushed the handover, the holds and where the sale came from
/// off the bottom of a panel that is read top to bottom. So the detail keeps
/// the **summary** —how many lines, and the ones worth stopping on— and this is
/// what opens from it.
///
/// **It stacks on the sale rather than replacing it.** That is what core's side
/// panels do (`showSideModal`): the sale slides right until a tab of it shows
/// at the edge, this opens to its left, and closing comes back to it. The rule
/// the handover form follows —one panel at a time— is about a *form*: what a
/// person does from the moment it opens is fill it in, and the sale behind it
/// is in the way. This is the opposite, a reading of the sale that is open, and
/// the way back is the point.
///
/// **The list is lazy and the search is local.** The lines came with the detail
/// in one read, so nothing is asked for again — and a `ListView.builder` builds
/// the dozen rows that are on screen and not the three hundred that are not,
/// which is the whole reason this is not a `Column` in a scroll.
///
/// It returns nothing: there is no action on a line, and what a person can do
/// to the sale is on the card of the panel underneath.
Future<void> showSaleItems(
  BuildContext context, {
  required SaleDetailModel sale
}) async {
  final width = math.min(_panelWidth, MediaQuery.of(context).size.width * .55);

  await showSideModal(
    context: context,
    title: S.of(context).sales_detail_items,
    minWidth: width,
    maxWidth: width,
    builder: (context) => SaleItemsModal(sale: sale)
  );
}

/// The same width the sale's own panel opens at: it lands on top of it, and two
/// stacked panels of different widths read as one having been resized.
double get _panelWidth => AppSize.action * 9 + AppSize.padding * 2;

/// The lines of one sale, searchable.
class SaleItemsModal extends StatefulWidget {
  const SaleItemsModal({super.key, required this.sale});

  /// The sale as it was read. **Nothing here reads anything**: the lines
  /// travelled with the detail, and asking for them again would be a second
  /// measurement of a sale that keeps moving — the two panels would then
  /// disagree about what is on it while both are on screen.
  final SaleDetailModel sale;

  @override
  State<SaleItemsModal> createState() => _SaleItemsModalState();
}

class _SaleItemsModalState extends State<SaleItemsModal> {
  final _form = FormController();

  late final _search = InputController.search(form: _form);

  /// What was typed, trimmed and lowered. Empty is the whole list.
  ///
  /// It is a [ValueNotifier] and not screen state so that typing rebuilds the
  /// list alone and not the field being typed into — the same arrangement the
  /// import panel uses, and it matters more here: the list is the expensive
  /// half.
  final _query = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();

    // The text is listened to and not `onSearch`: that one waits for typing to
    // stop because it is meant for a query that travels, and there is nothing
    // to ask for here — the lines are already in memory.
    _search.textController.addListener(_write);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_write);
    _form.dispose();
    _query.dispose();

    super.dispose();
  }

  void _write() => _query.value = _search.text.trim().toLowerCase();

  /// The two things a line is looked up by when somebody has the box in their
  /// hand: what it is called and the code printed on it.
  List<SaleItemModel> _matches(String query) {
    if (query.isEmpty) return widget.sale.items;

    return widget.sale.items.where((item) =>
      item.name.toLowerCase().contains(query) ||
      item.sku.toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Only where there is enough to look through. On a three-line ticket the
      // box is one more thing to read past to reach the three lines.
      if (widget.sale.items.length > _searchable) ...[
        SearchInput(
          controller: _search,
          placeholder: S.of(context).sales_detail_items_search,
          radius: AppSize.cornerInset(AppSize.gap),
          // The filtering runs on every key through `_write`; Enter has no
          // reason to do nothing.
          onSearch: (_) => _write()
        ),
        SizedBox(height: AppSize.spaceS)
      ],
      Expanded(child: ValueListenableBuilder<String>(
        valueListenable: _query,
        builder: (context, query, _) => _list(context, query)
      ))
    ]
  );

  Widget _list(BuildContext context, String query) {
    final scheme = ThemeColor.of(context);
    final items = _matches(query);

    if (items.isEmpty) {
      return Center(child: TextSmall(
        widget.sale.items.isEmpty
          ? S.of(context).sales_detail_items_empty
          : S.of(context).sales_detail_items_no_match,
        lines: 3,
        color: scheme.text.secondary
      ));
    }

    return ListView.builder(
      // The side panel leaves its own bottom padding out so scrolled content
      // reaches the edge, so the list puts it back.
      padding: EdgeInsets.only(bottom: AppSize.padding),
      itemCount: items.length,
      // The count is the point of this panel: a ticket of three hundred lines
      // builds the dozen that are on screen. The separator is drawn by the row
      // above itself rather than with `ListView.separated`, which would build
      // the same rows and a builder per gap.
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (index > 0) Separator.horizontal(
            margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
          ),
          SaleItemLine(item: items[index], currency: widget.sale.currency)
        ]
      )
    );
  }

  /// How many lines a sale has to carry before the search is worth its row.
  static const int _searchable = 8;
}
