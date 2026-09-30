# Spec: session (accounts, sign in, devices, bootstrap, permissions)

**Plan** §5.3, §5.4, §6.3, §6.4, §7.4. **App today** `client/`, `sign_in/`, `sign_up/`,
`permissions/`, `docs/app-areas.json`.

In `local` mode there is no e-mail and no cloud identity: people are **local accounts** of the
master. The app's screens stay the same; what changes is which branches of them are reachable.

---

## session.account

A person who can sign in to this master.

### Data

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `username` | string | unique, compared lowercased |
| `email` | string? | optional, unique when present; used only as a sign-in name offline (nothing is ever e-mailed) |
| `firstName`, `lastName` | string | |
| `sex` | `female`/`male`/`other`? | `ClientModel.sex` |
| `birthday` | `YYYY-MM-DD`? | |
| `picture` | fileId? | |
| `password` | Argon2id hash? | `null` until the account is activated |
| `pin` | Argon2id hash? | optional POS PIN |
| `status` | `pending` / `active` / `disabled` | `pending` = created by an invitation and not activated yet |
| `mustChangePassword` | bool | set by an admin reset |
| `failedAttempts`, `lockedUntil` | int, instant? | |
| `created`, `lastSignIn` | instant | |

### Rules

- **S-1** A username is 3 to 32 characters of `a-z 0-9 . _ -`, starting with a letter, unique
  without regard to case. An e-mail, when given, is unique without regard to case.
- **S-2** A password has at least 10 characters. There are no composition rules. Passwords in
  the bundled list of common passwords (`assets/catalogs/common_passwords.txt`) are refused
  (`weak_password`).
- **S-3** Passwords and PINs are stored as Argon2id (64 MiB, t=3, p=1, 16-byte salt). If the
  parameters were raised since the hash was written, it is rewritten on the next successful
  sign in.
- **S-4** Five failed sign ins in a row lock the account for 15 minutes (`account_locked`, with
  `until`). Independently, a device may try 20 sign ins per minute (`rate_limited`). Every
  failure and every lock goes to the audit log.
- **S-5** A PIN is 6 digits and opens a **POS-scoped session** only (§session.session). Five
  failed PINs disable the PIN until that person signs in with their password.
- **S-6** The first account is created at setup with the grant `*` (owner). The company always
  keeps at least one active account holding `*`: disabling it, or removing its `*`, is refused
  (`last_owner`).
- **S-7** Nobody signs up offline. Accounts are only created by an invitation (see
  `employees.md`, `employees.invite`). The app hides the sign-up branch in `local` (capability
  gate, plan §7.3).
- **S-8** An invited account is `pending` with an **activation code**: 8 digits, valid 72 hours,
  one use, shown once to the admin who invited (on screen, never sent). Activating (code plus a
  new password) makes the account `active`, signs the person in and **accepts the invitation**
  (they typed a code the company gave them, which is the consent). An expired code is re-issued
  by the admin (`employees.reissueActivation`).
- **S-9** Changing one's own password needs the current one, ends every other session of that
  account, and re-wraps the account's sealed-key wrap (plan §6.3).
- **S-10** An admin reset needs `business.employees.edit`, and the target may hold **no
  permission the resetter lacks** (`insufficient_permissions`): otherwise a reset is a way to
  sign in as somebody with more rights. So only a `*` holder resets another `*` holder, and
  nobody resets their own password this way (S-9). Every reset goes to the audit log. It
  sets a temporary password with `mustChangePassword`. The account's sealed-key wrap is lost:
  a holder of the sealed key must grant it again (plan §6.3). This is said on the confirmation.
- **S-11** A forgotten owner password is reset **on the master only**, with the recovery key.
  That also restores the owner's sealed-key wrap.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `auth.identify` | none (paired device) | `login` (username or e-mail) | `{method: "password" \| "activation"}` | — |
