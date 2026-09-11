# Module: finance section

**Path** `lib/screens/home/sections/finance`
**Role** The company's money: one subject seen through four tabs. Content of the `finance`
home section.
**Services** `lib/services/money` — `MoneyService`, `MoneyBotService`,
`MoneyPaymentsService`, `MoneyReceivablesService`, `MoneyMethodsService`,
`MoneyCatalogService`. All six are created by `_finance.dart` and provided from there;
none is app-wide.

## Routing

- The section is `/home/finance`, which opens `FinanceTab.initial`.
- One route per tab, generated from `FinanceTab.values`: `/home/finance/<key>`,
  `routeKey = "finance_<key>"`. All declare `parents: ["finance"]` and `shell: Home.shell`.
- Separate routes per tab (not a `:tab` arg) because the shell learns of a screen change
  through `Navis.currentKey`.
- `_finance.dart` reads the open tab **inside a `ValueListenableBuilder` on
  `Navis.currentKey`**, not from its own `build`. The shell mounts the section as a
  `const` widget, and a `const` is canonicalized: on the rebuild that follows the
  navigation the element is handed the same instance and `Element.updateChild` returns on
  identity without rebuilding it, which left the body on the previous tab while the URL
  and the bar had already changed.
- **No `:id`, unlike a business's tabs**: every money endpoint answers for the
  `business_id` header, so what is being looked at is always the active company. Changing
  it remounts the whole section (the shell keys its content by business).

## Files

- `_finance.dart` — `FinanceSection`: creates and provides the five services, hosts the
  tab bar and the active tab body. Reads the open tab from `Navis.currentKey`.
- `finance_tab.dart` — `enum FinanceTab { overview, payments, receivables, methods }` with
  `key`, `icon`, `routeKey`, `path`, `initial = overview`. Adding a tab is adding a case
  here; the route table reads this list.
- `money_format.dart` — `moneyLabel(value, currency)`, `moneyFineLabel(value, currency)`
  (four decimals under a cent, for what the bot costs, which is billed per token),
  `moneyCount(context, n)`, `moneyDateLabel(context, at)`, `moneyDayLabel(context, at)`. **Every figure and date of
  the section goes through it**: the amount is written the way whoever charges it writes
  it (the currency catalog decides symbol, side, decimals and grouping), the dates in the
  language being read.

The tab bar is `SectionTabs` (`lib/screens/home/sections/section_tabs.dart`), shared with
the business page.

### overview/ — what came in, what went out
- `_overview.dart` — `FinanceOverviewTab`. `GET /money` for today,
  `POST /money/summary` for any other window. One scroll holds two halves: the money of
  the window, and under a separator what Lyra cost, **drawn whatever the money did** (error
  and quiet day included) because it is a separate read over a separate window.
- `range_picker.dart` — `MoneyRangePicker`: today / 7 days / 30 days / 12 months. It only
  reports to whoever owns the window, which is what rereads — `MoneyService` at the top of
  the tab, `MoneyBotService` inside the bot's card.
- `summary_cards.dart` — `MoneySummaryCards`: received, paid, net and **sold on credit**,
  which is drawn apart because it is not income — nobody has paid it yet.
- `breakdown_block.dart` — `MoneyBreakdown`: by settlement kind (two figures, both
  directions) and by concept (one figure, its direction).
- `bot_block.dart` — `MoneyBotBlock`: what Lyra costs (`POST /money/ai`), with its own
  `MoneyRangePicker` and its own window label. The total and the four areas that compose
  it; `unattributed` only when there is any. **Only those five figures are written as
  money**, bold and in `text.primary`: what an area is made of (replies, images, lookups,
  catalog, searches) is named and never priced, so the price somebody came for is not one
  of eight on the sheet. Reads `MoneyBotService`, writes nothing.

### payments/ — the history, and the two writes on it
- `_payments.dart` — `FinancePaymentsTab`: `POST /money/payments/search`, plus recording
  (`showRecordPayment`) and voiding (`showAlertModal` + `MoneyPaymentsService.annul`).
  Both writes reread the summary and the receivables: a settlement moves a ticket's debt.
- `payment_filters.dart` — `PaymentFilters`: direction chips plus concept, method and
  state dropdowns (`showSelectMenu`, so there are no select controllers to dispose of).
  **Every filter travels to the backend** — the totals are the filter's, not the page's.
- `payments_table.dart` — `PaymentsTable`: `DataTableView`, date and amount frozen at the
  ends. Not sortable on purpose (it is one page of a filter). A voided row is dimmed and
  tagged, never hidden.

### receivables/ — who still owes
- `_receivables.dart` — `FinanceReceivablesTab`: `POST /money/receivables`. Opens on the
  unpaid tickets only. Collecting opens the same record panel, with the settling concept
  and the ticket already filled in.
- `receivables_table.dart` — `ReceivablesTable`: ticket, customer, sold / collected /
  outstanding.

### methods/ — how the company gets paid
- `_methods.dart` — `FinanceMethodsTab`: `GET/POST/PUT/DELETE /money/methods`. Reads the
  rail catalog (`GET /business/payments`) before opening the form —on an edit too, since
  it carries the requirement sheets and the bank lists— and never for the list.
- `method_card.dart` — `MoneyMethodCard`: one account, with the data a customer is told,
  each line labelled as its rail labels it (`fields:`). Falls back to the four generic
  names for a rail no sheet is known for.

## Conventions

- **What the bot costs is not an expense.** No payment backs it, it is measured from the
  providers' counters, and it is in USD while the rest of the section is in the company's
  currency — so it is drawn apart, like `credit`, and is never added to a money figure.
- **Nothing is added up in this app.** Every total —the window's, the filter's, a debt's—
  is the backend's answer, and a figure computed over the rows on screen would be a
  different number from the one the question was about.
- **What a payment method asks for is the backend's answer, not this section's.** Every
  rail carries a requirement sheet (`model:/money/requirements.js`) that says which of the
  four generic columns it has, what each is called and whether it is required, plus the
  lists the closed ones are filled from (banks with their codes, document types,
  networks). The form draws itself from it and the write is refused against it, so a rail
  added or changed on the backend needs no new version of the app.
- The two panels live in `lib/screens/modals/finance` (`record_payment`,
  `payment_method_form`),
  **return a request body and write nothing**: they open on a navigator this section's
  services are not in scope of. The tab is what writes and what decides which lists to
  reread.
- New money endpoint: model + service in `lib/services/money`, and the tab reads it. The
  vocabularies (`MoneyCatalogService`) are never hard-coded here — a concept or a
  settlement kind added on the backend must show up without a new version of the app.
