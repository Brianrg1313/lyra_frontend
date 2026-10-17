import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/kitchen/kitchen_units.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/toolkit/lan_image.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';

/// One made product as a menu shows it, for people who recognize a dish by its photo before its
/// name: the photo on top with how many can be sold now stamped on it (a colour and its words,
/// never the colour alone), then its name, what it is made of and its price
/// (`cocina-frontend.md` §3: what is left and the ingredients, never a stock to write).
///
/// A product nobody can sell has its photo greyed, so a sold-out dish is spotted across the
/// grid without reading. A tap opens its form; [onKitchen], when given, its kitchen page (the
/// 86, batches, lost dishes), as a labelled button: an icon alone is not read by everyone.
class MadeProductCard extends StatelessWidget {
  const MadeProductCard({
    super.key,
    required this.product,
    required this.service,
    required this.onOpen,
    this.onKitchen
  });

  /// Width a card aims for: the grid fits as many as its width allows and stretches them.
  static const double extent = 230;

  /// Ingredients drawn before the rest fold into «+N more»: a card stays a card.
  static const int _shownLines = 3;

  final MadeProduct product;
  final MadeProductsService service;
  final void Function() onOpen;
  final void Function()? onKitchen;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final name = product.valueOf(service.fields.name);
    final price = _price(product.valueOf(service.fields.price));
    final consumes = product.consumes;
    final lines = consumes?.recipe.lines ?? const <RecipeLine>[];
    final stock = _Stock.of(context, consumes?.availability);
    final radius = AppSize.cornerInset(AppSize.spaceXS);

    return FeedbackButton(
      action: onOpen,
      radius: radius,
      color: scheme.surfaceOver,
      feedbackColor: scheme.surfaceFeedback,
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Photo(
          product: product,
          radius: radius,
          stock: stock,
          batch: consumes?.recipe.mode == RecipeMode.batch
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSize.spaceXS, AppSize.spaceS, AppSize.spaceXS, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextMedium(
              name.isEmpty ? s.made_product_unnamed : name,
              bold: true,
              lines: 2,
              ellipsis: true,
              color: name.isEmpty ? scheme.text.secondary : scheme.text.primary
            ),
            SizedBox(height: AppSize.spaceXS),
            if (lines.isEmpty)
              _RecipeMissing()
            else
              Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
                for (final line in lines.take(_shownLines)) _LineChip(line: line, unit: service.unitOf(line.productId)),
                if (lines.length > _shownLines) _Chip(child: TextSmall(
                  s.made_product_lines_more(lines.length - _shownLines),
                  multiplier: 0.9,
                  color: scheme.text.secondary
                ))
              ]),
            if (stock?.limit != null) ...[
              SizedBox(height: AppSize.spaceXS),
              TextSmall(s.made_product_runs_out(stock!.limit!), multiplier: 0.9, ellipsis: true, color: scheme.text.secondary)
            ]
          ])
        ),
        // The price sits at the card's foot in every card of a row, whatever is above it.
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSize.spaceXS, AppSize.spaceS, 0, 0),
          child: Row(children: [
            Expanded(child: price.isEmpty
              ? TextSmall(s.made_product_no_price, ellipsis: true, color: scheme.text.secondary)
              : TextMedium(price, multiplier: 1.2, bold: true, ellipsis: true)),
            if (onKitchen != null) _KitchenButton(action: onKitchen!)
          ])
        )
      ])
    );
  }

  /// In the column's currency, or the company's; what isn't an amount as it is.
  String _price(String value) {
    if (value.isEmpty) return "";

    final unit = service.fields.price?.unit ?? "";

    return CurrencyCatalogService().resolve(unit.isEmpty ? businessService.currencyCode : unit).label(value) ?? value;
  }
}

/// How sellable a product is now, as a traffic light.
enum _Level { good, few, out }

/// What the photo's stamp says: [level] colours it, [label] says it, [limit] is the supply that
/// runs out first, named only when that is worth knowing (few or none left).
class _Stock {
  const _Stock(this.level, this.label, [this.limit]);

  /// At or under it a product reads «Only N left»: a kitchen's shift sells that in minutes.
  static const double few = 5;

  final _Level level;
  final String label;
  final String? limit;

  /// `null` for a product with no recipe: nothing to count.
  static _Stock? of(BuildContext context, RecipeAvailability? made) {
    if (made == null) return null;

    final s = S.of(context);

    if (made.paused) return _Stock(_Level.out, s.supply_chain_sold_out);

    final amount = kitchenQty(context, made.available);
    final level = made.available <= 0 ? _Level.out : made.available <= few ? _Level.few : _Level.good;
    final limit = level == _Level.good || (made.limit?.name ?? "").isEmpty ? null : made.limit!.name;
    final batch = made.mode == RecipeMode.batch;

    return _Stock(level, switch (level) {
      _Level.out => batch ? s.made_product_none_ready : s.made_product_cannot_make,
      _Level.few => batch ? s.made_product_ready(amount) : s.made_product_left_few(amount),
      _Level.good => batch ? s.made_product_ready(amount) : s.made_product_left(amount)
    }, limit);
  }

