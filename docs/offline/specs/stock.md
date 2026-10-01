# Spec: stock (ledger, movements, holds, summary)

**Plan** §8.3 (stock), §8.4, §9.3. **App today** `stock/movements/*`, `stock/summary/*`,
`pos/pos_invoice_service.dart` (holds), `pos/pos_product_model.dart`.

Stock is a **ledger**: movements are the truth, balances are a projection of them. Nothing ever
writes a balance directly. That is also what makes hybrid sync conflict-free (plan §9.3:
counters are never synced as values).

---

## stock.balance

For every product (a record of the primary table, or of any table with a `STOCK` field):

| Counter | Meaning |
|---|---|
| `onHand` | units physically on the shelf, held ones included |
| `reserved` | units promised to someone (a POS ticket line, a manual reservation) |
| `available` | `onHand − reserved`: units left to sell. What the POS and the `STOCK` cell show. |
| `returns` | units a customer returned, waiting for a decision. **Not** part of `onHand`. |

### Rules

- **ST-1** A product is **tracked** when its table has a `STOCK` field. An untracked product
  has no balance: the POS sells it **without holds** and never refuses it for stock, and the
  ledger answers `null` counters for it (not zeros). (Decided 2026-09-30: the POS is the point
  of sale in person, so the product leaves at the counter with no reservation step.)
- **ST-2** A tracked product the ledger has never moved reads `0` everywhere (`PosProduct.stock`:
  "a product the ledger has never been told about reads 0").
- **ST-3** Balances are recomputed from movements inside the same transaction as the movement,
  and stored as a projection for reading. A maintenance action ("rebuild stock") recomputes all
  of them from the movements and reports any difference.

---

## stock.movement

### Data

`movement { id, productId, tableId, operation, reason, quantity, note, actor, device, source,
at, commandId }`.

`source` says what caused it: `manual`, `pos` (with `invoiceId`), `import`, `outbox` (replayed
from a POS outbox), `sync` (hybrid). `productName` and `sku` are frozen on the movement, so the
history keeps reading after a product is renamed or deleted.

### Operations and reasons

| Operation | Counters | Reasons (`StockReason`) |
|---|---|---|
| `add` | `onHand +n` | `restock`, `return` (approved), `correction` |
| `remove` | `onHand −n` | `sale`, `damage`, `loss`, `expiration`, `theft`, `correction` |
| `reserve` | `reserved +n` | none (a manual reservation is just that) |
| `unreserve` | `reserved −n` | `reintegration`, `expiration`, `cancelled` |
| `return` | `returns +n` | `customer`, `defective`, `wrong_item`, `warranty` |

A returned unit leaves `returns` through an `add` with reason `return` (back on the shelf) or a
`remove` with reason `damage` / `correction` (discarded); both also take `returns −n`, in the same movement.

### Rules

- **ST-10** `quantity` is a positive integer ≤ 1 000 000. The operation gives the sign.
- **ST-11** A reason must belong to its operation (`invalid_reason`). Several reasons share a
  code across operations (`correction`, `expiration`): the pair (operation, reason) is what is
  checked, never the code alone.
- **ST-12** When the reason is omitted, the engine sets the operation's default: `add` →
  `restock`, `remove` → `correction`, `unreserve` → `reintegration`, `return` → `customer`.
- **ST-13** **Online, a movement that would make a counter negative is refused**
  (`insufficient_stock`, with the balance): `remove` and `reserve` beyond `available`,
  `unreserve` beyond `reserved`, taking more out of `returns` than it holds.
- **ST-14** **Replayed from a POS outbox, the same movement is accepted** even if a counter goes
  negative, and the product is flagged `needsReview` (plan §8.4). A sale that already happened
  at the counter can't be refused afterwards. The flag clears on the next manual `add` or
  `remove` with reason `correction` on that product.
- **ST-15** Every movement emits `stock/changed` with the balance **after** it.
- **ST-16** Movements are never edited or deleted. A mistake is fixed with another movement
  (`correction`).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `stock.move` | `inventory.move_stock` | `operation`, `tableId`, `productId`, `quantity`, `reason?`, `note?` | `StockBalance` | `not_found`, `untracked`, `invalid_reason`, `insufficient_stock` |
| `stock.history` | `inventory.view` | `productId`, `cursor?`, `size?` | `{items, cursor, more}`, newest first | `not_found` |

The five `POST /inventory/stock/{add,remove,reserve,unreserve,return}/` calls of
`StockOperation` map onto `stock.move` with `operation`.

