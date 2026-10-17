# Module: supply chain section

**Path** `lib/screens/home/sections/supply_chain`
**Role** Products made of others (backend `docs/guides/cocina-frontend.md`): recipes, the 86, batches, lost
dishes, presentations, modifier groups and the kitchen's reports. Cloud only. Content of the `supply_chain` home section.
**Services** `lib/services/kitchen` — `KitchenProductsService`, `ModifiersService`, `KitchenReportsService`: created
and provided by `_supply_chain.dart`; `RecipeService` per opened product panel.
**Modals** `lib/screens/modals/supply_chain` (`recipe produce_batch discard_dish presentations modifier_group shared`).

## Routing

- `/home/supply_chain` opens `SupplyChainTab.opening`. One route per tab: `/home/supply_chain/<key>`,
  `routeKey = "supply_chain_<key>"`, `parents: ["supply_chain"]`. Areas `supply_chain.<key>` (`docs/app-areas.json`;
  backend `areas.js` maps them to `kitchen.*`, `inventory.presentations`).

## Invariants

- Supplies and products never share a section (`cocina-frontend.md` §2.1): this one lists `supplies` tables only, the inventory
  `catalog` ones; a dish's recipe opens from its inventory row (`SummaryProductRow`).
- The backend lists no recipes: the recipes tab is a table's stock summary, and `POST /recipes/availability` over each
  page's ids is what marks a product as having one (absent = no recipe).
- `stock/changed` with `composite: true` moves only a dish's `available`, never a shelf (`StockChangedModel.composite`).

## Files

- `_supply_chain.dart` — `SupplyChainSection`: the three services, `SectionTabs` + active tab body (`NoPermissionSection` / `UnavailableSection`).
- `supply_chain_tab.dart` — `enum SupplyChainTab { recipes, modifiers, reports }`: `key icon routeKey path area`, `shown`, `opening`, `build`.
- `kitchen_format.dart` — `kitchenQty` (≤ 6 decimals, unit), `kitchenMoney` (company currency), `kitchenPercent`, `kitchenDay`, `kitchenParse`, `kitchenField`. **Every figure of the section and its panels goes through it.**

### recipes/
- `_recipes.dart` — `RecipesTab` (titled «Supplies»; the key stays the permission area's): supplies table selector (inventory's `TableSelector`) + cells switch + search + create (`CreateTableModal(supplies: true)`), the list or the sheet (inventory's `TableViewSection`, where supplies are written; a table with no rows opens on it), more; none → «Create supplies table»; a row opens `showRecipePanel`, then remeasures it.
- `recipe_row.dart` — `RecipeRow` (name, mode tag, 86 tag, what it makes now or its stock), `recipeAvailabilityLine` («3 left — because of the bacon»), `RecipeTag`.

### modifiers/
- `_modifiers.dart` — `ModifiersTab`: groups in order, create (`supply_chain.modifiers.edit`), a row opens `showModifierGroupForm` and writes its draft.
- `modifier_row.dart` — `ModifierRow`, `modifierRule` («Choose one», «Up to 3»).

### reports/
- `_reports.dart` — `ReportsTab`: report chips, window (day/month/year, both ends optional), body by status.
- `report_table.dart` — `ReportColumn`, `ReportHeader`, `ReportRow` (unfolds `details`), `ReportDetail`.
- `consumption_report.dart` — `ConsumptionReportView`: supplies (→ dishes), then batches.
- `variance_report.dart` — `VarianceReportView`: largest first; `counted: false` greyed «No count in the period», never «0 %».
- `cost_report.dart` — `CostReportView`: cost per dish, «Incomplete cost» and the line without price.
