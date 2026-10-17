# Module: modals

**Path** `lib/screens/modals`
**Role** Every dialog and side panel. Modals are **not routes**: not in `routes.dart`, no URL change.
**Layout** One folder per opening section (`business/ channels/ knowledge/ inventory/ supply_chain/ sales/ finance/ messages/ pos/ pre_start/ permissions/ home/`),
`shared/` for modals opened by more than one. One folder per modal, entry `_<name>.dart`,
parts beside it. A modal moves to `shared/` only once a second section opens it.

## Opening

```dart
await showModal(context: context, title: ..., builder: (context) => const XModal());
await showSideModal(context: context, title: ..., builder: (context) => const XModal());
final ok = await showAlertModal(context: context, title: ..., confirmText: ..., cancelText: ...);
```

Modals that need setup expose their own `show*` opener (listed per file). Results come back
through `Navigator.pop(context, value)`.

## Conventions

- A modal never navigates: it returns a value, the caller decides.
- Destructive confirmations are `showAlertModal`, never a custom modal.
- **A modal opens above the section's providers.** Section-scoped services (money, sales, POS)
  are not readable inside it: pass vocabularies in as parameters and **return a request body**;
  the caller writes. Or create and provide its own instance (channels' `MoneyMethodsService`).
- **Content scrolls itself**: `showModal`/`showSideModal` give a bounded height and no scroll.
  Use `ScrollableWidget` with `padding: EdgeInsets.only(bottom: AppSize.padding)` (the side panel
  omits bottom padding on purpose).

## Traps

- A `late final InputController` whose `customErrors` read `S.of(context)` **cannot be built in
  `initState`** (inherited lookup before mount → navigator crashes a frame later with
  `_dependents.isEmpty`). Build it in `build`/`didChangeDependencies`.
- A side modal opened from a side modal **stacks** (core `_SideStack`). A core fix there needs a
  full **restart**, not hot reload (path package).
- `InputType.numeric` forces `digitsOnly`: `12,50` becomes `1250`. For decimals use the default
  type with `pattern: "[0-9.,]"` and `CurrencyModel.parse`.
- Never let a select "notice" its options changed mid-build (it writes its label → `setState()
  during build`). Clear dependent values in the gesture; on revert **rebuild**, don't remount.

## Files

### `shared/`
- `approve_payment/_approve_payment.dart` — `showApprovePayment(context)` → `PaymentApproval?` (`amount` null = all of it,
  `currency` among the company's, null = the ticket's), `ApprovePaymentModal`. Writes nothing. From the chat header and the sales board.
- `crop_image/_crop_image.dart` — `CropImageModal({bytes})`: square crop + zoom, returns bytes. Before every logo/photo upload.
- `image_viewer/_image_viewer.dart` — `showImageViewer(context, url:)`, `ImageViewer`: full screen.
- `opening_hours/week_editor.dart` — `WeekEditor`: one branch's week (`OpeningHoursService`), Monday first, typed by
  `WeekMode` (every day / weekdays and weekend / day by day; opens on the coarsest the saved week fits), stretches per
  group (add, remove, copy the day before), validated (`HH:MM`, no overlap) and written whole per day; read only without
  `appointments.configure`. Used by `branch_hours` and `shipping_settings`.
- `opening_hours/closed_days.dart` — `ClosedDays`: the days ahead closed in that branch or in every one; close (day,
  reason, every branch), open again (asks for an every-branch one). Same two users.
- `settings/settings_block.dart` — read-only panel rows: `SettingsBlock` `SettingsRow` `SettingsValue`
  `SettingsList` `SettingsTag` `SettingsStat` `SettingsAction` `SettingsToggle` `SettingsSelect`.
  Decide nothing (colour/empty wording passed in). **Build new panel rows from these.**

### `business/`
- `branch_picker/_branch_picker.dart` — `showBranchPicker`, `BranchPickerModal` (the person's branches; a pick is `BranchService.select`), `BranchChoice` (glyph, name, address, check). Opened by the home (`_AskBranch`).
- `create_business/_create_business.dart` — `CreateBusinessModal` (from `BusinessSelector`, `NoBusinessSection`, `Welcome`); pops `true` on success. With `singleCompany` (a master's welcome) it also asks country, main currency (proposed by the country) and language from `Catalogs`, without the notice. The fields scroll, the button stays under them.
- `create_business/notice.dart` — `CreateBusinessNotice`: legal notice.
- `edit_business_field/_edit_business_field.dart` — `EditBusinessFieldModal`: edits **one** profile datum.
- `edit_business_field/business_field.dart` — `BusinessField`: registry of editable data (key, value, input). **Add a datum here.**
- `edit_business_email/_edit_business_email.dart` — `EditBusinessEmailModal`: create/edit an address.
- `verify_business_email/_verify_business_email.dart` — `VerifyBusinessEmailModal`.
- `two_factor/_two_factor.dart` — `showTwoFactorSetup(context, service:, email:)` (method, then its step; the factor in force proven last), `TwoFactorChoiceModal`; re-exports `showTwoFactorProof`, `showRecoveryCodes`. Opened from `OwnSecurity`; every write goes through the passed `AccountSecurityService`.
- `two_factor/two_factor_app.dart` — `TwoFactorAppModal`: staged secret as QR (`PairingQr`) and grouped key, the app's first code → pops the recovery codes.
- `two_factor/two_factor_email.dart` — `TwoFactorEmailModal`: mails the code on opening (resend), takes it back → pops `true`.
- `two_factor/two_factor_proof.dart` — `showTwoFactorProof(context, method)` → `TwoFactorProof?` (app code or recovery code; email: mails `two_factor/code` on opening), `TwoFactorCode` (6 digits, 400 wide).
- `two_factor/recovery_codes.dart` — `showRecoveryCodes(context, codes)`: shown once, two per row, copy all.
- `create_password/_create_password.dart` — `showCreatePassword(context, service)` → `bool`: the account's first password, typed twice; a refusal because one exists closes it.
- `invite_employee/_invite_employee.dart` — `showInviteEmployee(context, employees:)`, `InviteEmployeeModal`: email + job title
  (the backend files the job with the invitation) + an optional permissions template (`inviteTemplates`; none offered = no field); **writes** through the `BusinessEmployeesService` passed in. Returns `true` if sent.
  On a master the form gives way to the activation code (`_ActivationCode`: the code, its expiry, copy, done), shown once.
- `branch_form/_branch_form.dart` — `showBranchForm(context, branches:, country:, branch?)`, `BranchFormModal`:
  create (no `branch`) or edit one branch whole — name, store/warehouse (`STOREFRONT`, two cards), bot orders (`ONLINE`),
  main (not drawn on the main branch), phone, legal name + tax id (empty = the company's), address, landmark, city,
  region, postal code and the point on `DeliveriesMap` (beside the form; in one column, before the address; opens on the
  branch's point). `country` (the company's) fixes the phone code; only the main branch's form asks for it, and saving
  it also writes the changed country and phone on the company (`BusinessService.editProfile`). Owns its own
  `BusinessLocationService` + `MapTilesService` + one `BusinessPlacesService` per search (map box, address field); **writes** through the branches service
  passed by constructor (edit sends only what changed). Cloud only: an "Opening hours" row opens `showBranchHours` on a saved branch (a new one is born with the main
  branch's week). Returns `true` if something was written.
- `branch_hours/_branch_hours.dart` — `showBranchHours(context, branch:)`, `BranchHoursModal`: side panel with that
  branch's `WeekEditor` + `ClosedDays`; **owns** an `OpeningHoursService` for it (writes name `BRANCH`, any branch, not
  only the one worked in); editable with `appointments.configure` from `Sources.permissions.mine()`.
- `branch_form/phone_field.dart` — `BranchPhoneField`: one box, the company's flag + dial fixed in front of
  the typed number; without a country (or a saved phone with another code) the whole phone, flag of the typed code.
- `branch_form/place_search.dart` — `PlaceSearch`: the address search floating over the map's top edge (Google
  Places through the backend, answers restricted to the company's country). Asks 350 ms after typing stops (the
  core field's own wait is too long; the service drops repeats). Answers drop from the box as a select (core
  `SelectOptionTile` in an `OverlayPortal`). Draws **nothing** when the server has no key, and hands the pick up —
  it writes no field itself. With `child` the dropdown hangs from that field instead (the employee address tile, the
  branch form's address). Only a focused field asks: text the form writes after a pick searches nothing.

### `channels/`
- `create_channel/_create_channel.dart` — `showCreateChannel(context, {preset})`, `CreateChannelModal`: core `showStepModal` + `ModalSteps`, one question per page
  under a `StepArt`: network → role → data source → payment accounts → tools
  (no name/description, no credentials: added on the channel's page). Next stops only without a network, or on a product table not chosen. Reuses `sections/channels/form/`
  controller, `ProviderPicker` (`labeled: false`), `DataTableSelect`, `PaymentPickerNote`. Provides its own
  `MoneyMethodsService`. A `ChannelPreset` fills it, opens it on the role step (and picks the main table once the tables are read). Returns the new id, `null` if closed.
- `create_channel/step_bodies.dart` — `RoleStep` `SourceStep` `PaymentsStep` `ToolsStep` (answers as `ChoiceCard`s, each with its hint).
- `create_channel/choice_card.dart` — `ChoiceCard`: full-width answer (icon, name, one line, round or square mark, "Soon" badge).
- `create_channel/step_art.dart` — `StepArt(gradient, icon)`: a themed `gradient-N.png` with the step's icon in a white ring.
- `baileys_pairing/_baileys_pairing.dart` — `linkBaileysChannel` (start the session, pair on `starting`/`qr_pending`), `showBaileysPairing`.
- `channel_detail/_channel_detail.dart` — `showChannelDetail(context, channel:, label:)`,
  `ChannelDetailModal`: opened by tapping a card; edits the channel **in place** with the same
  blocks, own `MoneyMethodsService`, confirm/cancel only while `ChannelFormController.dirty`.
  Rereads the grid itself; returns nothing.
- `channel_detail/channel_identity.dart` — `ChannelIdentity`: card header from the list row (icon, network, scope, `ChannelStateTag`).
- `channel_detail/channel_account.dart` — `ChannelAccount`: provider account id + channel id, selectable.
- `channel_detail/channel_danger.dart` — `ChannelDanger`: unlink WhatsApp Personal (`BaileysService.unlink`) and disconnect (`ChannelsService.remove`), each confirmed.
- `channel_detail/edit_bar.dart` — `ChannelEditBar`: confirm/cancel pair, absent until something differs.
- `baileys_pairing/_baileys_pairing.dart` — `showBaileysPairing(context, channelId:, initial:)`,
  `BaileysPairingModal`: QR; opened by `BaileysChannelSwitch` on `qr_pending`, closes on connect.

### `knowledge/` (from the knowledge section)
- `knowledge_form/_knowledge_form.dart` — `showKnowledgeForm(context, entry?, branches, branchesFailed)` → `KnowledgeDraft?`, `KnowledgeFormModal`: question, context (`Input(lines: 7)`), tags, branch (only with a choice), dates (checked as real days, first ≤ last), products. Writes nothing.
- `knowledge_form/knowledge_product_picker.dart` — `KnowledgeProductPicker`: picked products as chips + its own `KnowledgeProductSearch` (max 20).
- `knowledge_form/knowledge_snippets.dart` — `KnowledgeSnippets`: lines appended to the context (hours, deadline, spots, agent confirms).
- `knowledge_form/knowledge_lyra_notice.dart` — `KnowledgeLyraNotice`: head of a question Lyra left (asked by a customer, how many times).

### `supply_chain/` (from the supply chain section)
- `recipe/_recipe.dart` — `showRecipePanel(context, product)` → whether anything was written, `RecipePanel`: owns a `RecipeService`; what it makes now and the 86 switch, produce (batch) / lost dish (order), the recipe read only or in its editor, delete (says where it is used first), presentations (not on a dish made to order). Each action by its `supply_chain.recipes.*` grant.
- `recipe/recipe_editor.dart` — `RecipeEditor`: mode, lines (quantity, waste %, optional), the ingredient search; checks quantity > 0 (whole on a product for sale), 0 ≤ waste < 100, one line not optional.
- `produce_batch/_produce_batch.dart` — `showProduceBatch` → `BatchDraft?` (quantity, lost ≤ quantity, note). Writes nothing.
- `discard_dish/_discard_dish.dart` — `showDiscardDish` → `DiscardDraft?` (how many, the optional lines they went without, note). Writes nothing.
- `presentations/_presentations.dart` — `showPresentationsEditor` → `List<PresentationDraft>?` (ids kept, names not repeated). Writes nothing.
- `modifier_group/_modifier_group.dart` — `showModifierGroupForm(context, group?, canEdit)` → `ModifierGroupDraft?` (or `delete`): name, min/max, the products that offer it (named from their tables, their recipes read for removals), options. Writes nothing.
- `modifier_group/modifier_option_card.dart` — `ModifierOptionCard`, `ModifierOptionDraft` (keeps its id), `ModifierExtraDraft`: name, price, pause, extras per unit, recipe lines it removes (`showCheckMenu`).
- `shared/kitchen_product_picker.dart` — `KitchenProductPicker` (a `KitchenProductSearch` over every table, supplies first), `KitchenNote`. `shared/kitchen_chip.dart` — `KitchenChip`.

### `inventory/`
- `create_table/_create_table.dart` — `CreateTableModal`: title, description, colour; where the supply chain exists, what it holds (`KIND`: what is sold or supplies, never changed after).
- `create_field/_create_field.dart` — `CreateFieldModal`: new column.
- `rename_table/_rename_table.dart` — `RenameTableModal`.
- `edit_table_details/_edit_table_details.dart` — `EditTableDetailsModal`: **one** header datum from the settings panel.
- `edit_table_details/table_detail_field.dart` — `enum TableDetailField`: writable header data.
- `import_table/_import_table.dart` — `ImportTableModal`: **chooses a source only**, does not import.
- `import_table/source_row.dart` — `ImportSourceRow`.
- `import_pictures/_import_pictures.dart` — `showImportPictures(context)`, `ImportPicturesModal` (side panel): reads `…/import/images/status`, re-read when the counters move; downloading (server / devices), file names missing (first 30 + count) with "choose a folder" (desktop) and "upload a .zip" (not web), failures with "try again" (`retry`).
- `table_settings/_table_settings.dart` — `showTableSettings(context, tableId)`, `TableSettingsModal` (side panel over list or sheet).
- `table_settings/summary_block.dart` — `TableSummaryBlock`, `TableDatesBlock`.
- `table_settings/columns_block.dart` — `TableColumnsBlock`; `columns_table.dart` — `TableColumnsTable` (the agent
  visibility cell only where `channels` is shown).
- `table_settings/agent_block.dart` — `TableAgentBlock`: what the model sees and can do. With the channels block, only
  where `channels` is shown (`CapabilityService`).
- `table_settings/channels_block.dart` — `TableChannelsBlock`: channels reading this table (links to the channel edit page).
- `table_settings/settings_id.dart` — `TableSettingsId`: hidden id, reveal + copy.
- `table_settings/settings_format.dart` — `settingsNumber`, `settingsDate`: locale-aware formatting.
- `stock_movement/_stock_movement.dart` — `showStockMovement(...)`, `StockMovementModal` (from a stock summary stepper): a supply's decimals; on an add, the product's presentations («Bought as», the total they hold) and «Total cost» on a restock, both behind `inventory.purchases`.
- `stock_movement/movement_shape.dart` — `StockMovementShape`, `StockCounter`, `StockDirection`, `MovementDestination`, `MovementDestinationKind`.
- `stock_movement/movement_option.dart` — `MovementOption`: selectable outcome row.
- `branch_prices/_branch_prices.dart` — `showBranchPrices(context, productId:, product:, tableId:, catalogPrice:, currency:)`, `BranchPricesModal` (owns its `BranchPricesService`): each branch with its own price/offer or the catalog's; with `products.price`, the branch worked in's price and offer % (empty keeps the product's offer, 0 takes it off), save, "use the catalog's".
- `transfer_form/_transfer_form.dart` — `showTransferForm(context, service:)`, `TransferFormModal`: where it goes (the other branches), products found in the primary table's summary (`StockTransfersService.searchProducts`, free units beside each, one table per transfer), units, note; "save as draft" / "send now". Returns `createTransferRequest`.
- `receive_transfer/_receive_transfer.dart` — `showReceiveTransfer(context, transfer:, nameOf:)`, `ReceiveTransferModal`: each line opens on what was sent; one counted short asks the reason (`StockShortage`, `loss` by default). Returns `TransferCount` (only the short lines).
- `stock_movement/quantity_field.dart` — `QuantityField`: amount with step buttons (`decimals`: a supply's).

### `sales/`
- `sale_detail/_sale_detail.dart` — `showSaleDetail(context, sale:, catalog:)` →
  `Future<SaleDetailRequest?>` (`approve` · `fulfil`), `SaleDetailModal`: one sale in full. **Writes
  nothing**; the board acts on the returned request after it closes. Owns a fresh
  `SaleDetailService` per opening; header drawn from the row so it shows before the read.
- `sale_detail/detail_identity.dart` — `SaleDetailIdentity`: customer, number · code, stage tag, wait, plus
  the one `action` button (approve if `canApprove`, else fulfil if `canFulfil`), handed in built.
- `sale_detail/detail_proof.dart` — `SaleDetailProof`: the payment proof(s) the customer sent,
  newest first — picture (→ `showImageViewer`), document (→ `launchUrl`), or text; lost image says
  so. `belongsTo(sale)`: only sales with a conversation.
- `sale_detail/detail_money.dart` — `SaleDetailMoney`: units, subtotal, tax (per-rate breakdown),
  total, method/reference, collected/owed when `payment.hasBalance`, `due` (charged apart), `received` (each approval). Backend figures only; missing = words,
  never `0`. Two figures per line (`_MoneyGrid`), one column under `AppSize.action * 6`.
- `sale_detail/detail_items.dart` — `SaleDetailItems`: line count + button to `showSaleItems`, plus
  rows for lines no longer sold / `isUnheld`.
- `sale_detail/detail_handover.dart` — `SaleDetailHandover` (mode, state, when, by whom, `stored`)
  and `SaleDetailHolds` (only when `reservations` != null). Read-only.
- `sale_detail/detail_trace.dart` — `SaleDetailTrace`: channel, till/bot, seller, contact, note, timestamps, id. Absent facts not drawn.
- `sale_items/_sale_items.dart` — `showSaleItems(context, sale:)`, `SaleItemsModal`: every line,
  **stacked** on the detail panel; `ListView.builder`; local search (name/code) past eight lines.
- `sale_items/item_line.dart` — `SaleItemLine`: qty, product, price, amount + shelf tags (gone, held, left, unheld).
- `sale_fulfillment/_sale_fulfillment.dart` — `showSaleFulfillment(context, sale:, modes:)`,
  `SaleFulfillmentModal`: handover mode/state. **Returns `fulfilSaleRequest`**. State picker only
  after a mode; sends only what changed (no-diff submit refused).

### `deliveries/` (from the deliveries desk)
- `delivery_settings/_delivery_settings.dart` — `showDeliverySettings(context)` ("Select delivery area" only closes it:
  the areas are on the desk), `DeliverySettingsModal`: side panel, **owns its `BusinessDeliveryService`**.
- `delivery_settings/settings_body.dart` — `DeliverySettingsBody({onArea})`: reads the service; owns every write the blocks
  and the panels stacked on it ask for. Order: delivery, ways you deliver, pickup.
- `delivery_settings/delivery_settings.dart` — `DeliverySettingsBlock`: delivers (three-state `SettingsSelect` + `showSelectMenu`)
  with "Select delivery area" beside it (`onArea`), fixed/flexible areas (`meeting`, two-state), the delivery note;
  `DeliveryPickupBlock`: pickup (three-state). Rows: `delivery_flag_field.dart` — `DeliveryFlagField`,
  `delivery_meeting_field.dart` — `DeliveryMeetingField`, `delivery_area_button.dart` — `DeliveryAreaButton`.
- `delivery_settings/delivery_options.dart` — `DeliveryOptionsBlock`: the options, adding in the block title, the "turned off"
  notice. `limit = 20`. `delivery_option_field.dart` — `DeliveryOptionField`: one option, its mode/reach line and its figures
  as `SettingsTag`s (off a local reach, the branch it leaves from).
- `delivery_settings/delivery_gate.dart` — `DeliveryGate({off, child})`: fades what only holds while delivering (options,
  fixed/flexible) when `delivers == false`; still editable.
- `delivery_option/_delivery_option.dart` — `showDeliveryOptionForm(context, catalog:, currency:, option?)`,
  `DeliveryOptionFormModal`: mode → carrier → reach → figures. Carrier pickers are one per mode (their lists
  differ); radius/zones only for a local reach, the branch it leaves from only off one (with several branches, `BranchService`). Checks what the backend refuses. **Returns the create/update body.**
- `delivery_option/zone_rows.dart` — `ZoneDraft`, `ZoneRows`: a row per zone (area + its own price). Their
  controllers belong to **no** form: rows come and go, and a registered one would stay and be validated.
- `edit_delivery_notes/_edit_delivery_notes.dart` — `showDeliveryNotes(context, notes:)`,
  `EditDeliveryNotesModal`: one field. **Returns the text** (empty erases).
- `shipment/_shipment.dart` — `showShipment(context, service:, id:)`, `ShipmentModal`: one shipment of the board, following
  the desk's `ShipmentsService` row (gone = left the board); moves and the form only with `shipments.dispatch`.
- `shipment/shipment_moves.dart` — `ShipmentMoves`: a button per state of the catalog's `next` (assigned only with a carrier).
- `shipment/shipment_form.dart` — `ShipmentForm`: carrier (`showSelectMenu`: none, the branch's riders, the country's
  carriers + reference), window (the branch's franjas with room), cost, note, receiver; address + point only for a sale
  without a point of its own. Drafts follow the row until edited; one save, `editShipmentRequest`.
- `shipment/shipment_facts.dart` — `ShipmentHeading` (number, state, untouched note, customer, opens the chat on the
  messages desk), `ShipmentCarrying` (read only), `ShipmentDestinationBlock` (address, area, point, opens `maps`),
  `ShipmentMoney` (total, collect on delivery, fee, cost), `ShipmentHistory`.
- `shipping_settings/_shipping_settings.dart` — `showShippingSettings(context, service:)`, `ShippingSettingsModal`: the
  branch worked in's schedule; **owns** `ShippingSettingsService` and `OpeningHoursService`; a week or closure change
  re-measures the franjas.
- `shipping_settings/offer_preview.dart` — `OfferPreview`: what the bot would offer today and each day's franjas with room;
  no hours / no zone said in words.
- `shipping_settings/slot_settings.dart` — `SlotSettings`: span, capacity (empty = no limit), lead, days, width, checked
  against the backend's ranges; read only without `shipments.configure`.

### `messages/`
- `chat_usage/_chat_usage.dart` — `showChatUsage(context, thread:)`, `ChatUsageModal`: AI spend of the open session (total, tokens, areas that ran). Re-provides the `ChatThreadService` and rereads the detail on open. `usageCost` `usageNumber` `usageCompact`.

### `finance/`
- `record_payment/_record_payment.dart` — `showRecordPayment(context, concepts:, settlements:,
  accounts:, currency:, ticket?, amount?)`, `RecordPaymentModal`. **Returns
  `recordPaymentRequest`**. No direction (concept decides), no date (backend stamps it).
- `payment_method_form/_payment_method_form.dart` — `showPaymentMethodForm(context, rails:,
  sheets:, options:, method?)`, `PaymentMethodFormModal`: add/edit an account. Rail read-only on
  edit. Fields drawn from the rail's sheet (`MoneyMethodField`): `select` searchable by code or
  name, `document` stores the code (`SelectOption.chosen`), `format` → `AccountMask`. New rail =
  new `FormController` (`obligatory` is fixed at creation). Currency picked from `currencies:` (fixed when the
  rail has one; warns if it has no rate; not asked without a setup). Commission: none / percent (< 100) / fixed
  in the account's currency. Branch (every branch or one of `BranchService.branches`) asked only with several branches or one stored. Returns `create/updateMoneyMethodRequest`.
- `exchange_currency_form/_exchange_currency_form.dart` — `showExchangeCurrencyForm(context, main:, taken:,
  exchange?)`, `ExchangeCurrencyFormModal`: currency (fixed on edit; fiat minus main and taken), mode, custom
  rate. Returns `saveMoneyExchangeRequest` (no `RATE` when official).
- `accounting_export/_accounting_export.dart` — `showAccountingExport(context)`, `AccountingExportModal`: period (this
  month, last month, ten more months, this and last year; never typed), datasets (all but receivables by default, at
  least one), format (XLSX default, CSV). Returns `(request, name, format)`.

### `pos/`
All three **return a value and write nothing** (POS services live below this navigator).
- `pos_amount/_pos_amount.dart` — `PosAmountModal({currency})`, `PosAmountEntry`: concept + price not in the catalog.
- `pos_tax/_pos_tax.dart` — `PosTaxModal({rate})`: percentage (`16`, never `0.16`); empty = 0.
- `pos_modifiers/_pos_modifiers.dart` — `showPosModifiers(...)` → picks or null, `PosModifiersModal({groups, currency})`: each group's rule, options greyed at `available: 0`/paused, one-choice groups swap, confirm only within every `min`–`max`; prices said, never added.
- `pos_checkout/_pos_checkout.dart` — `PosCheckoutModal({methods, currency, total})`, `PosCheckoutEntry`: payment method, required reference where the method has one.

### `permissions/`
- `request_permission/_request_permission.dart` — `showRequestPermission(context, requests:, permission:, section:, business:)`, `RequestPermissionModal`:
  optional note (≤ 200); **writes** through the `PermissionRequestsService` passed in. A `409` (already pending/granted) closes it. Returns `true` if sent.

### `home/` (the shell's header)
- `pending/_pending.dart` — `showPendingPanel(context, opens:, leads:)`, `PendingModal`: every badge standing, loudest first (live),
  then "Recent notifications" (`NotificationsService.recent`, live; unseen ones bold with a filled dot). Opening it is opening
  the bell: `load` then `BadgesService.seen(["notifications.unseen"])` (in that order, or every row reads as seen), and
  `markSeen` on close; the bell's own badge is not a row. A row that `opens`/`leads` returns its `BadgeModel` or
  `NotificationModel` (the header navigates); dismissible badges (not the terms: no terms page yet) get "Dismiss" /
  "Mark as read" (`BadgesService.seen`). Returns the chosen one or `null`.

### `server/` (one session over the cloud and a master, plan §9.6)
- `master_password/_master_password.dart` — `showMasterPassword(context, login:)`, `showUnseal(context)`,
  `MasterPasswordModal`: the person's password on this device's master, once after an online sign in that couldn't open
  it (`HybridService.signIn`), or to open the sealed details of a session the cloud grant opened (`LanService.unseal`);
  pops whether it did; "not now".
- `link_company/_link_company.dart` — `askLinkCompany(context, force:)`, `LinkCompanyModal`: joins the master's company
  with its company online (`HybridService.link`), in plain words; one candidate is named in the title, several are
  picked, none makes it online without asking (`HybridService.createOnline`); asked once a session from the home (a "not now" is remembered), offered again from `ServerConnection` (`force`).
- `online_sign_in/_online_sign_in.dart` — `showOnlineSignIn(context)`, `offerOnlineSignIn(context)`, `OnlineSignInModal`: a session on the master alone signs
  in online as the same person (`clientService.email`, not asked): `email/verify` on opening through `SessionCloudSource`, then
  the password or the mailed code, then `HybridService.join` → `hybrid` in place, the cloud socket opened; no online account →
  sign up there (mailed code + names prefilled from the master's session, `SignUpService`); another method only says so and
  closes ("close"; "not now" otherwise). The home's own offer once per session (`_OfferOnline` → `offerOnlineSignIn`) verifies
  quietly first and opens only to sign in (password or code), never to sign up.

### `pre_start/` (welcome page)
- `invitation/_invitation.dart` — `InvitationModal({invitation})`: invitation details + "Accept invitation" `Button` (`ClientService.acceptInvitation`), pops `true` once accepted; decline not offered yet.
- `awaiting_invitation/_awaiting_invitation.dart` — `AwaitingInvitationModal`: tells the person to be invited by their account email.
- `job_openings/_job_openings.dart` — `JobOpeningsModal`: placeholder (no endpoint yet).
