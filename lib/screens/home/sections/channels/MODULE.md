# Module: channels section

**Path** `lib/screens/home/sections/channels`
**Role** AI channels: networks the business answers on, what each knows and can do. Content of
the `channels` home section plus its edit sub-page.
**Services** `ChannelsService`, `ChannelCatalogService` (`lib/services/channels`).
**Other entry points** Create: `lib/screens/modals/channels/create_channel`. Detail/edit in
place: `lib/screens/modals/channels/channel_detail`. Both reuse this module's `form/` controller and blocks.

## Routing

- `/home/channels` — header + grid.
- `ChannelFormSection.editRouteKey` → `/home/channels/:id`, `parents: ["channels"]`,
  `shell: Home.shell`. Linked from `TableChannelsBlock` and by URL; the grid's cards open the detail panel instead.

## Files

Channels have no name/description: a card is identified by network and data source.

- `_channels.dart` — `ChannelsSection`: header ("connect channel") over `ChannelGrid`.
- `channel_list/_channel_list.dart` — `ChannelGrid`: loading/error/empty + grid.
- `channel_list/channel_grid_view.dart` — `ChannelGridView`: the grid; asks `BaileysService` for the WhatsApp Personal channels' state when the set changes.
- `channel_list/channel_card.dart` — `ChannelCard`: icon + network, scope, pending tag, tables it
  answers from **by name** (`ChannelCardSources`, `channel_card_sources.dart`), enable switch (`ChannelEnabledSwitch`, `channel_enabled_switch.dart`). Tap → `showChannelDetail`.
- `channel_list/channel_state_tag.dart` — `ChannelStateTag`.
- `channel_list/baileys_channel_switch.dart` — `BaileysChannelSwitch`: switch for WhatsApp
  Personal; starts/stops the `baileys_server` session (`BaileysService`) instead of `ENABLED`;
  colour/tooltip show `BaileysSessionState`; `qr_pending` → `showBaileysPairing`.

### form/ — catalog-driven; nothing network-specific is hardcoded

- `_channel_form.dart` — `ChannelFormSection`: the edit page (edit-only), resolves `:id`.
- `state/channel_form_controller.dart` — `ChannelFormController` + `ChannelFormStatus`: state and
  submit. `SCOPE`, `ROLE`, `TABLES`, `PAYMENT_METHODS` top-level (`payload()`); data-source category
  round-trips through `SETTINGS`. `dirty` compares against the channel as read (not core's
  `isEdited`); `settle()`, `revert()`.
Every block is one `ChannelFormRow` (label left, controls, one note); single choices note only the chosen option.

- `blocks/provider_picker.dart` — `ProviderPicker`: first block, `NetworkTile`s. On create: configurable,
  single-scope providers only (no scope picker yet → no Facebook/Instagram), plus one whose scope a
  preset fixed (`ChannelFormController.applyPreset`/`scopeOf`); WhatsApp Personal first. Note: the chosen network's capabilities.
- `blocks/credentials_block.dart` — `CredentialsBlock`: provider fields (`widgets/channel_credential_field.dart` — `ChannelCredentialField`, its backend hint shown only while focused); for WhatsApp Personal a QR notice.
- `blocks/agent_picker.dart` — `AgentPicker`: chips, seller / support / agent (3 of the backend's 6 `ROLE`s; others fall back to `general`).
- `blocks/data_picker.dart` — `DataPicker`: `ChannelDataSource` filtered by role
  (`allowedFor`); a role change corrects the source (`_syncSource`). No tables → the `field.table` dot on its note.
- `blocks/payment_picker.dart` — `PaymentPicker`: multi-select over `MoneyMethodsService.methods`
  (none is valid). Each host provides its own `MoneyMethodsService`. No accounts → points to finance, with the `field.payment_method` dot.
- `blocks/tools_picker.dart` — `ToolsPicker`: `ChannelTool` chips (voice, image, video, documents); note: the cost.
- `widgets/form_row.dart` — `ChannelFormRow` (label beside the controls, above them under `action * 9`; same tree either way), `ChannelFormNote`.
- `widgets/option_chip.dart` — `OptionChip` (button-tall choice; `multiple` swaps the icon for a check), `OptionChips` (wrap).
- `widgets/network_tile.dart` — `NetworkTile`: the network's large square tile.
- `FormBlock`, `OptionCard`, `OptionGrid` (`sections/_section/form/`, home module): connections and `ChannelAccount` only.
- `widgets/data_table_select.dart` — `DataTableSelect` (the data picker's table select); `widgets/payment_picker_note.dart` — `PaymentPickerNote`.
- `widgets/missing_banner.dart` — `MissingBanner`: what the channel still needs.

## Note

`connections/` mirrors `form/` file-for-file. **Intentional duplicates**: the two catalogs
describe different things; do not merge them.
