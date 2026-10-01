# Spec: sales (the board, stages, handover, detail)

**Plan** §2 (sales rows), §8.3 (sales board). **App today** `sales/*`,
`screens/home/sections/sales`, `docs/app-areas.json` (`sales.*`).

Nothing stores a list of sales. Each row is **measured when it is read** from the document that
owns it. In the cloud there are three sources (open invoice, charged ticket, chat); offline there
are two, because chats are cloud only. The one write is the **handover**: a fact nobody else can
measure (the driver left, the customer collected).

---

## sales.row

### Sources

| Source | Document | Offline |
|---|---|---|
| `invoice` | an open POS invoice (`pos.md`) | yes |
| `ticket` | a closed POS invoice (`pos.md`) | yes |
| `chat` | a purchase in a conversation | no (cloud only; in hybrid, pulled down, plan §2) |

A cancelled invoice is on neither list.

### Stages (measured)

The codes, names, sections, levels and precedence are the cloud's stages catalogue (the
vocabulary `GET /sales/stages` hands over), so a row means the same thing on both sides. The
full catalogue, in precedence order:

| Stage | Name (es) | Section | Level | Attention | Offline |
|---|---|---|---|---|---|
| `open` | Ticket abierto | process | info | yes | yes |
| `uncharged` | Sin forma de pago | process | warning | yes | no (conversations) |
| `verifying` | Pago por verificar | process | warning | yes | no (conversations) |
| `paying` | Pago pendiente | process | info | no | no (conversations) |
| `reserving` | Stock reservado | process | info | no | no (conversations) |
| `shipping` | Por enviar | process | warning | yes | yes |
| `handover` | Entrega por coordinar | process | warning | yes | yes |
| `transit` | En camino | process | info | no | yes |
| `pickup` | Listo para retirar | process | info | no | yes |
| `owed` | Crédito por cobrar | process | warning | yes | hybrid only (credit is deferred, `money.md`) |
| `completed` | Venta completada | done | success | no | yes |
| `sold` | Venta cerrada | done | success | no | no (conversations) |

The engine measures a POS row with these rules, **in this order**:

1. An open invoice → `open`.
2. A closed ticket whose handover isn't `done` → by the handover: `delivery` / `dispatched` →
   `transit`; `delivery` / anything else → `shipping`; `pickup` → `pickup`; no mode →
   `handover`.
3. A closed ticket with money still owed → `owed`.
4. Anything else → `completed`.

- **SA-1** "A sale is done when the money arrived and the goods left." The goods come before the
  money: a credit sale not yet handed over is at its handover stage, and `owed` means "delivered
  and still unpaid" (the same reading as the receivables list).
- **SA-2** A row's `label` is the stage's `name` from the catalogue snapshot, in the company
  language (README, vocabularies). Stages marked "no" never occur offline, and the catalogue
  served in `local` leaves them out, so the stage filter doesn't offer them.
- **SA-3** `since` is when the row reached its current stage: the invoice's `opened` (1), the
  handover change, or `closed` when there was none (2), the ticket's date (3), the handover
  change or `closed` (4).

### Row fields

The `SaleModel` fields, filled from the document: `id` (invoice or ticket id), `source`,
`ticket`, `stage`, `label`, `level`, `attention`, `since`, `channel` (`pos`), `customer`,
`contact` (both `null` for POS sales, POS-33 has no customer, see `money.md` Open question 1),
`units`, `total`, `currency`, `method`, `collected`, `outstanding` (credit only; `null`
otherwise), `mode`, `state`, `seller` (name), `chat` (`""`), `date`, `updated`.

### Rules: listing

- **SA-10** `sales.list` takes `section` (required), `stage?`, `channel?`, `mine?`, `page`,
  `size`. `mine` = sold by the signed-in person (the seller of the invoice).
- **SA-11** Without `sales.view_all`, `mine` is forced to `true` on the master, whatever the
  client sends (plan §5.4: the master is the gate).
- **SA-12** Order: `attention` first, then `since` oldest first, then `id`. `total` counts the
  filter.
- **SA-13** `sales.process` / `sales.done` view permissions gate each section.

---

## sales.handover

### Rules

