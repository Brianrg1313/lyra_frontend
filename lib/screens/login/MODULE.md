# Module: auth (login + sign up)

**Paths** `lib/screens/login`, `lib/screens/sign_up`
**Role** Getting into the app. Two flows, each with a second step.
**Services** `SignInService`, `SignUpService` — **flow-scoped**: each page provides its
own with `Provider(create: ...)`, they are not in `initial_builder.dart`.

## Routes (`lib/toolkit/settings/routes.dart`)

| key | url | notes |
|---|---|---|
| `login` | `/login` | |
| `sign_in_code` | `/login/code` | `parents: ["login"]`. Only reachable once the backend says the account signs in with an emailed code. |
| `sign_up` | `/sign_up` | |
| `verify_code` | `/verify_code` | `parents: ["sign_up"]` |

None of them declare a `shell` — each is its own `Navigator` page.

## Files

- `login/_login.dart` — `Login extends PageBuilder`: provides `SignInService`, renders
  `DesktopBody`.
- `login/desktop/_body.dart` — `DesktopBody`: the email/password form
  (`FormController` + `InputController.email/.password`). Resolves the account's
  `LoginMethod` first; if it is the emailed code it triggers the send and pushes
  `/login/code`.
- `login/code/_code.dart` — `SignInCode extends PageBuilder`: second step; the code was
  already sent by `Login`.
- `login/code/desktop/_body.dart` — `DesktopBody`: `CodeInput` + verify.
- `sign_up/_sign_up.dart` — `SignUp extends PageBuilder`: provides `SignUpService`.
- `sign_up/desktop/_body.dart` — `DesktopBody`: first name, last name, email
  (`InputController` / `.email`); links back to `/login`.
- `sign_up/verify_code/_verify_code.dart` — `VerifyCode extends PageBuilder`.
- `sign_up/verify_code/desktop/_body.dart` — `DesktopBody`: `CodeInput` + create account.

## Conventions

- Forms are always `FormController` + `InputController`s from `package:core/form.dart`;
  submit gates on `form.validate()` and uses `form.loading` to drive the button.
- Errors surface through `FloatFlag.showFromError(e)`.
- On success the flow lands with `Navis.pushAndClearStack(context, redirect ?? "/home")`
  so the auth pages leave the history (`redirect` is the consumed deep link).
- The `desktop/` sub-folder is the layout for desktop; there is no phone body yet. When
  one is added, branch with `DeviceSelector` in the `PageBuilder`, not inside the body.
