# Spec: inventory (tables, fields, records, images, import)

**Plan** §2 (inventory row). **App today** `stock/tables/*`, `inventory/*`,
`screens/home/sections/inventory`.

A company keeps its products in **tables** it designs itself: typed columns (fields) and rows
(records). One table is the **primary** one: it is what the POS sells from and what the stock
ledger counts (`stock.md`). Offline, everything works except what needs a language model: the
AI typing of imported columns is replaced by fixed rules, and semantic search by text search.

---

## inventory.table

### Data

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `name` | string, 1–80 | `TITLE` on create, `NAME` on edit |
| `description` | string? | ≤ 500 |
| `color` | ARGB literal (`0xFF2196F3`) | as the app sends it |
| `primary` | bool | exactly one table is primary once any table exists (I-3) |
| `created`, `updated` | instant | |
| `lastRecord` | instant? | when a record was last created or edited |
| `records` | int | count of live records |
| `importStage` | `null` / `preparing` / `loading` | I-42, I-45 |

### Rules

- **I-1** Creating a table with a `TEMPLATE` adds that template's starting fields. The app's
  `TableTemplate` names the codes; the fields of each are `TableTemplates` in `lyra_protocol`
  (name, SKU, price, stock and photos, then the template's own), named in the company's language
  (English where it has no name of its own), with the title, SKU and price in the summary.
- **I-2** Deleting a table is soft. Its records disappear from every list and from the POS.
  Stock movements that name its products are kept (history is never deleted) and keep reading
  the product's frozen name.
- **I-3** The first table created is primary. The company can give the flag to another table
  (`primary: true` on `inventory.tables.edit`), which takes it from the one that held it in the
  same write. There is no unmarking: `primary: false` is refused (`invalid_primary`), since a
  company with tables and no primary one has nothing to sell or count. If the primary table is
  deleted, the oldest remaining table becomes primary.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `inventory.tables.list` | `products` | — | `[TableLite]` | — |
| `inventory.tables.create` | `products.structure` | `title`, `description?`, `color`, `template?` | `{id}` | `invalid_field`, `unknown_template` |
| `inventory.tables.edit` | `products.structure` | `id`, `name?`, `description?`, `primary?` | table | `not_found`, `invalid_primary` |
| `inventory.tables.delete` | `products.structure` | `id` | `{}` | `not_found`, `has_open_tickets` (I-4) |
| `inventory.tables.structure` | `products` | `id` | `TableStructure` (fields in the `{keys, values}` shape) | `not_found` |
| `inventory.tables.details` | `products` | `id` | `TableDetail` | `not_found` |

- **I-4** A table whose products are held by an open POS ticket can't be deleted
  (`has_open_tickets`, naming the ticket codes). Cancel or charge them first.
- **I-5** `TableDetail.agent` and `TableDetail.channels` describe AI agents and channels. Offline
  they answer `{reached: false}` / empty, and the app hides those blocks (capability gate).

---

## inventory.field

### Data

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | the `FIELD_ID` |
| `tableId` | uuid | |
| `name` | string, 1–60 | |
| `description` | string? | |
| `type` | one of `TableFieldType` codes | `TEXT` … `STOCK` |
| `position` | int | 0-based, dense |
| `width` | int? | px, `null` = default |
| `options` | [string] | only `OPTIONS` / `CATEGORIES` |
| `unit` | string | only `PRICE` / `CURRENCY` / `MEASURE` |
| `visibility` | `visible` / `declared` / `hidden` | kept for hybrid; no local effect |
| `summary` | bool | shown in the stock summary |
| `created`, `updated` | instant | |

### Rules

- **I-10** `COUNTER` and `STOCK` fields are never written by hand (`read_only_field`). A table has
  at most **one** `STOCK` field and at most one `COUNTER` field (`duplicate_field_type`).
- **I-11** `COUNTER` is a per-table sequence: a new record gets the next integer, starting at 1.
  Numbers are never reused, even after a delete.
- **I-12** A `STOCK` cell answers the ledger's `available` for that record (`stock.md`). It is
  computed on read, never stored in the record.
- **I-13** Positions stay dense: creating at `position` shifts the fields at or after it; moving
  a field shifts the ones between; deleting closes the gap.
- **I-14** Changing a field's type keeps every stored value **as text** and re-reads it under the
  new type: a value that doesn't fit the new type (I-21) is kept and shown as invalid, never
  thrown away. (The app shows what it can't parse as text already.)
- **I-15** Options: a list field's options are trimmed, empty ones dropped, duplicates (compared
  without case) dropped. Removing an option from the list doesn't touch records that hold it
  (`TableFieldModel.options`: "a loaded value survives its option being removed").
- **I-16** Deleting a field is a hard delete of the column **and its values** after a
  confirmation on screen. It is recorded in the audit log with the field name and count of
  non-empty values.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `inventory.fields.create` | `products.structure` | `tableId`, `name`, `description?`, `type`, `position`, `options?`, `unit?` | field | `invalid_field`, `duplicate_field_type` |
| `inventory.fields.edit` | `products.structure` (`width` alone: `products`, see I-17) | `id`, and any of `name`, `description`, `type`, `position`, `width`, `visibility`, `summary`, `options`, `unit` | field | `not_found`, `read_only_field`, `duplicate_field_type` |
| `inventory.fields.delete` | `products.structure` | `id` | `{}` | `not_found` |

- **I-17** A column width is a property of the table, shared by everyone (as today). Anyone who
  can open the table may drag it.

---

## inventory.record

### Data

`record { id, tableId, values: {fieldId: value}, created, updated, createdBy, updatedBy, deleted }`.

### Rules

- **I-20** Writes are `{fieldId: value}` maps (`DATA`). A create may carry any subset; an edit
  carries the fields that changed. `null` or `""` clears a cell.
- **I-21** Values are checked against the field type:

  | Type | Stored as | Accepts |
  |---|---|---|
  | `TEXT` `TITLE` `SKU` `BARCODE` `EMAIL` `PHONE` `URL` | string | any text ≤ 1000 (`TEXTAREA`/`DESCRIPTION` ≤ 10 000). No format check on email/phone/url offline: the app formats, the engine stores. |
  | `NUMBER` | integer | an integer |
  | `DECIMAL` `PERCENTAGE` `MEASURE` | decimal string | a number, dot as the decimal separator |
  | `DISCOUNT` | decimal string | a percent off the price, 0–100 (`20`, never `0.20`); anything else is refused, because the POS subtracts it (POS-7) |
  | `PRICE` `CURRENCY` | decimal string | a number ≥ 0, with at most the column currency's decimals |
  | `BOOLEAN` | bool | `true`/`false`/`1`/`0` |
  | `DATE` | `YYYY-MM-DD` | that shape (`ProductDate`) |
  | `DATETIME` | ISO instant | that shape |
  | `OPTIONS` | string | any text (I-15), it doesn't have to be in the list |
  | `CATEGORIES` | [string] | a list of texts |
  | `IMAGE` | [imageRef] | written only through `inventory.images.*` |
  | `COUNTER` `STOCK` | — | refused (I-10) |

  A value that doesn't fit is refused with `invalid_value` naming the field.
- **I-22** `SKU` values are unique within a table when present (`duplicate_sku`), compared
  without case and trimmed. `nextSku` keeps generating them on the client, as today.
- **I-23** Deleting a record is soft (I-2). There is no delete op in the app today; the engine
  has one for the POS and imports (`inventory.records.delete`), gated by `products.delete`.
- **I-24** A record held by an open ticket can be edited (name, price…): the ticket keeps the
  values frozen on its line (`pos.md`, POS-12).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `inventory.records.list` | `products` | `tableId`, `page` (from 1), `size` (≤ 200), `match?` | `{keys, values, page, size, total}` (the `TableViewModel` shape: `keys` is `"id"` then the field ids in position order; each row is the record id then its cells) | `not_found` |
| `inventory.records.create` | `products.create` | `tableId`, `data` | `{id}` | `invalid_value`, `duplicate_sku` |
| `inventory.records.edit` | `products.edit` | `tableId`, `id`, `data` | `{}` | `not_found`, `invalid_value`, `duplicate_sku`, `read_only_field` |
| `inventory.records.delete` | `products.delete` | `tableId`, `id` | `{}` | `not_found`, `has_open_tickets` |

- **I-25** Order of `records.list`: creation order (UUIDv7), oldest first, as the sheet draws it.
- **I-26** `match` is the text search of the README over every text-like field of the table
  (`TEXT` `TEXTAREA` `TITLE` `DESCRIPTION` `SKU` `BARCODE` `OPTIONS` `CATEGORIES`). It is the
  offline replacement of the cloud's semantic match.

---

## inventory.images

### Rules

- **I-30** An `IMAGE` cell is a list of up to 8 images; the images ops write the table's first
  `IMAGE` field (a table without one answers `invalid_field`). Upload adds one to the end; remove takes
  one out by its file id. The first is the cover (what POS and the stock summary draw).
- **I-31** Images: `png`/`jpeg`/`webp`, ≤ 10 MB. The engine stores the original and the sizes
  `ProductImage` asks for (thumbnail sizes, see that file), in the encrypted file store.
- **I-32** An import can leave **external addresses** in an image cell (`{id: null, url}`).
  Offline they are kept as text and drawn as a missing image. They are never fetched by the
  master (it may have no internet, and fetching arbitrary URLs from the LAN server is a risk).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `inventory.images.add` | `inventory.pictures` | `tableId`, `productId`, `fileId` (uploaded first, `protocol-v1.md`) | the cell | `too_many_images`, `invalid_file` |
| `inventory.images.remove` | `inventory.pictures` | `tableId`, `productId`, `fileId` | the cell | `not_found` |

---

## inventory.import

The app uploads a spreadsheet in two steps: the **structure** (a table is created from the
header row) and then the **records** (rows are added once the columns are typed). Between the
two, the table is `preparing`, and the app waits for `table/ready`.

### Rules

- **I-40** Formats: `.xlsx` (`.xlsm` too, its macros ignored; the first sheet is read) and
  `.csv` (UTF-8, UTF-16 with a BOM, or Windows-1252 when the bytes aren't UTF-8, as Excel saves a
  CSV on a Spanish or Portuguese Windows; the separator is detected from `,` `;` and tab). The
  cloud also reads `.xls`, `.xlsb` and `.ods`; the app offers a master only the two it reads.
  Maximum 20 MB, 50 000 data rows and 250 columns (`too_large`). The upload is read once and
  deleted by the op that reads it: each step uploads the file again, as with the cloud.
- **I-41** `ROW` is the 1-based header row; rows above it are ignored, empty rows dropped. Empty
  header cells get the name `Column N`. Duplicate header names (without case) get ` (2)`, ` (3)`
  appended. A name is cut at 60 characters. A table name the app doesn't send is "Imported table"
  in the company's language.
- **I-42** The structure step creates the table with every column as `TEXT`, sets `importStage =
  preparing`, emits `table/normalizing`, and answers `{id}`. The rules of I-43 take milliseconds,
  so offline they run inside the same step: both events follow its answer, and the app's wait
  (which may see `table/ready` before it starts waiting) reads it the same way.
- **I-43** **Typing rules** (the offline replacement of the AI pass), run on the header and the
  first 200 values of each column:
  1. By header, using the bundled keyword dictionary (`Typing.keywords` in the engine: English,
     Spanish, Portuguese, matched as whole words without case or accents, the more specific kinds
     first: `código de barras`, `ean` → `BARCODE`; `foto`, `imagen` → `IMAGE`; `categoría` →
     `CATEGORIES`; `descripción` → `DESCRIPTION`; `stock`, `existencia`, `cantidad` → `STOCK`
     (I-44); `precio`, `pvp`, `costo` → `PRICE`; `sku`, `código`, `ref` → `SKU`; `nombre`,
     `producto` → `TITLE`), when at least 95 % of the column's non-empty values fit that type (a
     "Stock" column of yes/no is not a stock column).
  2. Otherwise by values, when at least 95 % of the non-empty values fit, tried in this order:
     `true/false/sí/no` → `BOOLEAN`, 8/12/13/14-digit codes with a valid check digit → `BARCODE`,
     integers → `NUMBER`, decimals → `DECIMAL`, `YYYY-MM-DD` or the language's day order
     (`31/12/2026`; `12/31/2026` in English) → `DATE`, `YYYY-MM-DD HH:mm` → `DATETIME`, e-mail →
     `EMAIL`, URL → `URL`. A number takes `,` or `.` as its decimal mark, a currency sign and
     thousands separators (`$1.234,50`).
  3. At most one `TITLE` (the first match) and one `STOCK`; a later one stays `TEXT`. When no
     header named the title, the first column left as `TEXT` becomes the `TITLE` (a product needs a
     name to be sold and searched by). Everything else stays `TEXT`.
  4. `summary` is turned on for the `TITLE`, `SKU` and `PRICE` fields.
  5. A table without an `IMAGE` column gets one at the end ("Photos" in the company's language),
     which is what `table/ready` names as `image`.
- **I-44** A column typed `STOCK` doesn't become a stock field with values: its numbers are read
  as the **opening balance** and written to the ledger as `add` / `restock` movements with the
  note "import", one per record, when the records step runs (`stock.md`).
- **I-45** When typing ends, the engine sets `importStage = loading`, emits `table/ready`
  (`{id, ok: true, normalized: true, retyped, summarized, image}`), and waits for the records
  step. The records step matches each file column to the field of the same name (without case or
  accents; a column with no field is skipped), adds the rows in the file's order in one
  transaction, then sets `importStage = null` and emits one `table/changed`.
- **I-46** A row whose cell doesn't fit its column is still imported with that cell kept as text
  (I-14), read with I-43's number and date marks first. Two exceptions drop the cell instead: a
  repeated SKU (I-22; the first row keeps it) and an image cell without an address. The answer of
  the records step reports `{imported, withInvalidCells}` (rows with at least one such cell). A
  `COUNTER` numbers the rows; rows with nothing in any matched column are skipped.
- **I-47** `inventory.tables.normalize` re-runs I-43 on a table **only for fields nobody typed by
  hand** (an import's columns until someone changes their type; `TableNormalizeModel`: "it only
  reviews the columns nobody touched"), over the first 200 records' values. It never makes a
  `STOCK` or `COUNTER` column (their values aren't cells), nor a second `TITLE`. Values are read
  again as I-46 reads them. It answers the `TableNormalizeModel` counts (`narrowed` and `renamed`
  are always 0, `reindexed` always `false` offline) and emits `table/changed`, no import events.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `inventory.import.structure` | `products.structure` | `fileId`, `format`, `name?`, `row` | `{id}` | `unsupported_file`, `too_large`, `empty_file` |
| `inventory.import.records` | `products.import` | `fileId`, `format`, `tableId`, `row` | `{imported, withInvalidCells}` | `not_found`, `unsupported_file` |
| `inventory.tables.normalize` | `products.structure` | `tableId` | `TableNormalizeModel` | `not_found` |

### Events

| Event | When | Payload |
|---|---|---|
| `table/normalizing` | I-42 | `TableNormalizingModel` shape |
| `table/ready` | I-45 | `TableReadyModel` shape |
| `table/changed` | a table's name, fields or records changed | `{id, what: "structure" \| "records"}` |

---

## Differences from cloud

- Column typing is rule-based (I-43), not AI. It is predictable and less clever: people fix the
  rest by hand, which normalization then respects.
- Search is text, not semantic.
- Agent visibility (`visibility`) and the channel/agent blocks have no effect offline. They are
  kept so a hybrid company doesn't lose them.
- External image addresses from imports are never fetched.

## Release status

The inventory release serves tables, fields, records and images; the import release adds the
three ops of `inventory.import` and `inventory.tables.normalize`, so every op above is served.
The POS release adds I-4 (`has_open_tickets` names the codes in `data.tickets`). A cell written by hand is checked by I-21: the app's date-and-time form (`2026-02-12 12:30`)
and categories typed as `a, b` are accepted and stored as given / as a list.

## Open questions

1. ~~How is the primary table chosen?~~ Answered: the company picks it, with `PRIMARY: 1` on the
   table edit, and it can't be unmarked (I-3).
2. ~~Column width.~~ Decided: anyone who can open the table (I-17).
3. ~~Record delete.~~ Answered: the cloud has one (soft), so the engine keeps I-23. The app has no
   button for it today; adding one is an app change for both sources, outside these specs.
