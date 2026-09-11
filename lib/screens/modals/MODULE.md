# Module: modals

**Path** `lib/screens/modals`
**Role** Every dialog and side panel in the app. Modals are **not routes** — they do not
appear in `routes.dart` and do not change the URL.

**Layout** one folder per section, named after the section that opens the modal
(`business/ channels/ inventory/ sales/ finance/ pos/`), plus `shared/` for the ones more
than one section opens. Inside it, one folder per modal with entry file `_<name>.dart` and its
parts beside it. A new modal goes under the section that opens it; it moves to `shared/`
only once a second section opens it.

## How to open one

Use core's helpers (`package:app/toolkit/toolkit.dart`):

```dart
await showModal(context: context, title: ..., builder: (context) => const XModal());
await showSideModal(context: context, title: ..., builder: (context) => const XModal());
final ok = await showAlertModal(context: context, title: ..., confirmText: ..., cancelText: ...);
```

Three modals expose their own opener because they need setup or a non-default shape:
`showTableSettings(context, tableId)` (side panel), `showStockMovement(...)`,
`showImageViewer(context, url: ...)`.

The modal returns its result through `Navigator.pop(context, value)`; the caller awaits
the `show*` future.

## Files

### `business/`
- `business/create_business/_create_business.dart` — `CreateBusinessModal`. Opened from
  `BusinessSelector` and `NoBusinessSection`.
- `business/create_business/notice.dart` — `CreateBusinessNotice`: the legal notice.
- `business/edit_business_field/_edit_business_field.dart` — `EditBusinessFieldModal`: edits **one**
  profile datum.
- `business/edit_business_field/business_field.dart` — `BusinessField`: the registry of editable
  data — backend key, current value, and the input it is written with. **Add a datum here**
  to make it editable.
- `business/edit_business_email/_edit_business_email.dart` — `EditBusinessEmailModal`: create/edit
  an address.
- `business/verify_business_email/_verify_business_email.dart` — `VerifyBusinessEmailModal`.

### `shared/`
- `shared/crop_image/_crop_image.dart` — `CropImageModal({bytes})`: pick the visible square and
  zoom; returns the cropped bytes. Used before every logo/photo upload.
- `shared/image_viewer/_image_viewer.dart` — `showImageViewer(context, url:)`, `ImageViewer`:
  full-screen view.
- `shared/settings/settings_block.dart` — the read-only panel primitives: `SettingsBlock`
  `SettingsRow` `SettingsValue` `SettingsList` `SettingsTag` `SettingsStat`
  `SettingsAction` `SettingsToggle` `SettingsSelect`. **Build new panel rows from these.**
  Drawn by the table settings and by the sale detail; they decide nothing — the colour of
  a tag and the wording of an empty value are passed in by whoever draws the row.

### `channels/`
- `channels/create_channel/_create_channel.dart` — `showCreateChannel(context)`,
  `CreateChannelModal`: connecting a channel — network, credentials, agent role, data
  source, payment accounts, tools. No name/description (the backend does not require
  either). Reuses the controller and blocks of `sections/channels/form/`
  (`ChannelFormController`, `ProviderPicker`, `CredentialsBlock`, `AgentPicker`,
  `DataPicker`, `PaymentPicker`, `ToolsPicker`) rather than duplicating them — editing an
  existing channel is still that section's own page. Owns a `MoneyMethodsService` of its
  own and provides it: a modal route sits above the finance section's providers, so there
  is none to read. Returns `true` if a channel was created.
- `channels/channel_detail/_channel_detail.dart` — `showChannelDetail(context, channel:, label:)`,
  `ChannelDetailModal`: a channel's own panel, opened by tapping its card. Reads
  `ChannelsService.detail` and **edits it in place** with the same blocks the create panel
  uses (`AgentPicker`, `DataPicker`, `PaymentPicker`, `ToolsPicker`, `CredentialsBlock`) —
  no second modal for a field. Provides its own `MoneyMethodsService`, same as the create
  panel and for the same reason. Held back behind a confirm/cancel pair that only exists while
  `ChannelFormController.dirty`; cancel calls `revert()` and **rebuilds** — never
  remounts, since the inputs share their controllers and a fresh select writing its label
  into one while the old one still listens is a `setState() during build`. Rereads the
  grid itself instead of returning a result.
- `channels/channel_detail/channel_identity.dart` — `ChannelIdentity`: the card again at the top
  (icon, network, scope, `ChannelStateTag`), drawn from the list row so it is there before
  the detail lands.
- `channels/channel_detail/channel_account.dart` — `ChannelAccount`: the two read-only facts, the
  provider-side account id and the channel's own id, both selectable.