| `auth.signIn` | none | `login`, `password` | session tokens + `mustChangePassword` | `invalid_credentials`, `account_locked`, `account_disabled`, `rate_limited` |
| `auth.signInPin` | none | `username`, `pin` | POS-scoped session tokens | `invalid_credentials`, `pin_disabled`, `rate_limited` |
| `auth.activate` | none | `login`, `code`, `password` | session tokens | `invalid_code`, `code_expired`, `weak_password` |
| `auth.refresh` | none | `refreshToken` | new tokens | `session_expired` (`action: "login"`) |
| `auth.signOut` | session | — | `{}` | — |
| `account.changePassword` | session | `current`, `password` | `{}` | `invalid_credentials`, `weak_password` |
| `account.setPin` | session | `password`, `pin` \| `null` | `{}` | `invalid_credentials` |

`auth.identify` answers `password` for an unknown login too, so it does not reveal who has an
account. The failure comes from `auth.signIn` as `invalid_credentials`, the same code as a wrong
password.

### How the app maps

| App today | Local |
|---|---|
| `SignInService` `email/verify` → method | `auth.identify`; `LoginMethod` gains `activation`; `code` is never answered |
| `email/sign_in/password` | `auth.signIn` |
| code sign in, resend | not reachable |
| `SignUpService` | not reachable (S-7) |
| `ClientService.signOut` `POST /authentication/logout/` | `auth.signOut` |
| `onSessionRejected` (`action: "login"`) | any op answering `session_expired`, `session_revoked` or `device_revoked` |

---

## session.session

### Rules

- **S-20** A session belongs to one account **and one paired device** (its certificate). A token
  presented from another device is refused (`session_revoked`).
- **S-21** Access token: 15 minutes. Refresh token: rotated on every use; 30 days for a desktop
  or mobile client, 16 hours for a POS-scoped session. Reusing an already-rotated refresh token
  ends the whole session (it was stolen or copied) and goes to the audit log.
- **S-22** A POS-scoped session (PIN) may run only the ops whose permission is under `pos.*`,
  plus `session.bootstrap` and `auth.*`. Anything else answers `forbidden`.
- **S-23** Revoking a device, disabling an account or changing a password ends the affected
  sessions **at once**: the next frame on those connections answers `session_revoked` and the
  connection is closed.

---

## session.bootstrap

What `GET /init/` answers today: who is signed in, their company, their permissions, pending
tasks and the platform catalogues. The `XLanSource` maps it onto the same `ClientService` seeds.

### Op

`session.bootstrap` · session · no args ·

```json
{
  "client":      { "name", "lastName", "username", "email", "sex", "picture", "birthday" },
  "businesses":  [ { "id", "name", "caption", "logo", "activity", "profile", "currency" } ],
  "permissions": { "<businessId>": ["*"] },
  "tasks":       [],
  "catalogs":    { "countries": [...], "currencies": [...] },
  "deployment":  { "mode": "local", "instanceId", "engine": "1.0.0", "timezone": "America/Caracas" }
}
```

### Rules

- **S-30** `businesses` has **exactly one** entry: the master's company (plan D6).
- **S-31** `tasks` is empty in `local`: the only pre-start task today is an employment
  invitation, and activation accepts it (S-8).
- **S-32** `catalogs` is the bundled snapshot (see `business.md`, catalogues). There is no `cdn`:
  every file is served by the master (`protocol-v1.md`, files), and the `XLanSource` resolves
  file ids to master URLs.
- **S-33** `deployment` is new and only used by the capability gate and the diagnostics screen.
  The cloud answer never carries it.

---

## session.permissions

Grants are the same permission ids as `docs/app-areas.json`, evaluated with the same rules as
`PermissionsService` (`can`, `canOpen`, `granted`), but **enforced on the master** (plan §5.4).

### Data

`grant { accountId, permission, grantedBy, granted }`. The list of an account's grants is what
`permissions[businessId]` answers.

### Rules

- **P-1** Wildcards: `*` is everything; `<area>.*` is every action of that area and its children.
  `<area>.view` opens the area; a child's view requires the parent's view (the grant op adds the
  parent views that are missing, as the permissions matrix already does on screen).
- **P-2** Nobody grants what they don't hold. Only a holder of `*` grants `*`.
- **P-3** Granting any permission needs `business.employees.permissions`. Changes apply to open sessions **at once**: the affected clients receive
  `permissions/changed` and re-read the bootstrap.
