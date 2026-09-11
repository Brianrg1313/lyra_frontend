import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_product_model.dart';

/// One product of the catalog grid.
///
/// It is read top to bottom the way somebody looks for something on a shelf:
/// the picture, which is what a product is recognized by; what it is called;
/// and what it costs, which is the reason the tile is being looked at.
///
/// **Tapping it puts the product on the ticket**, and tapping it again adds a
/// unit rather than a second line — the same thing scanned twice is one line of
/// two. That is the whole gesture of the counter, so the tile is the button and
/// not something inside it: at this size an add button would be smaller than
/// the picture above it.
///
/// **Tapping it takes the units off the shelf.** The product goes on the
/// backend's invoice and its units are held right then, so from that instant no
/// other till, no stock screen and no bot is offered them — which is what keeps
/// two registers from promising the same last unit to two people.
///
/// A product **with no price cannot be rung up**: null is not zero (see
/// [PosProduct.price]), so it says so instead of putting a line on the ticket
/// that the total cannot count. One with nothing left is still tapped like any
/// other — the catalog draws sold-out products because they can still be
/// ordered — and it is the hold that refuses, with the shelf's own answer.
///
/// The three things the row can be missing are drawn and not hidden, because
/// each says something different about the catalog: a product with no picture
/// keeps the strip of photos even, one with no name travels with its code (see
/// [PosProduct.label]), and one with **no price** says so —null is not zero,
/// and a checkout has to be asked for that number instead of giving it away.
class PosProductTile extends StatelessWidget {
  const PosProductTile({
    super.key,
    required this.product,
    required this.currency
  });

  final PosProduct product;

  /// The currency the company charges with, already resolved. It comes down
  /// from the grid so every tile reads it with a single subscription.
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final radius = AppSize.cornerInset(AppSize.gap);

    return FeedbackButton(
      action: () => _add(context),
      radius: radius,
      color: scheme.surfaceOver,
      feedbackColor: scheme.surfaceFeedback,
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Picture(product: product, radius: radius)),
          SizedBox(height: AppSize.spaceXS),
          TextSmall(
            product.label.isEmpty
              ? S.of(context).pos_product_unnamed
              : product.label,
            lines: 2,
            ellipsis: true,
            // A name is written in the reading colour and the placeholder in
            // the dim one, which is what tells a product called nothing apart
            // from one whose name happens to be short.
            color: product.label.isEmpty
              ? scheme.text.secondary
              : scheme.text.primary
          ),
          SizedBox(height: AppSize.spaceXS / 2),
          _Price(price: product.price, currency: currency),
          _Stock(stock: product.stock)
        ]
      )
    );
  }

  /// Puts the product on the ticket, or says why it cannot go on one.
  ///
  /// The ticket is read and not watched: a tile that subscribed to it would
  /// repaint the whole grid on every tap of every other tile.
  ///
  /// The two refusals are different sentences because they are different
  /// problems. A product with no price is this screen's answer and it is given
  /// before anything travels — the counter has to be told a number. Everything
  /// else is the backend's: the units are not there, the invoice could not be
  /// opened, the catalog moved. Those come back already worded, so they are
  /// shown as they are rather than translated into a guess.
  Future<void> _add(BuildContext context) async {
    final ticket = context.read<PosInvoiceService>();

    if (product.price == null) {
      FloatFlag.of(context).error(
        message: S.of(context).pos_product_no_price_flag
      );

      return;
    }

    if (await ticket.add(product)) return;
    if (!context.mounted) return;

    final error = ticket.error;

    if (error != null) FloatFlag.of(context).fromError(error);
  }
}

/// The product's cover.
///
/// The thumbnail is drawn and not the photo: the backend renders a 320px one on
/// upload ([kProductImageWidth]) and a tile is narrower than that. Asking for
/// the full one would download megabytes per page to fill a small square.
///
/// Without a picture —or with one that no longer resolves— the same box is
/// drawn with the section's icon, so a page of products stays an even grid
/// instead of collapsing wherever a photo is missing.
class _Picture extends StatelessWidget {
  const _Picture({required this.product, required this.radius});

  final PosProduct product;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final cover = product.image;

    return Surface(
      width: double.infinity,
      height: double.infinity,
      radius: radius,
      color: scheme.surface,
      child: cover == null
        ? _empty(scheme)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              cover.thumbnail,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stack) => _empty(scheme)
            )
          )
    );
  }

  Widget _empty(SchemeColor scheme) => Center(child: Icon(
    CI.shop,
    size: AppSize.text * 1.4,
    color: scheme.text.secondary
  ));
}

/// What the product sells for.
///
/// A price is a number **in a currency** and the currency is not in the datum:
/// it is the one the company charges with, resolved once by the grid. It is
/// written whole —symbol included, on the side that currency uses— because a
/// tile is one line and there is no column of numbers to line it up against.
///
/// **A product with no price says so** instead of showing nothing or a zero:
/// the table has no price column, or the row is empty, and either way the
/// number has to be asked for before the sale is rung up.
class _Price extends StatelessWidget {
  const _Price({required this.price, required this.currency});

  final double? price;
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    if (price == null) {
      return TextSmall(
        S.of(context).pos_product_no_price,
        ellipsis: true,
        color: scheme.text.secondary
      );
    }

    // It is the heaviest line of the tile —[TextMedium] and bold— because it
    // is the number the tile is being looked at for. The name above it is
    // what is scanned; this is what is read.
    return TextMedium(
      currency.label("$price") ?? "$price",
      multiplier: 0.9,
      bold: true,
      ellipsis: true,
      color: scheme.text.primary
    );
  }
}

/// How many units are left of the product.
///
/// It closes the tile because it is the second question at a counter —it costs
/// this, and is there any— and it is the ledger's figure, not the stock column
/// a file happened to carry.
///
/// Nothing left is painted in the error colour and the product is still drawn:
/// it remains in the catalog and can still be ordered, so hiding it would only
/// make whoever is attending look for it.
class _Stock extends StatelessWidget {
  const _Stock({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return TextSmall(
      S.of(context).pos_product_stock(stock),
      multiplier: 0.85,
      ellipsis: true,
      color: stock <= 0 ? scheme.snackBar.error : scheme.text.secondary
    );
  }
}