---

## stock.hold

A hold is a reservation **attached to something**: a POS ticket line (`pos.md`) or a manual
reservation. It is what the sale detail lists as `reservations` (`SaleHoldModel`).

### Data

`hold { id, productId, tableId, sku, qty, status: active|released|consumed, owner: {kind:
invoice|manual, id}, created, expires? }`.

### Rules

- **ST-20** A POS line's hold is created, grown and shrunk by the ticket (`pos.md`). Each change
  is a `reserve` / `unreserve` movement with `source: pos`.
- **ST-21** POS holds **never expire** on their own. A ticket left open keeps its units until
  somebody charges or cancels it (`PosInvoiceService`: "giving the units back is a decision
  somebody makes").
- **ST-22** Releasing units from the stock screen (`unreserve`) takes them from **manual holds
  first**, then from POS holds, oldest first. A POS line whose hold shrinks keeps its quantity
  but its `held` drops: that is exactly the case `PosInvoiceService._onStock` detects and
  announces ("released"). The ticket is not written to.
- **ST-23** Charging a ticket turns its holds into `consumed` (`remove` / `sale` for the held
  units plus whatever was missing, `pos.md` POS-31). Cancelling turns them `released`
  (`unreserve` / `cancelled`). That `remove` (`source: pos`) also takes its units off
  `reserved`, in the same movement: the hold it consumes holds exactly that many once POS-31 has
  topped it up. A rebuild (ST-3) reads it the same way.

---

## stock.summary

The stock screen's list: one row per product of the primary table.

### Answer (`StockSummaryPage`)

`{columns, rows, page, size, total, table}`. Columns are `image`, then the table's fields with
`summary = true` in position order, then `stock`, `reserved` and `performance`.

### Rules

- **ST-30** `stock` is `available` and `reserved` is `reserved` (ST-1: `null` for untracked
  products). `performance` is always `null` (not measured, same as the cloud today).
- **ST-31** `image` is the cover image already resolved (`{id, url}`), as the app reads it.
- **ST-32** The fixed columns' `name` is `null`, so the app puts its own translated label.
- **ST-33** `match` is the README text search over the summary's text fields. Order: products
  with `needsReview` first, then by title, then by id.

### Ops

`stock.summary` · `inventory.view` · `page` (from 1), `size` (≤ 200: the app re-reads up to six
pages of 30 at once), `match?` · `StockSummaryPage`. Its rows are `{keys, values}` with the record
id first; a last `needsReview` key flags ST-14's products. A company without a primary table
answers `no_primary_table` (as the `code`; the cloud sends it as the `message`).

### Events

| Event | When | Payload |
|---|---|---|
| `stock/changed` | ST-15 | `{productId, table, onHand, reserved, available}` (`StockChangedModel`), delivered to sessions with `inventory.view` (and `pos.view` from the POS release) |

---

## Differences from cloud

- Offline replay may leave negative stock (ST-14). Online in the LAN, the rule is the same as
  the cloud's: refuse.

## Release status

The inventory release serves `stock.move`, `stock.history` and `stock.summary`, the projection,
manual holds (ST-22) and the rebuild (`Stock.rebuild`, no screen yet). The import release writes
an imported stock column as opening balances (`inventory.md` I-44): one `add` / `restock`
movement per product, `source: import`, note "import", in the records step's transaction, with no
`stock/changed` for each (that step's one `table/changed` tells about all of them). The POS release
adds the ticket holds (ST-20, ST-21, ST-23; a line's hold is the `stock_holds` row with the line's
id) and `pos.view` to `stock/changed`'s audience. ST-14 is reached only by a POS outbox replay, which
arrives with the outbox (plan phase 5). A discarded returned unit (the `remove` row above)
has no way to be told apart from a shelf removal in today's `stock.move` arguments: it waits for
open question 4.

## Open questions

1. ~~Untracked products.~~ Decided: sold without holds, never refused (ST-1).
2. ~~Returns.~~ Decided: the same movement takes the unit out of `returns` (the `return` /
   `damage` / `correction` rows above).
3. ~~Expiring manual holds.~~ Decided: no expiry. In the cloud only the holds a WhatsApp bot
   places expire (a separate service releases them), and bots don't exist offline. `expires`
   stays in the data for hybrid, where a pulled-down bot hold keeps its date.
4. Discarding a returned unit: the app has no `discard` reason and `stock.move` no way to say the
   units come out of `returns`. Today only `add` / `return` takes from `returns`.
