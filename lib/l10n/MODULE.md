# Module: i18n

**Paths** `lib/l10n` (source), `lib/generated` (output)
**Role** Every user-facing string. Nothing rendered to a user may be a literal in a widget.

## Files

- `lib/l10n/intl_en.arb` — **the only file you edit.** Flat JSON, ~1120 keys, no `@`
  metadata blocks. English is the source locale; it is currently the only one.
- `lib/generated/l10n.dart` — generated `S` class (`S.of(context)`, `S.current`,
  `S.delegate`). **Never hand-edit.**
- `lib/generated/intl/messages_en.dart`, `messages_all.dart` — generated message
  catalogues. **Never hand-edit.**

## Usage

```dart
S.of(context).search            // inside the widget tree
S.current.connectionError       // outside it (services, validators)
S.of(context).form_long_ma(label)   // placeholder keys become methods
```

`S.delegate` and `S.delegate.supportedLocales` are wired in `lib/main.dart`; core's own
strings are bridged in `lib/toolkit/settings/translations.dart`.

## Adding a string

1. Add the key to `lib/l10n/intl_en.arb`. Keys are `lower_snake_case`, grouped by feature
   prefix (`stock_reason_*`, `channel_*`, `business_*`, `form_*`, `search_*`).
   Placeholders use `{name}` and turn the getter into a method taking `Object name`.
2. Regenerate. This repo's generator is the **Flutter Intl IDE plugin**
   (`flutter_intl: enabled: true` in `pubspec.yaml`), which runs automatically when the
   `.arb` is saved in IntelliJ/VS Code. `intl_utils` is **not** a dev dependency, but it is
   globally activated on this machine, so `dart pub global run intl_utils:generate` is the
   same generator from the shell. It writes LF while the repo is CRLF — convert the three
   generated files back afterwards, or the whole file shows up as a diff. If neither the
   plugin nor the global package is available, say so and let the user regenerate rather
   than hand-writing into `lib/generated/**`.
3. Use it via `S`.

## Rules

- No literal user-facing text in widgets, ever — including empty states, tooltips,
  button labels and error copy.
- Do not reuse a key across unrelated features; a shared wording is not a shared key.
- Backend-provided text (provider names, error `message`/`action`) is shown as received
  and is not translated here.
