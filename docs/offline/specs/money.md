# Spec: money (summary, payments, receivables, accounts, currencies, export)

**Plan** §2 (finance rows), §6.3 (sealed fields), §8.5 (export), principle 6. **App today**
`money/*`, `screens/home/sections/finance`, `docs/app-areas.json` (`finance.*`).

The finance screen **adds nothing up**: every total is the master's answer. Two kinds of money
are kept apart and never copied into each other: what the **register** took (closed tickets,
`pos.md`) and what was **recorded by hand** (payments). A payment is never edited or deleted:
it is voided and written again.

---

## money.catalog

`money.catalog` · `finance.view` · → `{concepts: {in: [...], out: [...]}, methods: [...]}`, from
the vocabularies (`business.md`). Concepts carry `direction`, `ticket` (may name a sale) and
`settles` (pays a credit ticket down). Settlement kinds carry `reference`, `change`, `default`
and `credit`.

---

## money.payment

### Data

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `concept` | code | decides `direction` |
| `direction` | `in` / `out` | **answered, never sent** |
| `amount` | money > 0 | in the main currency (M-5) |
| `method` | settlement kind? | |
| `accountId` | money method id? | |
| `reference` | string? | |
| `counterpart` | `{name?, contact?}`? | |
| `ticket` | ticket code? | only on concepts with `ticket: true` |
| `note` | string? | |
| `date` | instant | when the money moved; default now |
| `status` | `recorded` / `voided` | |
| `voidReason`, `voidedBy`, `voidedAt` | | |
| `registeredBy` | accountId | answered as a name |
| `created` | instant | when it was typed in |

### Rules

- **M-1** `direction` comes from the concept. A request that names a direction is refused
  (`bad_request`); there is no way to contradict the concept.
- **M-2** `amount` is positive and has at most the currency's decimals (`invalid_amount`).
- **M-3** `date` may be in the past, not more than 5 minutes in the future (`future_date`).
- **M-4** `accountId` must be an active money method (`unknown_account`). With an account and no
  `method`, the method is the account's settlement kind. With both, they must agree
  (`method_mismatch`).
- **M-5** Amounts are in the company's main currency. There is no currency field and no
  conversion ("the amount is stamped from the company's pricing").
- **M-6** `ticket` is refused on a concept without `ticket: true` (`ticket_not_allowed`). When
  present it must name a closed ticket (`sale_not_found`).
- **M-7** A concept with `settles: true` **requires** a ticket (`ticket_required`) that is a credit
  sale (`not_credit`), and `amount ≤ outstanding` (`exceeds_outstanding`, answering the
  outstanding amount).
- **M-8** Voiding keeps the row, sets `status: voided`, and it stops counting everywhere. Voiding a
  settlement gives the ticket its debt back. A voided payment can't be voided again
  (`already_voided`). Voids go to the audit log.
- **M-9** Empty texts are not stored (the request builders already strip them).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `money.payments.record` | `finance.payments.record` (a `settles` concept: `finance.receivables.collect`) | `recordPaymentRequest` fields | payment | M-1…M-7 codes |
| `money.payments.void` | `finance.payments.void` | `id`, `reason?` | payment | `not_found`, `already_voided` |
| `money.payments.search` | `finance.payments.view` | `page`, `size` (≤ 100), `direction?`, `concept?`, `method?`, `status` (`all` / `recorded` / `voided`) | `MoneyPaymentsPage` | — |

- **M-10** Search order: `date` newest first, then `id`. `totals` (`in`, `out`: count and total)
  are over the **whole filter**, voided payments never included, whatever `status` lists.

---

## money.summary

### Rules

- **M-20** The window is `[from, now]`. With no `from` it is today: midnight in the company time
  zone to now. The answer carries the `from` and `to` actually used.
- **M-21** `sales` = closed, **non-credit** tickets whose `closed` is in the window: count and sum
  of `total`.
- **M-22** `payments` = recorded incoming payments whose `date` is in the window.
  `income.total = sales.total + payments.total`.
- **M-23** `expenses` = recorded outgoing payments in the window.
- **M-24** `credit` = credit tickets closed in the window: count, and the sum of what is **still
  outstanding** on them now (Open question 2). It is never part of income.
