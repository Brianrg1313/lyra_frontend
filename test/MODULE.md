# Module: tests

**Path** `test` (flat, 101 files, `<subject>_test.dart`)
**Run** `flutter test` · `flutter test test/<file>_test.dart`
**Baseline** 883 tests, **3 known failures** (bottom). `flutter analyze` must be clean (see `CLAUDE.md`).

Pure logic and small widgets, not whole screens. **No test may hit the network.** Each file's
`///` header states the rule it pins and why — read it before changing the test.

## Map

| Area | Files | Pins |
|---|---|---|
| Sheet state | `sheet_columns` `sheet_dates` `sheet_drafts` `sheet_hover` `sheet_keys` `sheet_metrics` `sheet_widths` `sheet_zebra` `field_edit` `field_options` `field_type` `free_columns` `column_drag` `column_order` `row_cache` `table_paging` | Rules the inventory spreadsheet runs on. |
| Sheet cells | `date_cell` `image_cell` `listed_cell` `sku_cell` `unit_cell` `gutter_cell` | Cell rendering by field type. |
| Inventory contracts | `table_request` `field_request` `record_request` `table_records` `table_structure` `table_detail` `table_normalize` `table_normalizing` `table_ready` `product_date` `product_image` `sku_generator` `sku_generate` `import_file` | Payloads built/parsed exactly as the backend expects. |
| Inventory UI | `table_list_cards` `sticky_bar` `table_import_lock` `import_source_modal` `table_settings_columns` `table_settings_summary` `stock_summary` `stock_movement` | List cards, import lock (a table still importing does not open), settings panel blocks, stock. |
| Business | `business_profile` `business_profile_view` `business_email` `business_language` `business_header` `business_logo` `business_employees_tab` `edit_business_field` `edit_business_email` `verify_business_email` `crop_image` | Profile parse/rendering, `business_id` header on both apis, edit modals. |
| Location & delivery | `business_location` `business_location_tab` `business_places` `business_delivery` `business_delivery_tab` | A suggestion with no id is not a line and half a point is not a place, so the address search fills nothing it cannot read. Location body sends **only what changed** (`ADDRESS` and `COUNTRY` are `companies` columns other writes share); the country travels as its code, uppercased; a pasted point is a pair, a decimal comma or a map link. `delivers`/`pickup` three-state ("not set" ≠ "no"); `1,500` refused, not guessed; an edit resends the carrier only when it changed. |
| Catalogs & auth | `cdn` `country_catalog` `currency_catalog` `login_method` | `/init` catalogs, login method parse. |
| Routing & shell | `navis_links` `navis_shell` `home_sections_routing` `home_business_scope` `business_listener` `home_service_persistence` `pos_page` `connection_rebind` | URLs per section/tab, business scoping, rebind only when a connection was opened. |
| Channels | `channel_card_sources` `channel_form_dirty` `channel_form_select_label` `channel_edit_bar` `channel_detail_panel` `channel_payment_methods` | Card names its tables; `dirty` is a comparison; select gets its label (no mid-build write); unlink only for WhatsApp Personal; `PAYMENT_METHODS` always travels. |
| POS | `pos_catalog` `pos_invoice` `pos_ticket` `pos_ticket_sync` `pos_amount_modal` | Invoice → panel, totals from the ticket rate, external charge/cancel/unhold. Seams `PosInvoiceService.seed`/`.receive`. |
| Sales | `sales_board` `sales_search` `sales_filters` `sales_detail` `sales_detail_panel` `sales_proof` `sales_approve` `sales_money_layout` `sales_items_panel` | Tabs = `SECTION`; nulls kept; `sale/progress` effects; detail parse nulls; proof from file; approval by conversation; money grid; items virtualized. Seams `SalesService.seed`/`.receive`. |
| Money | `finance_tabs` `payment_method_form` `account_mask` `money_bot_spend` `finance_bot_block` `finance_overview_layout` | Tabs carry no id; request bodies (no `DIRECTION`, blanks/`null`, no rail on edit); rail-driven form; mask; bot spend areas and rendering. |
| Core rules | `select_menu` `table_frozen_band` | Dropdown height cap; frozen band width includes its divider (else 1 px overflow in every table). |

`_scratch_create_table_smoke_test.dart` — scratch smoke test, not a contract.

## Harness

Widget tests initialize `AppSize` inside the tree and provide what the widget reads:

```dart
tester.pumpWidget(MaterialApp(
  home: Builder(builder: (context) {
    AppSize.instance(context);
    return MultiProvider(providers: [...], child: const WidgetUnderTest());
  })
));
```

Services are used directly and reset in `tearDown` (e.g. `tearDown(() => useBusiness(null))`).
Seed instead of calling HTTP (`BusinessService().seed(table)`, `SalesService.seed`, …).

## Conventions

- One file per behaviour, named after the unit, not the screen. `///` header on the file.
- English only; translate Spanish test names/comments in any file you touch.
- A rule change updates its test in the same change.
- A test whose premise is outdated is **rewritten to pin what is true now** — never deleted or
  weakened to green. Read the production `///` docs first to decide which side is stale.

## Known failures (pre-existing)

Layout/colour assertions the design has moved past; each needs a decision on which side is stale.

- `image_cell_test.dart` — the cell should stay square in a wide column: expects side `17.5`, gets `225.5`.
- `stock_summary_test.dart` — rows should alternate zebra bands: gets `[null, null, null, null]`.
- `sheet_zebra_test.dart` — hovered and cursor rows should have their own fill: hovered row gets plain white.
