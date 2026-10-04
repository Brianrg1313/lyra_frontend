# Module: auth (sign in + sign up)

**Path** `lib/screens/authentication` (entry page at the root; `code/` holds the code step of both flows)
**Role** Getting in. One email-only entry; `email/verify` branches to sign in or sign up.
**Services** `SignInService`, `SignUpService` — **flow-scoped**: each page provides its own
(`Provider(create: ...)`), not in `initial_builder.dart`.

## Routes (no `shell`: each is its own Navigator page)

| key | url | notes |
|---|---|---|
| `login` | `/login` | the auth entry (sign in and sign up) |
| `auth_code` | `/login/code` | `parents: ["login"]`; after `email/verify` sends a code (`account: false`, or `account: true, method: code`) |

## Files

- `_authentication.dart` — `Authentication extends PageBuilder`: a browser on a master's page → `AuthMaster` while `LanService` is signed out (opens it when idle; any other state → `/lan`), no scan; otherwise provides `SignInService` and a watching `NetworkScanService` (`scan` seam); loading, then the backend answers → the stored session first (`resume` seam: `HybridService.resume` then `ClientService.resolve`, once: a route enters, `/login` draws the form) → `DesktopBody` (`Deployment.online`, paired or not); no backend on a paired device, or on a computer whose engine is set up but the app forgot it (`masterHere` → `Deployment.attach`; `/lan` enrolls the app again) → that same master gate (`Deployment.offline`); a master on the LAN → `AuthLan` (sign in); neither and `canHost` → `AuthLan` (create), whose "Create Master Server" swaps the page for the master setup body (`pre_start`, `owner` = the e-mail and password, "back" returns); neither → `AuthOffline`. The scan runs while the page lives (the backend live over `CloudPresence`, the LAN every 15 s), so the internet going or coming back swaps the online and offline sign in in place; a submit in flight holds it (`DesktopBody`, `AuthMaster`), and the gate keeps what it drew while `/login/code` covers it.
- `auth_hybrid.dart` — `joinMaster(context, login, password?)`: after an online sign in, the master's session too
  (`HybridService.join`); `needsPassword` → `showMasterPassword`. The password body passes the password, the code body
  (sign in only, not sign up) none.
- `auth_master.dart` — `AuthMaster`: a paired device's sign in in the cloud's steps: e-mail (or username) → "continue" → `LanService.needsActivation` (`auth.identify`) → the password under it, or the activation code and a new password (`LanService.activate`); refusals under the fields; `ready` is the page's to act on.
- `auth_frame.dart` — `AuthFrame`: the page every sign in draws on (`AuthPanel` from 860 px, 340 px form column, `AuthFooter`).
- `auth_lan.dart` — `AuthLan`: the sign in without the backend, in the cloud form's frame: e-mail + password (a server picker only with several masters); with masters, `LanPairingService.pairWithPassword` then `LanService.open` + `signIn` → `/lan` (`enter` seam), the scan held meanwhile; without, "Create Master Server" (`onCreate`, 10-character password first); "search again".
- `desktop/_body.dart` — `DesktopBody`: in `AuthFrame` (`AuthBrand`, headline, left-aligned fields); email only, then `email/verify` — no account or code → `/login/code`, password → inline password field; OAuth buttons (inert), terms line.
- `code/_code.dart` — `AuthCode extends PageBuilder`: provides `SignInService` + `SignUpService`; branches on `SignInService.pending().account`.
- `code/desktop/_body.dart` — `DesktopBody`: same frame as the entry (`AuthPanel(drop: false)` from 860 px, 340 px column, `AuthFooter`); back to `/login` if no pending email; account → `AuthBrand`, headline, `_SentTo` (email with "Change" → `/login`), `CodeInput` auto-submits `sign_in/code`, one status line under it (resend countdown → resend link, "signing you in" while submitting); no account → two `_Step`s, code then first/last name (`InputRow`), each marker a check once filled; a full code reveals the optional-password notice, "continue" (`MainButton`) and "continue and create a password" (`FeedbackButton` sized like `MainButton`), both `sign_up/code` + `sign_up/names`; after the cooldown, "resend code" (`FeedbackButton`, `AppSize.button` tall).
- `auth_panel.dart` — `AuthPanel`: `gradient-1.png` with the `l.png` pin cut out in the page background, dropping in once (`drop: false` skips it; reduced motion respected).
- `auth_brand.dart` — `AuthBrand`: pin + name heading the form column of the auth pages.
- `auth_offline.dart` — `AuthOffline`: no backend, no master, and no master possible here (web, phones): `AuthBrand`, title, message, "try again" (looks again), `AuthFooter`.
- `auth_footer.dart` — `AuthFooter`: bottom strip of the auth pages — copyright, privacy/terms links (no URLs yet), language picker (sets `AppController().locale`).

## Conventions

- Forms: `FormController` + `InputController`s; submit gates on `form.validate()`, button on `form.loading`.
- Every `_submit` returns early while `form.loading` is up: Enter and `CodeInput` autosubmit bypass `Button`'s own block, and a repeated request mails a new code (voiding the sent one) or reuses a consumed one (401 `invalid_code`).
- Errors: `FloatFlag.showFromError(e)`.
- Success: `Navis.pushAndClearStack(context, redirect ?? "/home")` (`redirect` = consumed deep link).
- Only `desktop/` bodies exist; a phone body branches with `DeviceSelector` in the `PageBuilder`, not inside the body.
