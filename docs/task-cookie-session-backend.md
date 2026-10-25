# Task: cookie session for the web client (backend side)

**Scope** Backend (`E:/andromeda/backend/projects/lyra` and its `core` package). The frontend side
is done and waits behind a build flag.
**Origin** Security review of 2026-09-28, finding 3: on web the session token sits in browser
storage (`flutter_secure_storage` has no OS vault there), so any XSS on the page can steal it.

## What the frontend already does (flag on)

Enabled with `flutter build web --dart-define=LYRA_COOKIE_SESSION=true`
(`useCookieSession` in `lib/toolkit/backend/api.dart`). Desktop is never affected.

- Every REST request and the socket handshake go out **with credentials** (`fetch` with
  `credentials: "include"`, socket.io `withCredentials`), so the browser sends and stores cookies
  for the api origin.
- Every REST request carries the header **`session: cookie`**.
- It sends **no `Authorization` header** and no `auth.token` on the socket.
- A sign in / sign up response's token, if any, is **ignored**; nothing is stored.
- Cold start always calls `GET /init/`; `401` + `action: "login"` → `/login`.
- Sign out calls `POST /authentication/logout/` and, if that fails (other than an already
  rejected session), **stays signed in** and shows an error: only the backend can clear the cookie.

## Contract the backend must meet

1. **Issue the cookie.** When a request carries `session: cookie`, the routes that open a session
   (`email/sign_in/password`, `email/sign_in/code`, `email/sign_up/names`, and
   `two_factor/verify` once it exists) answer with:
   `Set-Cookie: <name>=<token>; HttpOnly; Secure; SameSite=<see 5>; Path=/; Max-Age=<session TTL>`
   and **omit the token from the body** (keep `two_factor` etc.). `sign_up/names` answers a
   non-token value (e.g. `true`); the client does not read it in this mode.
2. **Read the cookie.** `validate_session` takes the token from `Authorization` first, then from
   the cookie. Same for the socket handshake (`validate_session` socket middleware /
   `SocketContext`: parse `handshake.headers.cookie`). Everything downstream
   (`context.bearer`, `validate_request`, revocation) stays as is.
3. **Clear the cookie.** `POST /authentication/logout/` answers
   `Set-Cookie: <name>=; Max-Age=0; Path=/; HttpOnly; Secure; SameSite=...` besides closing the
   session. A `401` from `validate_session` should clear it too.
4. **CORS with credentials.** `servers/express.js` uses `cors()` (origin `*`) and sockets use
   `cors: { origin: "*" }`; browsers refuse cookies with a wildcard. Use an **explicit allow-list**
   of web origins (env var), `credentials: true`, and add `session`, `device`, `business_id`,
   `Authorization`, `Accept-Language` to `Access-Control-Allow-Headers`. Same for socket.io.
5. **SameSite.** App and api on the same site (e.g. `app.x.com` / `api.x.com`): `SameSite=Strict`.
   Different sites: `SameSite=None; Secure` is required, and then CSRF rests on 6.
6. **CSRF.** Reject cookie-authenticated requests without the custom `device` header (a
   cross-site form cannot send custom headers, and the preflight blocks script-sent ones from
   origins outside the allow-list). No state change on `GET`.
7. **HTTPS.** `Secure` cookies need HTTPS; for local dev over http, drop `Secure` only when
   `NODE_ENV=development`, and use `SameSite=Lax` with app and api on `localhost`.

## Done when

- Web build with the flag: sign in, reload (still signed in), sign out, reload (on `/login`).
- `document.cookie` and browser storage hold no session token.
- A request from a non-allow-listed origin gets no CORS credentials.
- Desktop (no flag, `Authorization` header) works unchanged.
- Then make the flag the default for web builds (or remove it) in `lib/toolkit/backend/api.dart`.
