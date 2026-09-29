# Task: harden the WhatsApp sidecar's credentials

**Scope** `baileys_server` + `lib/services/baileys/baileys_service.dart`. No backend change.
**Origin** Security review of 2026-09-28 (session access), finding 6.

## Problem

`baileys_server` holds the desktop app's own user session to act on its behalf
(`src/backend/credentials.js`, pushed with `PUT /backend`). Three weaknesses:

1. **Token in clear text on disk.** `data/backend.json` stores the session token as plain JSON.
   Its "user-only" file mode is a POSIX mode, which Node ignores on Windows (the primary target),
   so any process or user able to read the data folder gets a working session. The WhatsApp auth
   folders under `data/sessions/` are in the same situation and are more sensitive still.
2. **Token outlives the session.** `ClientService` signs out by calling `DELETE /backend`
   (`BaileysService.signOut`). If the sidecar is down at that moment, `backend.json` keeps the
   token and the sidecar resumes with it on its next boot. Harmless only if the backend logout
   succeeded; not when it failed or the session expired on its own.
3. **Non-constant-time key check.** `src/control/auth-middleware.js` and `src/control/events.js`
   compare `CONTROL_API_KEY` with `!==`. Low risk (localhost only, 256-bit key), trivial to fix.

## Work

- [ ] **Restrict the data folder.** When `DATA_DIR` is created (and on every boot, idempotently),
      on Windows drop inherited ACLs and grant only the current user:
      `icacls <DATA_DIR> /inheritance:r /grant:r "%USERNAME%:(OI)(CI)F"`. Covers `backend.json`
      and `sessions/`. Log a warning (do not crash) if `icacls` fails.
- [ ] **Encrypt `backend.json` at rest** with Windows DPAPI (`CryptProtectData`, current-user
      scope), e.g. `@primno/dpapi`. Keep plain JSON only on non-Windows dev machines, behind the
      file mode it already sets. Reading a file written before the change: treat as plain JSON
      once, rewrite it encrypted.
- [ ] **Wipe credentials on rejection.** In `src/backend/client.js` / `src/backend/socket.js`,
      a `401` with `action: "login"` (or a handshake rejected with it) clears the credentials
      (`Credentials` → delete `backend.json`), stops the backend link and reports
      `backendConfigured: false` on `/health`. The WhatsApp sessions keep running.
- [ ] **Clear on the app side at startup.** In `BaileysService`, when the app starts with no
      session (`ClientService.resolve()` ended on `/login`) and the sidecar answers `/health`
      with `backendConfigured: true`, call `DELETE /backend`.
- [ ] **Constant-time key check.** Replace `!==` with a helper: equal lengths, then
      `crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b))`. Use it in both places.
- [ ] **Docs.** Update `baileys_server/MODULE.md` (credentials at rest, wipe on 401) and
      `lib/services/MODULE.md` (`BaileysService` startup clear).

## Done when

- `backend.json` is not readable as plain text on Windows, and `data/` is not readable by
  another Windows user.
- Signing out with the sidecar stopped, then starting the app, leaves no `backend.json`.
- Revoking the session in the backend makes the sidecar drop its credentials without the app.
- `flutter analyze` is clean; `flutter test` shows only the known failures.
