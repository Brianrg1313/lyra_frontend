# Module: auth (login + sign up)

**Paths** `lib/screens/login`, `lib/screens/sign_up`
**Role** Getting in. Two flows, each with a second step.
**Services** `SignInService`, `SignUpService` — **flow-scoped**: each page provides its own
(`Provider(create: ...)`), not in `initial_builder.dart`.

## Routes (no `shell`: each is its own Navigator page)

| key | url | notes |
|---|---|---|
| `login` | `/login` | |
| `sign_in_code` | `/login/code` | `parents: ["login"]`; only after the backend says the account uses an emailed code |
| `sign_up` | `/sign_up` | |
| `verify_code` | `/verify_code` | `parents: ["sign_up"]` |

## Files

- `login/_login.dart` — `Login extends PageBuilder`: provides `SignInService`.
- `login/desktop/_body.dart` — `DesktopBody`: email/password form; resolves `LoginMethod`
  first — emailed code → send + push `/login/code`.
- `login/code/_code.dart` — `SignInCode extends PageBuilder` (code already sent).
- `login/code/desktop/_body.dart` — `DesktopBody`: `CodeInput` + verify.
- `sign_up/_sign_up.dart` — `SignUp extends PageBuilder`: provides `SignUpService`.
- `sign_up/desktop/_body.dart` — `DesktopBody`: first/last name, email; link to `/login`.
- `sign_up/verify_code/_verify_code.dart` — `VerifyCode extends PageBuilder`.
- `sign_up/verify_code/desktop/_body.dart` — `DesktopBody`: `CodeInput` + create account.

## Conventions

- Forms: `FormController` + `InputController`s; submit gates on `form.validate()`, button on `form.loading`.
- Errors: `FloatFlag.showFromError(e)`.
- Success: `Navis.pushAndClearStack(context, redirect ?? "/home")` (`redirect` = consumed deep link).
- Only `desktop/` bodies exist; a phone body branches with `DeviceSelector` in the `PageBuilder`, not inside the body.