  Color color(SchemeColor scheme) => switch (level) {
    _Level.good => scheme.chart.good,
    _Level.few => scheme.chart.warning,
    _Level.out => scheme.chart.critical
  };
}

/// The product's thumbnail, or the box with the product glyph, so every card's photo lines up;
/// greyed when [stock] says none can be sold. The stamps sit on the photo, where the eye is.
class _Photo extends StatelessWidget {
  const _Photo({required this.product, required this.radius, required this.stock, required this.batch});

  final MadeProduct product;
  final double radius;
  final _Stock? stock;
  final bool batch;

  /// Luminance weights: a sold-out photo keeps its shapes and loses its appetite.
  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.6, 0
  ]);

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final cover = product.cover;
    final empty = Center(child: Icon(CI.product, size: AppSize.text * 2, color: scheme.text.secondary));
    final out = stock?.level == _Level.out;
    final inset = AppSize.spaceXS;

    final picture = cover == null ? empty : Image(
      image: mediaImage(cover.thumbnail),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => empty
    );

    return AspectRatio(aspectRatio: 4 / 3, child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(fit: StackFit.expand, children: [
        ColoredBox(color: scheme.surface, child: out ? ColorFiltered(colorFilter: _grey, child: picture) : picture),
        if (batch) Positioned(top: inset, left: inset, child: _Stamp(text: S.of(context).supply_chain_mode_batch)),
        if (stock != null) Positioned(left: inset, bottom: inset, right: inset, child: Align(
          alignment: Alignment.centerLeft,
          child: _Stamp(text: stock!.label, color: stock!.color(scheme), filled: out)
        ))
      ])
    ));
  }
}

/// A word pinned on the photo, on its own plate so it reads over any picture. With [color], a dot
/// of it before the words; [filled] paints the whole plate in it (none left: the loudest state).
class _Stamp extends StatelessWidget {
  const _Stamp({required this.text, this.color, this.filled = false});

  final String text;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final dot = AppSize.text * 0.55;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.5, vertical: AppSize.gap * 0.75),
      decoration: BoxDecoration(
        color: filled ? color : scheme.surfaceOver,
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (color != null && !filled) ...[
          Container(width: dot, height: dot, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: AppSize.gap)
        ],
        Flexible(child: TextSmall(
          text,
          multiplier: 0.9,
          bold: true,
          ellipsis: true,
          color: filled ? scheme.snackBar.text : scheme.text.primary
        ))
      ])
    );
  }
}

/// A product with no recipe yet: what to do about it, in the accent, where the ingredients go.
class _RecipeMissing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = ThemeColor.of(context).accent;

    return Row(children: [
      Icon(CI.plus, size: AppSize.text * 0.9, color: accent),
      SizedBox(width: AppSize.gap),
      Flexible(child: TextSmall(S.of(context).made_product_recipe_missing, ellipsis: true, color: accent))
    ]);
  }
}

/// The plate an ingredient (or the «+N more») sits on.
class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.5, vertical: AppSize.gap / 2),
    decoration: BoxDecoration(
      color: ThemeColor.of(context).surface,
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: child
  );
}

/// One thing a product consumes, in the unit it reads best in (0.3 kg of meat is 300 g).
class _LineChip extends StatelessWidget {
  const _LineChip({required this.line, required this.unit});

  final RecipeLine line;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final best = kitchenBestUnit(line.qty, unit);
    final qty = best.unit.symbol.isEmpty
      ? S.of(context).made_product_line_times(kitchenQty(context, best.qty))
      : kitchenQty(context, best.qty, unit: best.unit.symbol);

    return _Chip(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(child: TextSmall(line.name.isEmpty ? line.productId : line.name, multiplier: 0.9, ellipsis: true)),
      SizedBox(width: AppSize.gap),
      TextSmall(qty, multiplier: 0.9, bold: true, color: line.negotiable ? scheme.text.secondary : null)
    ]));
  }
}

/// The kitchen page, named in words beside its icon; its message says what is in it.
class _KitchenButton extends StatelessWidget {
  const _KitchenButton({required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return FocusableWidget(
      action: action,
      message: s.made_product_kitchen,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(CI.fire_sqaure, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          TextSmall(s.made_product_kitchen_short, multiplier: 0.9)
        ])
      )
    );
  }
}
