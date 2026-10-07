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

- `_connections.dart` — `ConnectionsSection`: the list. `connections_body.dart` — `ConnectionsBody` (the only listener of
  `ConnectionsService`: loading, error, empty, list); `connections_list.dart` — `ConnectionsList` (re-filtered by the search only).
- `connection_row.dart` — `ConnectionListRow`: service icon, given name + state, owning service.
  `connection_options_button.dart` — `ConnectionOptionsButton` (the row's menu).
- `connection_state_tag.dart` — `ConnectionStateTag`.
- `form/_connection_form.dart` — `ConnectionFormSection` (create + edit). Catalog-driven.
- `form/state/connection_form_controller.dart` — `ConnectionFormController` + `ConnectionFormStatus`.
- `form/blocks/provider_picker.dart` — `ProviderPicker`: first block, decides the rest.
- `form/blocks/credentials_block.dart` — `CredentialsBlock`: `ConnectionProviderField` / `ConnectionFieldType`
  (`form/widgets/connection_credential_field.dart` — `ConnectionCredentialField`).
- `form/widgets/missing_banner.dart` — `MissingBanner`. `FormBlock`, `OptionCard`, `OptionGrid`: shared with channels, in `sections/_section/form/` (home module).

## Note

Deliberately parallel to `sections/channels/form`, not shared: a connection is an account the
business owns, a channel is where it answers. Do not merge them.
