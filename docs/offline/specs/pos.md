# Spec: pos (catalogue, ticket, checkout, outbox)

**Plan** §8.3 (POS ticket, numbering), §8.4 (outbox), principle 6. **App today** `pos/*`,
`screens/pos`, `docs/app-areas.json` (`pos.*`).

The ticket is a **document from its first line**, not a list in memory: its lines hold stock, it
has a code before anything is paid, and it survives a reload, another till and a closed window.
Every figure on it is computed by the master. Those rules hold offline exactly as they do in the
cloud; this spec writes them down.

---

## pos.catalog

What the counter draws: the primary table's records, read **by field type**, not by column.

### Rules

- **POS-1** A product's fields come from the primary table (`inventory.md`, I-3):
  `name` = first `TITLE` field; `sku` = first `SKU`; `barcode` = first `BARCODE`; `price` = first
  `PRICE` net of the first `DISCOUNT` (POS-7); `image` = cover of the first `IMAGE`; `categories` = every label of every `CATEGORIES`
  field; `stock`/`reserved` = the ledger (`stock.md`), `null` for untracked products (POS-6).
- **POS-2** A product whose `PRICE` cell is empty has `price: null`. It is listed (it exists) and
  it **can't be put on a ticket** (`no_price`): null is not zero.
- **POS-3** `search` matches `name`, `sku` and `barcode` (README text search). `category` is an
  exact label. Both can be combined.
- **POS-4** Cursor paging with no total (`PosCatalogPage`). Order: `name` without case or accents,
  then `id`. `size` ≤ 100.
- **POS-5** `pos.summary` answers `{mine: {sales}, categories}`: `sales` = tickets **closed
  today** (company time zone) **by the signed-in person**; `categories` = the options of the
  primary table's `CATEGORIES` fields, in field order then option order, without duplicates.

- **POS-6** An untracked product (its table has no `STOCK` field) is sold **without holds** and
  is never refused or shown as sold out for stock: the counter is the sale in person, and the
  product leaves right there (ST-1). Its tile shows no stock count.
- **POS-7** A product's price is its list price (first `PRICE`) with its own discount off (first
  `DISCOUNT`, a percent): `price = round(list × (1 − discount / 100))`, rounded once, in minor
  units. A discount outside (0, 100] is ignored (the price is the list price). Only `DISCOUNT` is
  a discount: a `PERCENTAGE` column never is. This is the one place a discounted price is
  computed, so the grid, the ticket and the sale detail can't disagree.

### Ops

| Op | Permission | Args | Answer |
|---|---|---|---|
| `pos.summary` | `pos.view` | — | `{mine: {sales}, categories}` |
| `pos.catalog` | `pos.view` | `size`, `cursor?`, `search?`, `category?` | `PosCatalogPage` (`{table, size, cursor, more, data: {keys, values}}`) |
| `pos.methods` | `pos.view` | — | `{methods: [PosPaymentMethod], channels: ["pos"]}` from the settlement vocabulary |

---

## pos.invoice (the ticket)

### Data

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | what every write addresses |
| `ticket` | string | human code, minted at opening (POS-40) |
| `status` | `open` / `closed` / `cancelled` | `open` answers `open: true` |
| `device` | deviceId | the till that opened it (what `MINE` filters by) |
| `seller` | accountId | who opened it |
| `closedBy`, `cancelledBy` | accountId? | |
| `defaultTax` | percent | the `TAX` sent at opening |
| `items` | [line] | see below |
| `units`, `held` | int | sums over lines |
| `subtotal`, `tax`, `total` | money | POS-20 |
| `taxes` | [{rate, base, amount}] | per-rate breakdown (`SaleTaxModel`) |
| `payment` | `{method, name, reference, credit}`? | set at close |
| `note` | string? | set at close |
| `currency` | ISO 4217 | the company's main currency |
| `opened`, `closed` | instant | |
| `origin` | `live` / `outbox` | POS-50 |

**Line** `{lineId, productId?, name, sku, qty, held, price, list, discount, taxRate, subtotal,
tax, total}`. `productId` is `null` on a typed-in charge. `name`, `sku`, `price`, `list` and
`discount` are **frozen** when the line is created. `list` and `discount` are `null` on a
typed-in charge, and `discount` is `null` when the product had none (POS-7).

### Rules: opening and lines

- **POS-10** An invoice is opened by `pos.invoices.open` with `tax`. The app opens it on the
  first line, never on an empty screen, and an open invoice with no lines is allowed (it is
  what a till has between opening and the answer to its first line).
- **POS-11** Adding a product: `productId` plus `add: n` (relative) or `quantity: n` (absolute).
  A product appears **at most once** per ticket: adding it again grows its line.