- **SA-20** Modes and their states: `immediate` → `done`; `pickup` → `pending`, `done`;
  `delivery` → `pending`, `dispatched`, `done`. This is the `handover` block of the stages
  catalogue, and the engine checks against it (`invalid_state`).
- **SA-21** Only `ticket` rows have a handover (`not_a_ticket` for an invoice).
- **SA-22** `sales.fulfil` takes `mode?`, `state?`, `note?`; at least one of mode and state
  (`nothing_to_change`). Naming **only** the mode moves the handover to that mode's first state
  (`immediate` → `done`, the others → `pending`). Naming the mode again resets the state, which
  is why the app sends only what changed.
- **SA-23** A blank `note` isn't sent and doesn't erase the stored one.
- **SA-24** Every change records `{at, by, note}` on the handover and answers the updated row
  **with its `section`** (the moment a row may change sides).
- **SA-25** `sales.approve` (confirm a payment at `verifying`) is about conversations: not
  available offline.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `sales.list` | `sales.view` + section view | SA-10 | `SalesPage` | — |
| `sales.catalog` | `sales.view` | — | `SaleStagesCatalog` + `channels` | — |
| `sales.detail` | `sales.view` (SA-11 applies) | `reference`: ticket code, row id | `SaleDetailModel` | `sale_not_found` |
| `sales.fulfil` | `sales.fulfil` | `id`, `mode?`, `state?`, `note?` | row | `not_a_ticket`, `invalid_state`, `nothing_to_change`, `sale_not_found` |

---

## sales.detail

`SaleDetailModel`, one shape for both sources.

### Rules

- **SA-30** `reference` resolves a ticket code (POS-41, any case) or a row id. Not found answers
  `sale_not_found`, which the app shows as news, not as an error.
- **SA-31** `items` come from the invoice lines: `price`, `list`, `discount` (POS-7),
  `subtotal`, `taxRate`, `tax`, `total`. `held`, `state`
  and `available` are filled for an open invoice; `gone` is true when the product was deleted.
- **SA-32** `reservations` is the list of the invoice's holds (`stock.md`) for an invoice, and
  **`null` on a ticket** (the app tells the two apart by it).
- **SA-33** `payment.proofs` is always `[]` offline: proofs come from conversations.
- **SA-34** `handover` is `null` on an invoice ("nothing to hand over").
- **SA-35** `origin` is `{kind: "pos", channel: "pos", terminal: <device name>}`.

### Events

| Event | When | Payload |
|---|---|---|
| `sale/progress` | a row's stage or section changed (open, line write that changes the total, close, cancel, fulfil, a settlement on a credit ticket) | the `SaleProgressModel` shape; **every key present**, `section: null` when the row left both lists |

Delivered to sessions with `sales.view`. A session without `sales.view_all` only gets its own
sales' notices (SA-11).

---

## Release status

The sales release serves the four ops (SA-1 to SA-35) and `sale/progress`. On the wire:
- money is in minor units of each row's `currency`, as on the ticket (`pos.md`; the app's
  `SalesLanSource` turns it into amounts); `sale/progress` carries no money;
- the detail's `status` is the cloud's (`open`, `completed`, `cancelled`), a standing hold reads
  `pending`, and a tracked line of an open invoice reads `state: reserved`, so a hold shrunk from the
  stock screen shows as unheld;
- the handover written at close is the counter's reading (`stored: false`); `sales.fulfil` writes
  `stored: true`;
- `sales.detail` and `sales.fulfil` apply SA-11 too: another person's sale is `sale_not_found`.
  `sales.detail` takes a ticket code or an id, `sales.fulfil` only the id;
- a stage with `offline: false` filters to an empty page; an unknown one is `invalid_field`.

## Differences from cloud

- No `chat` rows and none of their stages (`uncharged`, `verifying`, `paying`, `reserving`,
  `sold`), no payment proofs, no approval. No `owed` in `local` while credit is deferred.
- POS sales have no customer offline (the counter doesn't ask for one).

## Open questions

1. ~~Stage codes.~~ Decided: the cloud catalogue's codes and precedence (table above).
2. ~~POS discounts.~~ Answered: the product's own discount (`DISCOUNT` column) is taken off at
   the counter (POS-7). There is no discount typed in at the till, as in the cloud.
