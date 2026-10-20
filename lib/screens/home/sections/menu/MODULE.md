# Module: menu section

**Path** `lib/screens/home/sections/menu`
**Role** `made` tables (`cocina-frontend.md` §2, §3), one open at a time (`/home/menu`): what is made from the supplies and
sold (dishes, combos), each product a card and a form with what it consumes. Cloud only (area `menu`; backend `areas.js`:
`products`). The tables are the inventory's (`TablesService`): the inventory lists the `catalog` ones, the supply chain the `supplies`.
**Services** `TablesService` (`lib/services/stock`), `MadeProductsService` (`lib/services/kitchen`, per open table).
`PreferencesService`: the open table per company (`RememberedSelection.menu`).
**Modals** `modals/inventory` (`create_table made_product rename_table table_settings`) + `modals/supply_chain/recipe` (what a made product consumes, its kitchen page).

## Files

- `_menu.dart` — `MenuSection`: the `made` tables (remembered → first); the inventory's `InventoryBar` parts (`TableSelector`, `TableOptionsButton` without transfers, «New menu»: `CreateTableModal(kind: TableKind.made)`) over `MadeProductsSection`; none → `SectionMessage` offering the first.

## made_products/ — a made table

- `_made_products.dart` — `MadeProductsSection({tableId, parts})`: owns `MadeProductsService`; the bar (count, «New product» with `supply_chain.recipes.edit`), header search → `MATCH`, the products as a grid of cards (as many columns as fit `MadeProductCard.extent`, each row as tall as its tallest), the new card first when one can write, `SectionMoreButton`, empty / error states; a card opens `showMadeProduct`, its «Kitchen» button `showRecipePanel` (`supply_chain.recipes`); a right click or a long press on one (`ContextMenuRegion`) offers edit and duplicate (`supply_chain.recipes.edit`; duplicate greyed without its read recipe) and delete (`products.delete`, after `showAlertModal`).
- `made_product_card.dart` — `MadeProductCard`: its photo (greyed when none can be sold) stamped with «by the batch» and how many can be sold now as a traffic light (left / only N left / sold out; a batch's ready), name, what it consumes as chips in the unit each reads best in («Meat 300 g», «Bread ×1», the rest «+N more»; none: «Add what it is made of»), what runs out first when few or none are left, what it costs and its margin (or «Loses $X on each», red) from the page's `costs` (`kitchen.reports` only), price at the foot.
- `made_product_new_card.dart` — `MadeProductNewCard`: the grid's «New product» card.

## Invariants

- A made product is never a sheet row: its record and what it consumes are one `records/manage` call (all or nothing), so
  they are written together in its form (no cells switch, no import: `409 made_not_importable`).
