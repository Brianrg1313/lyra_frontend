# Module: finance section

**Path** `lib/screens/home/sections/finance`
**Role** The company's money through four tabs. Content of the `finance` home section.
**Services** `lib/services/money` — `MoneyService`, `MoneyBotService`, `MoneyPaymentsService`,
`MoneyReceivablesService`, `MoneyMethodsService`, `MoneyCatalogService`: all six created and
provided by `_finance.dart`, none app-wide.

## Routing

- `/home/finance` opens `FinanceTab.initial`. One route per tab from `FinanceTab.values`:
  `/home/finance/<key>`, `routeKey = "finance_<key>"`, `parents: ["finance"]`, `shell: Home.shell`.
- `_finance.dart` reads the tab inside a `ValueListenableBuilder` on `Navis.currentKey` (the const-section trap, see home module).
- No `:id`: every money endpoint answers for the `business_id` header; a business switch remounts the section.

## Files

- `_finance.dart` — `FinanceSection`: creates/provides the six services, `SectionTabs` + active tab body.
- `finance_tab.dart` — `enum FinanceTab { overview, payments, receivables, methods }`: `key icon routeKey path`, `initial = overview`. Add a tab here.
- `money_format.dart` — `moneyLabel`, `moneyFineLabel` (4 decimals under a cent, for bot cost),
  `moneyCount`, `moneyDateLabel`, `moneyDayLabel`. **Every figure and date of the section goes through it.**

### overview/
- `_overview.dart` — `FinanceOverviewTab`: `GET /money` (today) / `POST /money/summary`; below a
  separator the bot cost, **drawn regardless of the money half's state**.
- `range_picker.dart` — `MoneyRangePicker`: today / 7d / 30d / 12m; reports to its owner (`MoneyService` or the bot card).
- `summary_cards.dart` — `MoneySummaryCards`: received, paid, net, and **sold on credit** (apart: not income).
- `breakdown_block.dart` — `MoneyBreakdown`: by settlement kind (both directions) and by concept.
- `bot_block.dart` — `MoneyBotBlock`: `POST /money/ai` with its own picker; total + four areas
  (`unattributed` only if any) are the only figures written as money.

### payments/
- `_payments.dart` — `FinancePaymentsTab`: `POST /money/payments/search`, record
  (`showRecordPayment`), void (`showAlertModal` + `annul`); writes reread summary and receivables.
- `payment_filters.dart` — `PaymentFilters`: direction chips + concept/method/state via `showSelectMenu`. All server-side.
- `payments_table.dart` — `PaymentsTable`: `DataTableView`, date and amount frozen, not sortable; voided rows dimmed, never hidden.

### receivables/
- `_receivables.dart` — `FinanceReceivablesTab`: `POST /money/receivables`, unpaid first; collect = record panel prefilled.
- `receivables_table.dart` — `ReceivablesTable`: ticket, customer, sold / collected / outstanding.

### methods/
- `_methods.dart` — `FinanceMethodsTab`: `/money/methods` CRUD; reads rails (`GET /business/payments`) before opening the form (edit too).
- `method_card.dart` — `MoneyMethodCard`: one account, lines labelled by its rail's sheet (`fields:`), generic fallback.

## Conventions

- **Nothing is added up in this app**: every total is the backend's answer.
- **Bot cost is not an expense**: USD, measured, never added to a money figure.
- **What a payment method asks for is the backend's** (requirement sheet): a new rail needs no app release.
- Panels (`lib/screens/modals/finance`: `record_payment`, `payment_method_form`) return request
  bodies; the tab writes and decides what to reread.
- New money endpoint: model + service in `lib/services/money`. Vocabularies (`MoneyCatalogService`) are never hard-coded.
