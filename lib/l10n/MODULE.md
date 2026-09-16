# Module: i18n

**Paths** `lib/l10n` (source), `lib/generated` (output)
**Role** Every user-facing string. Nothing rendered to a user is a literal in a widget.

## Files

- `lib/l10n/intl_en.arb` — **the only file you edit.** Flat JSON, no `@` metadata. English is the
  source and only locale.
- `lib/generated/l10n.dart` — generated `S` (`S.of(context)`, `S.current`, `S.delegate`). Never hand-edit.
- `lib/generated/intl/messages_en.dart`, `messages_all.dart` — generated catalogues. Never hand-edit.

`S.delegate` / `supportedLocales` are wired in `lib/main.dart`; core's strings are bridged in
`lib/toolkit/settings/translations.dart`.

```dart
S.of(context).search                 // inside the tree
S.current.connectionError            // outside it (services, validators)
S.of(context).form_long_ma(label)    // placeholder keys become methods
```

## Adding a string

1. Add the key to `intl_en.arb`: `lower_snake_case`, feature prefix (`stock_reason_*`,
   `channel_*`, `business_*`, `form_*`, `search_*`). `{name}` placeholders make it a method taking `Object name`.
2. Regenerate — either:
   - the **Flutter Intl IDE plugin** (`flutter_intl: enabled: true` in `pubspec.yaml`), on save; or
   - `dart pub global run intl_utils:generate` (globally activated, not a dev dependency). It
     writes LF: convert the three generated files back to CRLF or they show as fully changed.
   If neither is available, say so and let the user regenerate — never hand-write `lib/generated/**`.
3. Use it via `S`.

## Rules

- No literal user-facing text in widgets — empty states, tooltips, labels and error copy included.
- Do not reuse a key across unrelated features; shared wording is not a shared key.
- Backend-provided text (provider names, error `message`/`action`) is shown as received, not translated.
