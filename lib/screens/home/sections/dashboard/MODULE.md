# Module: dashboard section

**Path** `lib/screens/home/sections/dashboard`
**Role** The home (`/home`): the assistant's chat on 3/5 (GenUI, `package:genui`), summary cards on 2/5.
**Services** `AssistantService` (`lib/services/assistant`), created by `AssistantPanel`, not app-wide.
**Backend** none yet: answers come from `AssistantDemoSource`, the cards from `_Sample` (placeholders).

## Invariants

- `package:genui` exports a `Surface` widget that clashes with `core`'s: always import it `as genui`.
- The model learns the catalog's names and properties (`LyraCatalog`, id `lyra.catalog.v1`); the demo source writes
  the same id. Renaming an item or a property breaks every prompt and stored answer that used it.
- A surface's `navigate` event (`context.path`) only navigates; every other event is the person's next turn.
  The controller's error reports are logged, never answered (answering would loop on a broken surface).

## Files

- `_dashboard.dart` — `DashboardSection`: `Row` of `AssistantPanel` (flex 3) and `SummaryPanel` (flex 2).
- `assistant/_assistant.dart` — `AssistantPanel`: owns and provides `AssistantService` (catalog, `Navis.navigate`); bar (orb, name, "Preview", new chat), welcome or thread, composer; content capped at `AssistantPanel.maxWidth`. `_Thread` follows the answer unless scrolled up.
- `assistant/assistant_welcome.dart` — `AssistantWelcome({onAsk})`: orb, title, suggestion cards sent as typed.
- `assistant/assistant_orb.dart` — `AssistantOrb({size, active})`: the assistant's turning gradient mark; faster and breathing while active.
- `assistant/assistant_turn_view.dart` — `AssistantTurnView({turn})`: user bubble (or a pressed control's label), answer with orb, its parts in order (`AssistantMarkdown` / `genui.Surface`), thinking shimmer, footer (copy, stopped/failed).
- `assistant/assistant_markdown.dart` — `AssistantMarkdown(text)`: `flutter_markdown_plus` with `core`'s sizes and colours, selectable.
- `assistant/assistant_composer.dart` — `AssistantComposer` (state `AssistantComposerState.focus()`): `Input` (Enter sends), attach and dictate (coming soon), send/stop.
- `assistant/catalog/lyra_catalog.dart` — `LyraCatalog.build()`: GenUI `Column`/`Row` + `Text Card Divider Button Metric Progress Item`, drawn with `core`.
- `summary/_summary.dart` — `SummaryPanel`: sales today (`StatTile`), counts (messages, online, deliveries, sales in process), subscription usage, low stock; each opens its section. `_Sample` holds every figure.
- `summary/summary_card.dart` — `SummaryCard({icon, title, child, trailing?, onMore?})`, `SummaryIcon`, `SummaryTile({icon, value, label, caption?, color?, live, onTap?})`.
- `widgets/usage_bar.dart` — `UsageBar({label, value, color, caption?})`: labelled 0–1 bar (catalog `Progress`, usage, stock).
