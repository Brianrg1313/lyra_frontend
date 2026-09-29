# Contract: currencies and method charges (`/lyra/v1/money`)

**Status: proposed, not yet built on the backend.** The app is already written against it
(`money_currencies_service.dart`, `money_currency_model.dart`, `money_currency_request.dart`,
`money_method_model.dart`, `money_method_request.dart`). Until it exists, the currencies block of
the payment methods tab shows its error state and the account form does not ask for a currency.

Gated on the `money` permission like the rest of `/money`. The company comes from the
`business_id` header, never from the body.

---

## 1. Currencies — `/money/currencies/`

Backed by `companies.currency` (main, read-only) and `company_currencies` (exchanges), which
`model:/currency/currency.js` already reads. Rates always mean
**1 unit of the main currency = `rate` units of this one** (`1 USD = 36.52 VES`).

### `GET /money/currencies/`

```json
{
  "currency": "USD",
  "currencies": [
    {
      "currency": "VES",
      "mode": "custom",
      "rate": 40.5,
      "official": 36.5234,
      "custom": 40.5,
      "updated": "2026-09-23T10:00:00Z"
    },
    {
      "currency": "EUR",
      "mode": "official",
      "rate": 0.92,
      "official": 0.92,
      "custom": null,
      "updated": "2026-09-23T10:00:00Z"
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `currency` | Main currency (`companies.currency`). Stock, services and prices are stored in it. |
| `currencies[].currency` | ISO 4217 code, uppercase. Never the main one. Only `status = 1` rows. |
| `mode` | `official` (the feed's rate) or `custom` (the company's figure). |
| `rate` | **Effective** rate today: `custom` when mode is custom, else `official`. `null` when there is none (feed down past `#maxAge`). The app displays this and never picks between the other two. |
| `official` | The feed's rate (`Currency.#official`), whatever the mode. `null` when unavailable. |
| `custom` | The stored custom figure, kept even when mode is official (so switching back does not lose it). |
| `updated` | When `official` was last refreshed (ISO 8601, UTC). |

The app treats `0`, negatives and non-numbers as `null`.

### `PUT /money/currencies/` — add or edit (upsert by `bid` + `CURRENCY`)

```json
{ "CURRENCY": "VES", "MODE": "custom", "RATE": 40.5 }
{ "CURRENCY": "EUR", "MODE": "official" }
```

- `CURRENCY` required, must be in `lyra_admin.currencies` (fiat), must not be the main currency.
- `MODE` required, `official` | `custom`.
- `RATE` required and `> 0` when `MODE` is `custom`; **ignored** when `official` (the stored custom
  figure is left untouched). A client can never write an "official" figure.
- Re-adding a currency with `status = 0` flips it back to `1` instead of inserting.
- Invalidate `currency:pricing:<bid>` in Redis on every write, or the agent keeps quoting the
  old rate for up to `#configTtl`.
- Answer: `{ "ok": true }`. The app rereads with `GET`.

### `DELETE /money/currencies/`

```json
{ "CURRENCY": "VES" }
```

Soft delete (`status = 0`). Payment methods in that currency stay; they just have nothing to
convert into. Invalidate the Redis pricing key.

### Suggested schema change (`databases/schema.sql`)

```sql
ALTER TABLE `company_currencies`
    ADD COLUMN `mode` VARCHAR(8)     NOT NULL DEFAULT 'official' AFTER `currency`,
    ADD COLUMN `rate` DECIMAL(18, 6) NULL                        AFTER `mode`;
```

`Currency.pricing()` then resolves `rate` as `mode = 'custom' ? rate : official × margin`. `margin`
stays as it is (default 1); the app does not write it. A custom secondary must still be usable
when the feed is down: it does not depend on `official`.

---

## 2. Payment methods — additions to `/money/methods/` and `/business/payments/`

### `GET /business/payments/` — rails

Each rail may carry the one currency it moves:

```json
{ "code": "pago_movil", "name": "Pago Móvil", "method": "mobile", "currency": "VES" }
{ "code": "zelle",      "name": "Zelle",      "method": "transfer", "currency": "USD" }
{ "code": "cash",       "name": "Efectivo",   "method": "cash" }
```

`currency` empty or missing = the rail takes any currency and the company picks. It is the
same fact `model:/money/templates.js` hard-codes today (`Templates.#bolivar`); it belongs in
`lyra_admin.payment_methods` as a nullable `currency` column.

### `GET /money/methods/` — each account gains

```json
{
  "id": "m1",
  "code": "pago_movil",
  "currency": "VES",
  "fee": { "type": "percent", "value": 3 }
}
```

| Field | Meaning |
|---|---|
| `currency` | Currency money comes into this account in. Empty/missing is read as the main currency. |
| `fee.type` | `none` \| `fixed` \| `percent`. |
| `fee.value` | `fixed`: an amount **in the account's `currency`**. `percent`: written `3`, never `0.03`. `0`/missing with `none`. |

### `POST` / `PUT /money/methods/` — new keys

```json
{ "CURRENCY": "VES", "FEE_TYPE": "percent", "FEE": 3 }
```

- `CURRENCY`: must be the main currency or an active exchange currency. **When the rail has a
  `currency`, the rail's wins** whatever is sent. Missing on `POST` = the rail's, else the main.
- `FEE_TYPE` / `FEE`: on `POST` only sent when there is a commission. On `PUT`, `FEE_TYPE: "none"`
  with `FEE: null` removes it; keys missing = leave as is (same rule as the other columns).
- Validation: `FEE > 0`; `percent` `< 100`.

Suggested columns on `company_payment_methods`:

```sql
ALTER TABLE `company_payment_methods`
    ADD COLUMN `currency` CHAR(3)        NULL                   AFTER `method`,
    ADD COLUMN `fee_type` VARCHAR(8)     NOT NULL DEFAULT 'none' AFTER `currency`,
    ADD COLUMN `fee`      DECIMAL(18, 4) NULL                   AFTER `fee_type`;
```

### Charging with it (backend only, the app adds nothing up)

For a sale of `T` in the main currency paid through an account in currency `C` at effective rate
`r` (`r = 1` when `C` is the main):

```
base   = T × r
fee    = fixed   → fee.value                (already in C)
         percent → base × fee.value / 100
charge = base + fee                          (rounded to C's decimals)
```

This is what `Templates` should render (the Pago Móvil message) and what `Ticketing.owed` should
compare a payment against. A payment keeps stamping the currency it was received in.