- `channels/channel_detail/channel_danger.dart` — `ChannelDanger`: unlink the WhatsApp Personal
  number (`BaileysService.unlink`, only for that provider) and disconnect the channel
  (`ChannelsService.remove`). Each confirms with `showAlertModal`.
- `channels/channel_detail/edit_bar.dart` — `ChannelEditBar`: the confirm/cancel pair at the foot of
  the panel. Absent until something differs from what the channel holds.
- `channels/baileys_pairing/_baileys_pairing.dart` — `showBaileysPairing(context, channelId:, initial:)`,
  `BaileysPairingModal`: the QR for a WhatsApp Personal channel. Opened from
  `BaileysChannelSwitch` right after `BaileysService.activate` comes back `qr_pending`;
  watches the session (`BaileysService.watch`) and closes itself once it connects.

### `inventory/`
- `inventory/create_table/_create_table.dart` — `CreateTableModal`: title, description and colour in
  one step.
- `inventory/create_field/_create_field.dart` — `CreateFieldModal`: a new column, spreadsheet-style.
- `inventory/rename_table/_rename_table.dart` — `RenameTableModal`.
- `inventory/edit_table_details/_edit_table_details.dart` — `EditTableDetailsModal`: **one** header
  datum, from the settings panel.
- `inventory/edit_table_details/table_detail_field.dart` — `enum TableDetailField`: which header data
  are writable.
- `inventory/import_table/_import_table.dart` — `ImportTableModal`: **chooses a source only**, it
  does not import.
- `inventory/import_table/source_row.dart` — `ImportSourceRow`.

### `inventory/table_settings/` (side panel)
- `inventory/table_settings/_table_settings.dart` — `showTableSettings(context, tableId)`,
  `TableSettingsModal`. Opens over the list or the sheet, so the URL stays as it was.
- `inventory/table_settings/summary_block.dart` — `TableSummaryBlock`, `TableDatesBlock`.
- `inventory/table_settings/columns_block.dart` — `TableColumnsBlock`; `columns_table.dart` —
  `TableColumnsTable`.
- `inventory/table_settings/agent_block.dart` — `TableAgentBlock`: what the model sees and can do.
- `inventory/table_settings/channels_block.dart` — `TableChannelsBlock`: channels reading this table.
- `inventory/table_settings/settings_id.dart` — `TableSettingsId`: hidden id with reveal + copy.
- `inventory/table_settings/settings_format.dart` — `settingsNumber(context, v)`,
  `settingsDate(context, at)`: locale-aware formatting for this panel.

Its rows are `shared/settings/settings_block.dart`, which is where they moved once the sale
detail drew them too.

### `inventory/stock_movement/`
- `inventory/stock_movement/_stock_movement.dart` — `showStockMovement(...)`, `StockMovementModal`.
  Opened from a stock summary stepper.
- `inventory/stock_movement/movement_shape.dart` — `StockMovementShape`, `StockCounter`,
  `StockDirection`, `MovementDestination`, `MovementDestinationKind`: which number is
  being touched and where the units go.
- `inventory/stock_movement/movement_option.dart` — `MovementOption`: a selectable outcome row.
- `inventory/stock_movement/quantity_field.dart` — `QuantityField`: amount with step buttons.

### `sales/`
- `sales/sale_detail/_sale_detail.dart` — `showSaleDetail(context, sale:, catalog:)` →
  `Future<SaleDetailRequest?>`, `SaleDetailModal`: **one sale opened in full**
  (`GET /sales/detail/:ID`), from a tap on any row of the board. It writes nothing: what a
  person can do to a sale is **asked for** here and recorded by the board — that is what
  the returned `SaleDetailRequest` is (`approve` · `fulfil`), and the board opens the
  confirmation or `showSaleFulfillment` once this panel has closed. **Both asks are one
  button on the card at the top** (`SaleDetailIdentity.action`) and never both at once, on
  `SaleModel.canApprove` then `SaleModel.canFulfil` — read off the row the panel was opened
  from, so the button is there before the read lands. Charging a ticket is still the
  counter. It owns a `SaleDetailService` of its own and reads on every opening —
  a sale is measured, so a cached detail is a sale as it was — and takes the channel
  catalog as a parameter, since a side modal opens above the sales section's providers.
  The header is drawn from the **row** and not from the read, so the panel names its sale
  the instant it slides in. The endpoint resolves a ticket id, an invoice id and a chat id
  to the same sale, so the panel asks with `SaleModel.id` whatever kind of row it is.