- **M-25** `net = income.total − expenses.total`.
- **M-26** `methods`: per settlement kind, `in` (sales and incoming payments through it), `out`,
  `net`, `count`. The credit kind is not listed (no money moved through it).
- **M-27** `concepts`: per concept, total and count of recorded payments in the window. Sales are
  not a concept.
- **M-28** `currency` is the main currency.

### Ops

`money.summary` · `finance.overview.view` · `from?` · `MoneySummary`. (`GET /money/` and
`POST /money/summary/` both map to it.)

---

## money.receivable

A credit ticket: sold on the store's tab, collected later by `settles` payments.

**Deferred offline (2026-09-30).** Credit is a payment option still being researched (services
such as Cashea offer it to shops). Until it is decided, `local` offers no credit settlement kind
(POS-33), so no receivable can exist: the receivables tab is **hidden in `local`** and the
summary's `credit` is always zero. The rules below stay as the target for when credit is
decided, and for hybrid, where cloud credit tickets are pulled down.

### Rules

- **M-30** Every closed ticket paid with a `credit: true` kind is a receivable.
  `collected` = sum of its recorded settlement payments; `outstanding = total − collected`
  (never below 0).
- **M-31** `open: 1` lists only `outstanding > 0`. Order: `date` newest first, then `id`.
- **M-32** `totals` over the filter: `count`, `sold`, `collected`, `outstanding`.
- **M-33** A settlement that brings `outstanding` to 0 emits `sale/progress` (the row goes from
  `owed` to `completed`, `sales.md`).

### Ops

`money.receivables` · `finance.receivables.view` · `page`, `size`, `open` · `MoneyReceivablesPage`.

---

## money.method (the company's payment accounts)

### Data

`MoneyMethod`: `id`, `code` (rail, fixed at creation), `label`, `holder`, `document`,
`institution`, `account`, `instructions`, `currency`, `fee {type, value}`, `position`, `active`.
`method` (settlement kind), `name`, `icon`, `institutionName` come from the rail catalogue.

### Rules

- **M-40** Rails come from the catalogue **for the company's country** plus the global ones
  (`money.rails`). An unknown `code` is refused (`unknown_rail`). `code` can't be changed.
- **M-41** The rail's requirement sheet (`fields`) is checked: a `required` field that is missing
  or blank is refused (`required`, naming the field); a field the sheet doesn't list is stored
  empty. `select` values must be codes of their option list (`invalid_option`).
- **M-42** `currency` must be the main currency or an exchange currency (`unknown_currency`). A
  rail with a fixed currency stores that one whatever is sent.