- **POS-12** A new product line freezes the product's current `name`, `sku`, `price`, `list` and
  `discount`. Later edits to the record don't change the line: a ticket open for twenty minutes
  charges the offer that was running when the product went on it.
- **POS-13** Tracked product: growing a line reserves the extra units **before** the line
  changes. If `available` can't cover them, the write is refused with `insufficient_stock`
  (naming the product and what is available) and nothing changes. Shrinking a line releases
  units (`unreserve` / `cancelled`). Untracked products hold nothing (ST-1).
- **POS-14** A typed-in charge: `concept` (1–80 characters) plus `price ≥ 0` plus `add: 1`. It
  never merges with another line, even with the same concept. It holds nothing.
- **POS-15** `quantity: 0`, or a relative change that reaches 0, removes the line and releases
  its hold.
- **POS-16** A line holds at most 9 999 units (`too_many_units`). The app's own guard is 999.
- **POS-17** `tax` (0–100, percent) on a line write sets that line's `taxRate`. Every write may
  carry it; the app sends it on every line and rewrites all lines when the rate changes.
- **POS-18** Only `open` invoices accept writes. A write to a closed or cancelled one answers
  `invoice_closed` / `invoice_cancelled`, and the app reads the list again (as today).

### Rules: money

- **POS-20** Per line, in minor units: `subtotal = price × qty`; `tax = round(subtotal × taxRate
  / 100)`; `total = subtotal + tax`. Per invoice: `subtotal`, `tax` and `total` are the sums of
  the lines. `taxes` groups lines by rate. (README: rounding once per line, half away from zero.)
- **POS-21** Whether catalogue prices include tax is **not decided yet** (Open question 2).
  POS-20 assumes they don't, and is revised with that decision.
- **POS-22** The client never sends a total, and no op accepts one.

### Rules: closing (checkout) and cancelling

- **POS-30** `pos.invoices.close` needs `method` from the settlement vocabulary (`unknown_method`
  otherwise, never a silent default). `reference` is optional and stored when sent: a method
  with `reference: true` tells the **app** to ask for it, as in the cloud. `note` is optional. An invoice with no lines can't be
  closed (`empty_invoice`).
- **POS-31** Before charging, every tracked line's hold is checked: a line whose `held < qty`
  (its hold was released from the stock screen, ST-22) takes the missing units again. If they
  aren't `available`, the close is refused with `insufficient_stock` naming the product, and
  nothing changes.
- **POS-32** Closing, in one transaction: the holds become `consumed`, each tracked line becomes a
  `remove` / `sale` movement for `qty`, the invoice becomes `closed` with `payment` and `closed`,
  and the answer is the closed invoice (`open: false`).
