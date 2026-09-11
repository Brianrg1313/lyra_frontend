import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/pos/pos_catalog_service.dart';
import 'package:app/services/pos/pos_service.dart';

// WIDGETS
import './category_bar.dart';
import './catalog.dart';

/// Central panel of POS mode —section 3—: the product picker, and the only one
/// of the three that grows with the window.
///
/// It is split the same way as the left panel and for the same reason: the
/// strip of categories ([PosCategoryBar]) takes the fixed height of its two
/// rows and the catalog ([PosCatalog]) keeps the rest, as two surfaces rather
/// than one divided by a line, so picking a category repaints the grid and not
/// the strip.
///
/// **The strip and the grid are joined through the service and not through this
/// panel.** Picking a chip is a new read of the catalog ([PosCatalogService.filter]),
/// so which one is marked is read back from there: holding it here as well
/// would be a second owner of the same fact, and the way a chip ends up marked
/// over a grid that is no longer filtered by it.
///
/// **With no categories there is no strip**, and the catalog is the whole
/// panel. A company whose price list has no category column —which is most of
/// them— would otherwise get a bar with nothing to pick in it, eating the
/// height the products are worth.
class PosCenterPanel extends StatelessWidget {
  const PosCenterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<PosService>().categories;

    // Only the chosen category, and not the whole catalog service: the grid
    // reads a page every time the scroll asks for one, and the strip has
    // nothing to repaint for any of them.
    final selected = context.select<PosCatalogService, String?>(
      (catalog) => catalog.category
    );

    return Column(children: [
      if (categories.isNotEmpty) ...[
        SizedBox(
          width: double.infinity,
          child: PosCategoryBar(
            categories: categories,
            selected: selected,
            onCategory: context.read<PosCatalogService>().filter
          )),
        SizedBox(height: AppSize.gap)
      ],
      const Expanded(child: Surface(child: PosCatalog()))
    ]);
  }
}