- **P-4** Granting `business.employees.view_personal` (or anything that implies it) re-wraps
  the sealed key for the grantee. It needs a granter who holds the sealed key in their current
  session. Otherwise it answers `sealed_key_unavailable` (plan §6.3).
- **P-5** Areas that don't exist in `local` (messages, channels, connections, …) can be granted
  (so a hybrid company keeps one set of grants), but they open nothing locally.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `permissions.of` | `business.employees.view` | `accountId` | `[permission]` | `not_found` |
| `permissions.set` | `business.employees.permissions` | `accountId`, `permissions: [id]` (the whole set) | `[permission]` | `escalation`, `last_owner`, `sealed_key_unavailable` |
| `permissions.requests.list` | session | — | own requests of the company | — |
| `permissions.requests.create` | session | `permission`, `reason?` (≤ `kPermissionReasonMax`) | `{id}` | `already_requested`, `already_granted` |
| `permissions.requests.inbox` | `business.employees.permissions` | `state?` | everyone's requests | — |
| `permissions.requests.answer` | `business.employees.permissions` | `id`, `grant: bool` | the request | `escalation` |

- **P-10** A request's `state` is measured when it is read: `granted` if the person holds the
  permission now (however it was given), otherwise `pending` or `denied` as answered. That is
  the rule `PermissionRequestState` already documents.
- **P-11** `already_requested` / `already_granted` are the local equivalents of today's `409`.
  The app keeps its behaviour: re-read the list and the bootstrap, then show the error.

### Events

| Event | When | Payload |
|---|---|---|
| `permissions/changed` | an account's grants changed | `{accountId}`, delivered only to that account's sessions |

---

## session.devices

Paired devices (plan §5.3). The pairing handshake itself is in `protocol-v1.md`.

### Data

`device { id, name, platform, code, certFingerprint, paired, pairedBy, lastSeen, lastAccount, revoked }`.
`code` is a short identifier (`A`, `B`, … `Z`, then `AA`…), assigned at pairing and never
reused. It prefixes ticket codes minted by that device (`pos.md`, POS-40).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `devices.list` | `local_server.devices` | — | devices with online state | — |
| `devices.rename` | `local_server.devices` | `id`, `name` | device | `not_found` |
| `devices.revoke` | `local_server.devices` | `id` | device | `not_found`, `self` (can't revoke the master's own device) |
| `pairing.start` | `local_server.devices`, **on the master's own device only** | `name?` | `{qr, code, expires}` | `not_master` |
| `devices.browserCa` | any session | — | `{certificate, fingerprint, thumbprint, addresses, port}`: the browsers' root (plan §5.3) and where the web build answers | — |

### Rules

- **S-40** A pairing code is 8 digits, lasts 5 minutes, one use, and three wrong attempts void
  it. Only one pairing code is live at a time.
- **S-41** Revoking a device ends its sessions (S-23), puts its certificate on the deny list, and
  voids the key that opens its client cache (plan §6.5). A POS outbox still on that device is
  lost unless it is replayed before the revocation (the confirmation lists pending outbox
  entries the master knows about, see `pos.md`).

---

## Differences from cloud

- No e-mail codes, no sign up, no OAuth. Activation codes replace e-mailed invitations.
- `auth.identify` never reveals whether an account exists (the cloud's `email/verify` does).
- Grants of other people can be edited in `local` (the app draws the matrix today but has "no
  endpoint for another person's grants yet").

## Open questions

1. ~~New permission ids.~~ **Decided 2026-09-30:** `business.employees.permissions` and the
   area `local_server` (`view`, `devices`, `backups`, `stop`, `modes: ["local", "hybrid"]`) are
   in `docs/app-areas.json`.
2. ~~Who may reset a password.~~ **Decided 2026-09-30:** whoever holds
   `business.employees.edit`, never over someone with more permissions (S-10).
3. ~~PIN for accounts that hold more than `pos.*`.~~ Decided: allowed, since the PIN session is
   limited to `pos.*` anyway (S-22).