- `sales/sale_detail/detail_identity.dart` — `SaleDetailIdentity`: customer, ticket code,
  stage tag and wait, off the board's row, plus the panel's one `action` — handed in built,
  since the card carries the state a person came to change and the block that decides it is
  directly underneath. It decides nothing itself.
- `sales/sale_detail/detail_proof.dart` — `SaleDetailProof`: **el comprobante**, what the
  customer sent to show the money went out, drawn straight under the identity card and
  above the money. Three shapes, chosen by the **file** and not by the backend's `kind`: a
  picture (tap opens `showImageViewer` — the address is the file's own, since a `chat` file
  renders no thumbnails), a stored document that is not an image (offered through
  `launchUrl`), and text with the reference the customer typed. All of them newest first,
  because a customer who pays in two transfers sends two. An `image` entry whose bytes
  could not be stored says so rather than drawing an empty frame. `belongsTo(sale)` is
  where it is drawn at all: only a sale with a conversation behind it — a counter ticket
  has nowhere for one to have come from, and a heading over that reads as a gap.
- `sales/sale_detail/detail_money.dart` — `SaleDetailMoney`: units, subtotal, tax (with the
  per-rate breakdown when there is more than one), total, method and reference, and the
  collected/owed pair **only on a credit ticket**. Every figure is the backend's; nothing
  here adds up the lines. A missing figure is said in words, never as `0`. **Read two
  figures to a line** (`_MoneyGrid`, private to the file): every entry is a handful of
  characters under a two-word label, so one column left three quarters of the panel blank.
  The order is unchanged — units · subtotal · tax · total read left to right and then down
  — the method keeps a line of its own (its reference hangs under it), and under
  `AppSize.action * 6` of width it falls back to `SettingsList`, since the panel is only as
  wide as the window allows.
- `sales/sale_detail/detail_items.dart` — `SaleDetailItems`: **the summary of the lines and
  the way into them**, not the lines. A ticket has one line or three hundred, and three
  hundred of them pushed the handover, the holds and the origin past the bottom of a panel
  read top to bottom — so this is how many there are plus the button that opens
  `showSaleItems`. What stays out here is what somebody must not have to open a list to
  meet: how many lines are no longer sold, and how many say their units are held while the
  ledger holds none (`SaleItemModel.isUnheld`). An ordinary sale gets no such row at all.
- `sales/sale_items/_sale_items.dart` — `showSaleItems(context, sale:)`, `SaleItemsModal`:
  every line of one sale, in a panel of its own. It **stacks** on the sale's panel rather
  than replacing it (core's side modals do that by design: the sale slides right leaving a
  tab, closing comes back to it) — the one-panel-at-a-time rule is about a *form*, whose
  whole point is that you stop looking at what is behind it. `ListView.builder` and not a
  `Column` in a scroll: three hundred lines build the dozen on screen. The search is local
  (the lines came with the detail, so nothing is read again), matches name or code, and is
  drawn only past eight lines. Returns nothing — there is no action on a line.
- `sales/sale_items/item_line.dart` — `SaleItemLine`: one line — how many, of what, at
  what, for how much — with what the shelf says about it as tags: gone, held, what is left,
  and the one worth stopping on, a cart entry that says reserved while the ledger holds
  nothing.
- `sales/sale_detail/detail_handover.dart` — `SaleDetailHandover({sale})` (mode, state,
  when, by whom, note, and whether **anybody actually recorded it** — `stored`; a sale with
  no handover says why) and `SaleDetailHolds` (the ledger's standing holds and when they
  lapse, drawn only where `reservations` is not null). Both are readings: recording the
  handover is asked for from the identity card, which is where every action on a sale
  lives — the same request offered twice is two buttons for one write.
- `sales/sale_detail/detail_trace.dart` — `SaleDetailTrace`: channel, till or bot, seller,
  contact, note, the three moments (opened · charged · last movement) and the id. Rows for
  facts that are absent are not drawn rather than drawn empty.
- `sales/sale_fulfillment/_sale_fulfillment.dart` — `showSaleFulfillment(context, sale:,
  modes:)`, `SaleFulfillmentModal`: records **how a sale reaches its customer and how far
  that got** — the one write the sales board makes, and the one fact in that pipeline no
  collection can measure (nothing sees a van leave or a customer walk in for their box).
  It sets a fact (`MODE`, `STATE`) and never a stage; the stage that follows is computed
  on the backend and handed back. **Returns the request body** (`fulfilSaleRequest`) and
  writes nothing — `SalesService` is provided by the sales section, under the navigator
  this opens on — and the handover catalog comes in as a parameter for the same reason.
  Two rules the form exists to keep: the state picker only appears once a mode is chosen
  (the states belong to the mode), and **only what changed travels** — re-sending the mode
  a delivery already has would walk a dispatched order back to "sin despachar", so a
  submit with no difference is refused on the mode field instead. A mode change that
  invalidates the chosen state clears it **in the gesture**, never by letting the select
  notice its options changed, which would write a label mid-build.

