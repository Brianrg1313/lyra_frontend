# Lyra

Desktop-first business console built with Flutter. Windows is the primary target; web and
mobile builds are supported.

Lyra brings a company's day-to-day into one place: an AI assistant on the home dashboard,
the business and its branches, employees and permissions, inventory and menu, AI channels and
their knowledge base, third-party connections, a live messages desk, deliveries on a map,
the sales board, finance, and a standalone point-of-sale mode. It runs against the cloud
backend or, in offline/LAN mode, against a local master device on the same network.

> **Proprietary software.** All rights reserved — see [LICENSE](LICENSE). No use, copying or
> distribution is permitted without written authorization.

## Repository layout

| Path | What it is |
|---|---|
| `lib/main.dart` | Entry point (calls `starter` from `core`). |
| `lib/toolkit/` | App wiring: api/socket clients, routes, themes, LAN client, barrel export. |
| `lib/services/` | State and backend access (`ChangeNotifier` services, models, sources). |
| `lib/screens/` | Home shell and sections, modals, authentication, pre-start, POS. |
| `lib/l10n/`, `lib/generated/` | Translations (`intl_en.arb`) and the generated `S` class. |
| `test/` | Widget and unit tests. |
| `baileys_server/` | Node.js sidecar for WhatsApp (Baileys) with a local control API. |
| `docs/` | Design and backend-contract documents (offline/LAN plan, protocol, tasks). |
| `tool/` | Developer scripts (`clean.ps1`). |

Each module has a `MODULE.md` describing its files; [`CLAUDE.md`](CLAUDE.md) holds the global
conventions.

## Requirements

- Flutter SDK with Dart `^3.9.2`
- For Windows builds: Visual Studio with the "Desktop development with C++" workload
- Node.js `>= 20` (only for `baileys_server`)
- Sibling local packages, referenced by path in `pubspec.yaml` (separate repositories):
  - `../../packages/core` — design system, navigation, api/socket, forms, tables, charts
  - `../../packages/lyra_protocol` — LAN protocol shared with the engine
  - `../../packages/lyra_node` — the master's engine (offline/LAN mode)

  `pubspec.yaml` currently points to them with absolute paths (`E:/andromeda/frontend/packages/...`);
  adjust them to your checkout if it lives elsewhere.

## Getting started

```sh
flutter pub get
flutter run -d windows
```

The development backend host is set in `lib/toolkit/backend/api.dart` (`devHost`).

### WhatsApp sidecar (optional)

```sh
cd baileys_server
cp .env.example .env      # then set CONTROL_API_KEY to a long random value
npm install
npm start
```

`.env` and `data/` (WhatsApp session state) are git-ignored and must never be committed.

## Development

```sh
flutter analyze                 # must report "No issues found!"
flutter test                    # all tests
flutter test test/<file>.dart   # a single file
.\tool\clean.ps1                # reset local app data and build cache (Windows)
```

User-facing strings live in `lib/l10n/intl_en.arb`; never edit `lib/generated/**` by hand.

## Security

- Do not commit secrets: `.env` files, keys, certificates, keystores and local data are ignored
  by `.gitignore`. Use `.env.example` as the template.
- Report vulnerabilities privately to the maintainer; do not open public issues for them.

## License

Proprietary. Copyright (c) 2025-2026 David. All rights reserved. See [LICENSE](LICENSE).
