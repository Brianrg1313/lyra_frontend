# Task: the kitchen's reports in the reports section

Opened 2026-10-20. Open.

## Why

The kitchen's three reports were a tab of the supply chain section. That section was merged into the
inventory (supplies are a kind of inventory table, `cocina-frontend.md` §2) and its reports tab was
removed rather than moved: they belong in the reports section (`HomeSection.report`, `/home/report`,
still a placeholder), which is meant for longer and more complete reports than a tab could hold.

## What exists

**Backend, unchanged and live** (`E:/andromeda/backend/projects/lyra/docs/guides/cocina-frontend.md` §9):
`POST /lyra/v1/inventory/recipes/consumption` (with `branch_id`), `/variance` (with `branch_id`), `/cost`
(the whole company), each `{ FROM?, TO? }` in ISO 8601, permission `kitchen.reports`.

**App, kept** (the menu's cost per dish uses part of it):
- `lib/services/kitchen/kitchen_report_model.dart` — `ConsumptionReport` (+ supply, dish, batch), `VarianceRow`
  (`counted` false = no count in the window, never «0 %»), `DishCost` / `DishCostLine`; parsers pinned in
  `test/kitchen_test.dart` («reports: consumption by supply and dish, variance with its count, cost incomplete…»).
- `kitchenWindowRequest` in `lib/services/kitchen/kitchen_request.dart` — whole local days in ISO 8601.

**App, removed** — recover from the frontend commit before the merge, `e9b1322`
(`git show e9b1322:<path>`):
- `lib/services/kitchen/kitchen_reports_service.dart` — `KitchenReportsService` (+ `KitchenReport`, status): one
  report and one window, only the last read counts; `invalid_field` = the window ends before it starts.
- `lib/screens/home/sections/supply_chain/reports/_reports.dart` — `ReportsTab`: report chips, window (day/month/year,
  both ends optional), body by status.
- `.../reports/report_table.dart` — `ReportColumn`, `ReportHeader`, `ReportRow` (unfolds `details`), `ReportDetail`.
- `.../reports/consumption_report.dart` — supplies (→ the dishes that spent them), then batches.
- `.../reports/variance_report.dart` — largest first, each with a `VarianceBar` (diverging, one scale); not counted
  greyed «No count in the period».
- `.../reports/cost_report.dart` — cost per dish, «Incomplete cost», the line without a price.
- Strings `supply_chain_reports_*` and `supply_chain_cost_empty_note` in `lib/l10n/intl_en.arb` (the prefix is
  `kitchen_` today: rename them when restoring).
- `test/supply_chain_screens_test.dart` — «variance is drawn both ways, and a supply with no count is not a 0 %».

## To do

1. Design the reports section (its tabs or report list) and where the kitchen's three go in it.
2. Give them an area in `docs/app-areas.json` under `report` (cloud only, `CapabilityService.modes`) and its line in
   the backend's `lib/models/permissions/areas.js` → `kitchen.reports`, then `pnpm permissions:export` into
   `lyra_protocol` (its `permissions.dart` and the fixture).
3. Restore the service and the views from `e9b1322` under the reports section, with their strings and the test.
4. Variance is read from one count to the next: keep the note that tells the person to count at the close and open
   it from the previous count's day.
