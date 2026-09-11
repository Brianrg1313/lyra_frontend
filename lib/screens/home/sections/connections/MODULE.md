# Module: connections section

**Path** `lib/screens/home/sections/connections`
**Role** The business's own accounts on outside services: what gets connected, with which
credentials, and what jobs it can then be put on. Content of the `connections` home
section plus its create/edit sub-page.
**Services** `ConnectionsService` (list/detail/writes), `ConnectionCatalogService`
(providers, their fields and scopes) — `lib/services/connections`.

## Routing

- `/home/connections` — the section (the list).
- `ConnectionFormSection.createRouteKey` → `/home/connections/new` (declared **before**
  the `:id` route).
- `ConnectionFormSection.editRouteKey` → `/home/connections/:id`.
- Both: `parents: ["connections"]`, `shell: Home.shell`.

## Files

- `_connections.dart` — `ConnectionsSection`: the list.
- `connection_row.dart` — `ConnectionListRow`: service icon, given name + state, and which
  service the account belongs to.
- `connection_state_tag.dart` — `ConnectionStateTag`.

### form/

Catalog-driven, exactly like the channel form: the provider declares its fields.

- `_connection_form.dart` — `ConnectionFormSection`.
- `state/connection_form_controller.dart` — `ConnectionFormController` + `ConnectionFormStatus`.
- `blocks/provider_picker.dart` — `ProviderPicker`: first block, decides the rest.
- `blocks/credentials_block.dart` — `CredentialsBlock`: fields from
  `ConnectionProviderField` / `ConnectionFieldType`.
- `widgets/form_block.dart` — `FormBlock`.
- `widgets/option_card.dart` — `OptionCard`.
- `widgets/option_grid.dart` — `OptionGrid`.
- `widgets/missing_banner.dart` — `MissingBanner`.

## Note

Deliberately parallel to `sections/channels/form`, not shared with it: a connection is an
account the business owns, a channel is a place it answers on. Do not refactor them into
one set of widgets.
