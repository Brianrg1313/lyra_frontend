# Module: connections section

**Path** `lib/screens/home/sections/connections`
**Role** The business's accounts on outside services: credentials and the jobs they can do.
Content of the `connections` home section plus its create/edit sub-page.
**Services** `ConnectionsService`, `ConnectionCatalogService` (`lib/services/connections`).

## Routing

- `/home/connections` — the list.
- `ConnectionFormSection.createRouteKey` → `/home/connections/new` (declared **before** `:id`).
- `ConnectionFormSection.editRouteKey` → `/home/connections/:id`.
- Both: `parents: ["connections"]`, `shell: Home.shell`.

## Files

- `_connections.dart` — `ConnectionsSection`: the list.
- `connection_row.dart` — `ConnectionListRow`: service icon, given name + state, owning service.
- `connection_state_tag.dart` — `ConnectionStateTag`.
- `form/_connection_form.dart` — `ConnectionFormSection` (create + edit). Catalog-driven.
- `form/state/connection_form_controller.dart` — `ConnectionFormController` + `ConnectionFormStatus`.
- `form/blocks/provider_picker.dart` — `ProviderPicker`: first block, decides the rest.
- `form/blocks/credentials_block.dart` — `CredentialsBlock`: `ConnectionProviderField` / `ConnectionFieldType`.
- `form/widgets/form_block.dart` · `option_card.dart` · `option_grid.dart` · `missing_banner.dart` — `FormBlock`, `OptionCard`, `OptionGrid`, `MissingBanner`.

## Note

Deliberately parallel to `sections/channels/form`, not shared: a connection is an account the
business owns, a channel is where it answers. Do not merge them.