- **POS-33** Credit sales (the store's tab) are **not offered offline** for now: the settlement
  vocabulary served in `local` leaves out every kind with `credit: true`, and a close with one
  answers `unknown_method`. See `money.md`, money.receivable.
- **POS-34** Handover at close: the ticket is `immediate` / `done` (handed over at the till).
  A later `sales.fulfil` can change it (`sales.md`).
- **POS-35** `pos.invoices.cancel` releases every hold (`unreserve` / `cancelled`) and marks the
  invoice `cancelled`. **It is kept**, never deleted ("a cart somebody walked away from is a fact
  about the day"). Only `open` invoices can be cancelled.
- **POS-36** Closing or cancelling a ticket opened on **another** device is allowed (the app
  handles "charged/cancelled somewhere else"), with the same permissions.

### Rules: codes

- **POS-40** The ticket code is `<deviceCode>-<n>`: the device's short code (`session.md`,
  devices) and a per-device counter starting at 1, zero-padded to 6 (`B-000153`). It is minted
  at opening, never changes and is never reused. Two devices never collide, even while one of
  them works offline (plan §8.3). It is an **internal reference, never a fiscal number**
  (principle 6).
- **POS-41** Codes are looked up without case (`b-000153` finds `B-000153`).

### Rules: reading

- **POS-45** `pos.invoices.list` lists **open** invoices. `mine: true` limits it to the calling
  device (not the person): that is how a till gets its ticket back after a reload without sending
  any id. Order: oldest first (`recover()` takes the first). `size` ≤ 100.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `pos.invoices.open` | `pos.sell` | `tax?` | invoice | — |
| `pos.invoices.line` | `pos.sell`; with `concept`: `pos.custom_amount`; with `tax` changing a rate: `pos.set_tax` | `id`, one of (`productId` \| `lineId` \| `concept`+`price`), one of (`add` \| `quantity`), `tax?` | `{invoice}` | `not_found`, `no_price`, `insufficient_stock`, `too_many_units`, `invoice_closed`, `invoice_cancelled` |
| `pos.invoices.close` | `pos.checkout` | `id`, `method`, `reference?`, `note?` | the closed invoice | `empty_invoice`, `unknown_method`, `insufficient_stock`, `invoice_closed`, `invoice_cancelled` |
| `pos.invoices.cancel` | `pos.cancel_ticket` | `id` | `{}` | `invoice_closed`, `invoice_cancelled` |
| `pos.invoices.list` | `pos.view` | `mine?`, `size?` | `{invoices: [invoice]}` | — |

### Events

Delivered to sessions with `pos.view` or `sales.view`.

| Event | When | Payload |
|---|---|---|
| `invoice/opened` | POS-10 | `{id, ticket, units, total}` |
| `invoice/updated` | any line write | `{id, ticket, units, total}` |
| `invoice/closed` | POS-32 | `{id, ticket, units, total}` |
| `invoice/cancelled` | POS-35 | `{id, ticket, units, total}` |
| `stock/changed` | every hold or sale movement | `stock.md` |
| `sale/progress` | open, close, cancel | `sales.md` |

The thin payload is deliberate: every till receives every notice, and the one holding that
ticket reads it back in full (`PosInvoiceEvent`).

---

## pos.outbox (selling while the master is unreachable, plan §8.4)

### What a POS may do offline

- **POS-50** Only a device paired as a POS, signed in, and with a catalogue snapshot younger than
  the limit may sell offline: 24 hours by default, set by the owner in the local server settings
  (`local_server`).
- **POS-51** Offline ops are **append-only and local to that device**: open a ticket, write its
  lines, close it, cancel it. Nothing else (no catalogue edits, no stock screen, no payments).
- **POS-52** Prices, names and the method list come from the snapshot. The device mints ticket
  ids (UUIDv7) and codes (POS-40) itself: codes don't collide because the series is per device.
- **POS-53** Offline tickets hold nothing (there's no ledger to hold against). The device counts
  down its **own** snapshot stock so the grid doesn't offer what it already sold, and shows the
  "offline" banner.
- **POS-54** Each finished ticket is queued as **one** outbox entry `{commandId, hlc, op:
  "pos.outbox.sale", args: {invoice with lines, payment, opened, closed, seller}}`. A ticket
  cancelled offline is queued too (it is a fact about the day) with `status: cancelled`.

### Replay

- **POS-55** When the master is reachable again, the device replays its outbox **in order**,
  one entry at a time. `commandId` makes each entry idempotent: a replay after a dropped answer
  does nothing twice.
- **POS-56** The master accepts an outbox sale **as it happened**: it creates the closed invoice
  with `origin: outbox`, the device's code and the sent prices; writes the `remove` / `sale`
  movements with `source: outbox` (they may go negative, ST-14); and records the sale time as
  the offline time (`closed`), so the day's figures land on the right day.
- **POS-57** The master refuses an entry only when it can't be trusted: device revoked, seller
  unknown, invalid signature of the entry, or a malformed body. A refused entry stays on the
  device, flagged, for an admin to resolve. It is never silently dropped.
- **POS-58** Prices that differ from the master's current ones are **kept** (the customer paid
  them). The invoice is flagged `priceDrift` in the audit log for review.
- **POS-59** While the outbox isn't empty, the device can't sign out (warning; an admin can
  override, which records the pending entries in the audit log on the next contact).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `pos.outbox.sale` | `pos.checkout` of the **seller** in the entry | outbox entry | `{invoiceId, ticket, flags}` | `device_revoked`, `unknown_seller`, `bad_entry` |
| `pos.snapshot` | `pos.view` | — | catalogue + methods + stock + version | — |

---

## Differences from cloud

- Ticket codes look different (`B-000153` instead of `K7M4-2QX9`). The app treats them as opaque
  text.
- Offline outbox sales (POS-50 to POS-59) don't exist in the cloud.
- `MINE` means "this device" identified by its certificate; the cloud identifies the terminal its
  own way. The app sends the same flag.

## Open questions

1. ~~Untracked products.~~ Decided: sold without holds (POS-6). App change in phase 4:
   `PosProduct.stock` becomes nullable, read as "not counted".
2. **Tax-inclusive or exclusive prices.** *Deferred: the product owner will research how taxes
   work and decide later.* The model says a line's `total` is "tax included", and
   `PosInvoiceService` computes `tax = subtotal × rate` on top of the sum of line totals for its
   optimistic draw. The two readings disagree. Pin the cloud's rule with a contract test and fix
   POS-20/21 and the app's optimistic getters to the same rule.
3. ~~Age of the offline catalogue snapshot.~~ Decided: a POS refuses to sell offline with a
   snapshot older than 24 hours by default; the owner can change the limit (POS-50).
4. ~~Is `reference` required?~~ Answered: no, the cloud stores it when sent and the app asks for
   it (POS-30).
