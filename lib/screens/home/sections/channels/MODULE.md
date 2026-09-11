# Module: channels section

**Path** `lib/screens/home/sections/channels`
**Role** AI channels: the networks the business answers on, what each one knows and what
it can do. Content of the `channels` home section plus its edit sub-page. Creating a
channel is not here — it is a side panel, see `lib/screens/modals/channels/create_channel`.
**Services** `ChannelsService` (list/detail/writes), `ChannelCatalogService` (providers
and their fields) — `lib/services/channels`.

Editing also happens **outside this module**, in the channel's own side panel
(`lib/screens/modals/channels/channel_detail`), which draws these same blocks. The page below is
the other entry point, not the only one.

## Routing

- `/home/channels` — the section (single panel: header + grid of channels).
- `ChannelFormSection.editRouteKey` → `/home/channels/:id`, `parents: ["channels"]`,
  `shell: Home.shell`. Opened from `TableChannelsBlock` (table settings panel) and reachable
  by direct URL. This section's own grid does **not** link to it: tapping a card opens the
  detail panel instead.

## Files

A channel no longer carries a company-given name or description: the grid identifies
each one by its network (from the catalog) and the data source it reads from.

- `_channels.dart` — `ChannelsSection`: header (title + "connect channel" button) above
  `ChannelGrid`.
- `channel_list/_channel_list.dart` — `ChannelGrid`: load states (loading/error/empty)
  and the grid layout for `ready`.
- `channel_list/channel_card.dart` — `ChannelCard`: network icon + name, scope (job)
  label, pending tag, the tables it answers from (`_Sources`, one `Surface` per table
  **by name**, not a count) and the enable/disable switch. The whole card opens
  `showChannelDetail` (`lib/screens/modals/channels/channel_detail`), which is where a channel is
  read, edited, unlinked and disconnected.
- `channel_list/channel_state_tag.dart` — `ChannelStateTag`.
- `channel_list/baileys_channel_switch.dart` — `BaileysChannelSwitch`: replaces
  `ChannelCard`'s switch for WhatsApp Personal channels. On/off starts/stops the
  `baileys_server` session (`BaileysService`, `lib/services/baileys`) instead of flipping
  `ENABLED`; the thumb color and tooltip double as the live status indicator
  (`BaileysSessionState`). Turning it on opens `showBaileysPairing` when the result is
  `qr_pending`.

### form/ — the edit page, and the blocks the create panel also reuses

The form is **driven by the catalog**: the provider decides which credential fields exist.
Nothing about a specific network is hardcoded here.

`ChannelFormController` and every block below are shared between this page and
`CreateChannelModal` (`lib/screens/modals/channels/create_channel`) — one controller/block set for
both entry points, not a duplicate per entry point. `_channel_form.dart` itself is edit-only.

- `_channel_form.dart` — `ChannelFormSection`: the edit page; resolves `:id` from the URL.
- `state/channel_form_controller.dart` — `ChannelFormController` + `ChannelFormStatus`:
  all form state and submit. No name/description any more — the backend does not require
  either. `SCOPE`, `ROLE`, `TABLES` and `PAYMENT_METHODS` are real backend fields sent
  top-level (see `payload()`); the data-source category (table / calendar / knowledge base)
  has no backend column of its own and still round-trips through `SETTINGS`. `TABLES`,
  `TOOLS` and `PAYMENT_METHODS` are pickers: each replaces its whole selection, so an empty
  `PAYMENT_METHODS` is "offer no way to pay" and travels. Also `dirty` / `settle()` /
  `revert()`: `dirty` compares a snapshot of every editable value against the channel as
  read (not core's `isEdited`, which never goes back down), which is what the detail
  panel's confirm/cancel pair listens to.
- `blocks/provider_picker.dart` — `ProviderPicker`: first block; the choice determines
  every block after it. On create, filtered to providers this app can configure **and**
  that declare a single scope (`SCOPE` is required and there is no scope picker yet) —
  Facebook/Instagram are left out until one exists. Also shows "WhatsApp Personal" first,
  always selectable — see `ChannelProviderModel.whatsappPersonal()`.
- `blocks/credentials_block.dart` — `CredentialsBlock`: fields declared by the provider
  (`ChannelProviderField` / `ChannelFieldType`). For WhatsApp Personal (no fields) it shows
  a notice pointing at the channel list's switch instead of an empty box — pairing is a QR
  scan, not something typed here.
- `blocks/agent_picker.dart` — `AgentPicker`: `ChannelAgentRole` (seller / support / agent
  — three of the backend's six `ROLE` codes; unoffered ones fall back to `general`).
- `blocks/data_picker.dart` — `DataPicker`: `ChannelDataSource` (product table, services
  calendar, knowledge base), **filtered by the chosen role**
  (`ChannelDataSource.allowedFor`) — a seller gets product data, support/general agents
  only get the knowledge base. Picking a role that no longer allows the current source
  corrects it on its own (`ChannelFormController._syncSource`).
- `blocks/payment_picker.dart` — `PaymentPicker`: which of the company's payment accounts
  this channel may give a customer, multi-select over `MoneyMethodsService.methods`. None is
  the default and a legitimate answer — not every account a company charges through is
  public. The service is **not** app-wide: each form host (create panel, detail panel, edit
  page) owns an instance and provides it, because the accounts are the active company's and
  a modal route sits above the finance section's providers. With no accounts it points at
  the finance section instead of drawing an empty grid.
- `blocks/tools_picker.dart` — `ToolsPicker`: `ChannelTool` (voice, image, video, documents).
- `widgets/form_block.dart` — `FormBlock`: title + explanation + content.
- `widgets/option_card.dart` — `OptionCard`: a selectable option.
- `widgets/option_grid.dart` — `OptionGrid`: lays options out in the columns that fit.
- `widgets/missing_banner.dart` — `MissingBanner`: what the channel still needs to work.

## Note

`connections/` mirrors this structure file-for-file (`form_block`, `option_card`,
`option_grid`, `missing_banner`, `provider_picker`, `credentials_block`). They are
**intentional duplicates**, not shared code: the two catalogs describe different things.
Change one only when the change is really about that domain.