- **M-43** `fee`: `none`, `fixed` (an amount in the method's currency, ≥ 0), or `percent` (0–100).
  On an edit, `FEE_TYPE: none` with `FEE: null` removes it.
- **M-44** Removing is soft (`active: false`). Payments that named it keep reading its label.
- **M-45** `holder`, `document` and `account` are **sealed** (plan §6.3, scope `payments`): they
  are readable only in a session whose account holds `finance.methods.view`, and unwrapped with
  that person's password at sign in. A PIN session can't read them.
- **M-46** Fees are not applied to POS sales: POS checkout uses settlement kinds, not accounts.
  (In the cloud, fees apply to channel payments, which don't exist offline.)

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `money.methods.list` | `finance.methods.view` | — | `[MoneyMethod]` (by `position`) | — |
| `money.methods.rails` | `finance.methods.view` | — | `[MoneyRail]` with `fields`, and `options` | — |
| `money.methods.create` | `finance.methods.create` | `createMoneyMethodRequest` | method | M-40…M-43 codes |
| `money.methods.edit` | `finance.methods.edit` | `updateMoneyMethodRequest` | method | `not_found`, M-41…M-43 codes |
| `money.methods.remove` | `finance.methods.delete` | `id` | `{}` | `not_found` |

---

## money.currencies

### Rules

- **M-50** `main` is read-only (B-5).
- **M-51** An exchange currency is `{currency, mode, custom?}`. `rate` (the effective one) is
  `custom` in `custom` mode and `official` in `official` mode.
- **M-52** `official` needs a rate feed on the internet. In `local` it is always `null` (the
  screen already says "no rate"), so only `custom` rates work. In `hybrid` it is the last rate
  the cloud sent, with its `updated`; it is never discarded for being old while offline, and
  the screen shows its date.
- **M-53** A custom rate is a positive number (`invalid_rate`). Switching back to `official`
  keeps the custom figure.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `money.currencies.get` | `finance.methods.view` | — | `MoneyCurrencies` | — |
| `money.currencies.save` | `finance.methods.manage_currencies` | `saveMoneyExchangeRequest` | `MoneyCurrencies` | `unknown_currency`, `invalid_rate`, `is_main` |
| `money.currencies.remove` | `finance.methods.manage_currencies` | `currency` | `MoneyCurrencies` | `in_use` (an account uses it) |

---

## export.accounting (plan §8.5)

Lyra is not accounting software. It hands its data to the software that is.

### Rules

- **M-60** `export.accounting` takes `from`, `to` (calendar days in the company time zone,
  inclusive), `datasets` (any of `sales`, `sale_lines`, `payments`, `receivables`,
  `stock_movements`) and `format` (`csv` or `xlsx`). It answers a `fileId` to download
  (`protocol-v1.md`, files), valid for 1 hour.
- **M-61** One file per dataset (a `.zip` for CSV, one sheet each for XLSX). Column names are
  stable English snake case and documented in `lyra_node/docs/export.md` when it's built; a new
  column is only ever **added at the end**.
- **M-62** Every row carries its Lyra `id` (and the ticket code where there is one), so a
  re-export can be matched on the other side.
- **M-63** Money columns are decimal numbers with the currency's decimals and a `currency`
  column. Dates are ISO. CSV is UTF-8 with a BOM; the separator is `;` when the company
  language uses a decimal comma, else `,`.
- **M-64** Voided payments and cancelled tickets are exported **with their status**, not left
  out: the other system decides what to do with them.
- **M-65** Every export is recorded in the audit log (who, window, datasets).

### Ops

`export.accounting` · `finance.export` (new permission, plan §8.5) · M-60 · `{fileId, expires}`
· `invalid_range`, `too_large` (more than 1 000 000 rows: narrow the window).

---

## Release status

The finance release serves `money.catalog`, `money.summary`, `money.payments.*`,
`money.receivables` and `money.currencies.*` (M-1 to M-33, M-50 to M-53). On the wire:
- money is in minor units of the main currency, as on the ticket (`pos.md`; the app's
  `MoneyLanSource` converts both ways); rates are not money and travel as numbers;
- the catalogue leaves out the concepts that settle a credit ticket while credit is deferred, so
  a `settlement` asks for `finance.receivables.collect` and then always answers `ticket_required`
  or `not_credit`; the receivables answer an empty page;
- a payment names a settlement kind (`unknown_method` when it names none, as the cloud refuses);
  `accountId` answers `unknown_account` until the accounts are served;
- a search row is flat (`counterpart` read down to a name or contact, `account` a label), as the
  cloud's; `record` and `void` answer the whole payment, with `voided {at, by, reason}`;
- a custom rate is required in `custom` mode (`invalid_rate`); `money.currencies.remove` of a
  currency that isn't there is `not_found`; `in_use` arrives with the accounts.

Still to come: `money.methods.*` (needs the `payments` sealed key, plan §6.3, and the rails, banks
and document types snapshot, `business.md`), then `export.accounting`. Until then a master hides
the methods tab (and with it the currencies block) and the export.

## Differences from cloud

- No money AI (`/money/ai`). No official rate feed in `local`.
- No payment fees on POS sales (there are none in the cloud either; channel payments don't exist
  offline).
- The accounting export is new and can later be offered in the cloud too.

## Open questions

1. **Customer on credit sales.** *Deferred with credit itself* (money.receivable).
2. **`credit` in the summary.** *Deferred with credit.* Proposal kept: what is still owed on the
   credit tickets of the window (M-24). The cloud reports it apart from income for the same reason.
3. **`settles` without a ticket.** *Deferred with credit.* The cloud accepts one today and applies
   it to nothing; M-7 proposes refusing it (`ticket_required`), which the contract test will
   show as a difference to settle.
