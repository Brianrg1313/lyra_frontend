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

- `_authentication.dart` — `Authentication extends PageBuilder`: provides `SignInService`.
- `desktop/_body.dart` — `DesktopBody`: `AuthPanel` on the left from 860 px wide, form column (`AuthBrand`, headline, left-aligned fields, `AuthFooter`) on the right; email only, then `email/verify` — no account or code → `/login/code`, password → inline password field; OAuth buttons (inert), terms line.
- `code/_code.dart` — `AuthCode extends PageBuilder`: provides `SignInService` + `SignUpService`; branches on `SignInService.pending().account`.
- `code/desktop/_body.dart` — `DesktopBody`: same frame as the entry (`AuthPanel(drop: false)` from 860 px, 340 px column, `AuthFooter`); back to `/login` if no pending email; account → `AuthBrand`, headline, `_SentTo` (email with "Change" → `/login`), `CodeInput` auto-submits `sign_in/code`, one status line under it (resend countdown → resend link, "signing you in" while submitting); no account → two `_Step`s, code then first/last name (`InputRow`), each marker a check once filled; a full code reveals the optional-password notice, "continue" (`MainButton`) and "continue and create a password" (`FeedbackButton` sized like `MainButton`), both `sign_up/code` + `sign_up/names`; after the cooldown, "resend code" (`FeedbackButton`, `AppSize.button` tall).
- `auth_panel.dart` — `AuthPanel`: `gradient-1.png` with the `l.png` pin cut out in the page background, dropping in once (`drop: false` skips it; reduced motion respected).
- `auth_brand.dart` — `AuthBrand`: pin + name heading the form column of the auth pages.
- `auth_footer.dart` — `AuthFooter`: bottom strip of the auth pages — copyright, privacy/terms links (no URLs yet), language picker (sets `AppController().locale`).

## Conventions

- Forms: `FormController` + `InputController`s; submit gates on `form.validate()`, button on `form.loading`.
- Every `_submit` returns early while `form.loading` is up: Enter and `CodeInput` autosubmit bypass `Button`'s own block, and a repeated request mails a new code (voiding the sent one) or reuses a consumed one (401 `invalid_code`).
- Errors: `FloatFlag.showFromError(e)`.
- Success: `Navis.pushAndClearStack(context, redirect ?? "/home")` (`redirect` = consumed deep link).
- Only `desktop/` bodies exist; a phone body branches with `DeviceSelector` in the `PageBuilder`, not inside the body.
