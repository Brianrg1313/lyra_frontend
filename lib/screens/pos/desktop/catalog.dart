import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/pos/pos_catalog_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

import './pos_currency.dart';
import './product_tile.dart';

/// The catalog: the bottom half of section 3 and the part that keeps whatever
/// space is left over, because it is the only one of the panel that shows more
/// as the window grows.
///
/// Its search box sits above the grid and not in the category strip: what is
/// typed searches products, which is what the grid holds, and a filter reads
/// where what it filters begins.
///
/// **Both filters are the same read.** What is typed here travels as `SEARCH`
/// and the chip picked in the strip as `CATEGORY`, and they AND together on the
/// backend (see [PosCatalogService]). Neither is applied in memory: the grid
/// holds one page of a catalog that can run to tens of thousands of rows, so
/// filtering what came down would search the page and not the catalog.
///
/// **The grid loads as it is scrolled.** There are no pages or buttons: the
/// first one is read when the counter opens and the next is asked for while the
/// end of the current one is being drawn, which is what [_lookahead] measures.
class PosCatalog extends StatefulWidget {
  const PosCatalog({super.key});

  /// Width a product tile aims for. It is a maximum, not a fixed size: the grid
  /// fits as many columns as the panel allows and stretches them to fill the
  /// row, so the tiles never leave a gutter of dead space on the right.
  static const double tileExtent = 160;

  /// Height a tile takes for its width. Clearly taller than wide, and not by
  /// eye: under the picture go up to two lines of name, the price and the
  /// units, and the picture is what keeps whatever they do not use. A squarer
  /// tile leaves that text with the whole height and the photo —which is what
  /// a product is recognized by— as a strip.
  static const double tileRatio = 0.65;

  /// How many tiles before the end the next page is asked for. Enough for it to
  /// arrive while the scroll is still moving, without requesting it on the
  /// first row.
  static const int _lookahead = 8;

  @override
  State<PosCatalog> createState() => _PosCatalogState();
}

class _PosCatalogState extends State<PosCatalog> {
  /// The search box is mounted for as long as the panel is —it is never opened
  /// and closed like the channels one—, so it is left with the form
  /// `InputController.search()` creates for itself and [SearchInput] disposes
  /// both when the panel goes away.
  final _search = InputController.search();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PosCatalogService>();

    return Padding(
      padding: EdgeInsets.all(AppSize.gap),
      child: Column(children: [
        SizedBox(
          width: 300,
          child: SearchInput(
            controller: _search,
            radius: AppSize.cornerInset(AppSize.gap),
            placeholder: S.of(context).pos_search_product,
            // [SearchInput] already waits until typing stops, so what arrives
            // here is a finished query and goes straight to the read: the
            // service drops it if it is the same one already being shown.
            onSearch: service.search
          ),
        ),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.padding),
        ),
        Expanded(child: _body(context, service))
      ])
    );
  }

  /// What is seen under the search box, depending on how the read came out.
  Widget _body(BuildContext context, PosCatalogService service) =>
    switch (service.status) {
      PosCatalogStatus.idle || PosCatalogStatus.loading =>
        const Center(child: Loading()),
      PosCatalogStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).pos_catalog_error_title,
        subtitle: S.of(context).pos_catalog_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).pos_catalog_retry
      ),
      // The company has not imported anything yet, so there is nothing to sell
      // and nothing to retry either: it is fixed in the inventory section, and
      // this counter has no way to get there.
      PosCatalogStatus.missing => SectionMessage(
        icon: CI.shop,
        title: S.of(context).pos_catalog_missing_title,
        subtitle: S.of(context).pos_catalog_missing_subtitle
      ),
      PosCatalogStatus.empty => SectionMessage(
        icon: service.isSearching ? CI.search : CI.shop,
        // A filter that matched nothing and a catalog with nothing in it are
        // two different answers, and the second one is the only one that has
        // anything to suggest: emptying a filter is done in the strip above.
        title: service.isSearching || service.isFiltering
          ? S.of(context).pos_catalog_search_empty
          : S.of(context).pos_catalog_empty_title,
        subtitle: service.isSearching || service.isFiltering
          ? null
          : S.of(context).pos_catalog_empty_subtitle
      ),
      PosCatalogStatus.ready => _Grid(service: service)
    };
}

/// The products themselves, and at the end of them whatever the next page is
/// doing.
///
/// It is a scroll of two slivers and not a [GridView] because the grid has a
/// tail: while the next page comes down it says so, and if it did not arrive it
/// offers to ask again. A grid with a footer under it in a [Column] would leave
/// that tail pinned to the panel instead of at the end of the products.
class _Grid extends StatelessWidget {
  const _Grid({required this.service});

  final PosCatalogService service;

  @override
  Widget build(BuildContext context) {
    final currency = posCurrency(context);
    final products = service.products;

    return CustomScrollView(slivers: [
      SliverGrid.builder(
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: PosCatalog.tileExtent,
          mainAxisSpacing: AppSize.gap,
          crossAxisSpacing: AppSize.gap,
          childAspectRatio: PosCatalog.tileRatio
        ),
        itemBuilder: (context, index) {
          // The next page is asked for while the end of the current one is
          // drawn. The service makes sure asking too often does nothing.
          if (index >= products.length - PosCatalog._lookahead) service.more();

          return PosProductTile(
            product: products[index],
            currency: currency
          );
        }
      ),
      SliverToBoxAdapter(child: _Footer(service: service))
    ]);
  }
}

/// The end of the grid: what is happening with the next page.
///
/// While one comes down you see it coming, and if it did not arrive retrying is
/// offered. With everything read it takes up nothing: a catalog that already
/// ended does not have to say so.
class _Footer extends StatelessWidget {
  const _Footer({required this.service});

  final PosCatalogService service;

  @override
  Widget build(BuildContext context) {
    if (service.moreFailed) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
        child: Center(child: SizedBox(
          width: AppSize.action * 4,
          child: Button(
            title: S.of(context).pos_catalog_retry,
            action: service.retryMore
          )
        ))
      );
    }

    if (!service.hasMore) return SizedBox(height: AppSize.spaceS);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceS),
      child: const Center(child: Loading())
    );
  }
}