### `finance/`
- `finance/record_payment/_record_payment.dart` — `showRecordPayment(context, concepts:,
  settlements:, accounts:, currency:, ticket?, amount?)`, `RecordPaymentModal`: records
  money received or paid. **Returns the request body** (`recordPaymentRequest`) and writes
  nothing — the money services are provided by the finance section, which lives under the
  navigator this opens on, so the vocabularies come in as parameters and the caller does
  the write. No direction control (the concept decides it) and no date field (core has no
  date picker; the backend stamps it now).
- `finance/payment_method_form/_payment_method_form.dart` — `showPaymentMethodForm(context,
  rails:, sheets:, options:, method?)`, `PaymentMethodFormModal`: adds or edits one of the
  company's accounts. One panel for both; on an edit the rail is drawn read-only, because
  changing it would rewrite what the payments already recorded say they came in through.
  **The middle of the form is drawn from the rail's sheet** (`MoneyMethodField`): a Pago
  Movil asks for a bank out of the list, a cedula or RIF and a phone and asks for no
  holder; cash asks for nothing. The sheet also says how: a `select` is offered as
  `0134 - Banesco` and searchable by either half, a `document` is picked as `V - Cedula` and
  kept in the field as `V` alone (`SelectOption.chosen`), and a field with a `format` is
  spaced as it is typed (`AccountMask`). Only the optional fields carry the word, name and
  instructions included. Picking another rail rebuilds those
  controllers in a new `FormController`, since `obligatory` is written when a controller is
  created. Returns `createMoneyMethodRequest` or `updateMoneyMethodRequest`.

Turning an account off and voiding a payment are `showAlertModal`, like every destructive
confirmation here.

### `pos/`
- `pos/pos_amount/_pos_amount.dart` — `PosAmountModal({currency})`, `PosAmountEntry`: charges
  something the catalog does not have (concept + price). Returns the entry.
- `pos/pos_tax/_pos_tax.dart` — `PosTaxModal({rate})`: the tax percentage of the ticket
  (`16`, never `0.16`). Returns the rate as a `double`; the empty field is zero.
- `pos/pos_checkout/_pos_checkout.dart` — `PosCheckoutModal({methods, currency, total})`,
  `PosCheckoutEntry`: how the ticket is being paid. The methods come in as a parameter
  (`PosMethodsService` is below the navigator) and the reference is required on the
  methods that carry one. The total is shown, never asked for.

All three **return a value and write to no service**: `PosInvoiceService` and
`PosMethodsService` are provided by the POS page, which is below the navigator these are
opened on.

Three traps they were written around, all worth knowing before touching any modal here:

- A `late final InputController` whose `customErrors` read `S.of(context)` **cannot be
  touched from `initState`** — that is an inherited lookup before the element is mounted,
  and the half-built modal takes the navigator down a frame later with
  `_dependents.isEmpty`. Build them from `build` (or `didChangeDependencies`).
- **A side modal opened from a side modal stacks**, which core supports and nothing in
  this app used until `sale_items` opened over `sale_detail`. It asserted the first time:
  a panel joins core's stack from its own `initState`, which runs while the overlay is
  building the route that brought it, and the panels already open were built earlier in
  that same pass — so telling them the stack moved was a `setState()` during build. Fixed
  in core (`_SideStack` announces after the frame in flight); it needs a **restart** and
  not a hot reload, since it is a path package.
- `InputType.numeric` forces `FilteringTextInputFormatter.digitsOnly` in core, so a field
  that takes decimals must not use it: `12,50` arrives as `1250`. Use the default text type
  with `pattern: "[0-9.,]"` and read the value with `CurrencyModel.parse`.

## Conventions

- A modal never navigates. It returns a value; the caller decides what to do.
- One folder per modal even when it is a single file — its parts live beside it, and
  that folder sits under the section that opens it (`shared/` when more than one does).
- Destructive confirmations use `showAlertModal`, not a custom modal.
- **The content scrolls itself.** `showModal` and `showSideModal` hand the builder a
  bounded height (the panel is as tall as the window) and no scroll of their own, so a
  form of more than a few fields goes in a `ScrollableWidget`; a bare `Column` overflows
  on a short screen. Add `padding: EdgeInsets.only(bottom: AppSize.padding)`: the side
  panel leaves its bottom padding out on purpose so scrolled content reaches the edge.
