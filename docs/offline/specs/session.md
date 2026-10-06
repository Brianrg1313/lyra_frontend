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
- **S-6** The first account is created at setup and is the **owner**: `all` (P-2), measured
  from `meta.owner`, never from a stored document, so nothing written can lock the company out of
  itself. Nobody changes the owner's permissions or access (`permissions_owner`), and the owner
  account is never disabled (`last_owner`).
- **S-7** Nobody signs up offline. Accounts are only created by an invitation (see
  `employees.md`, `employees.invite`). The app hides the sign-up branch in `local` (capability
  gate, plan §7.3).
- **S-8** An invited account is `pending` with an **activation code**: 8 digits, valid 72 hours,
  one use, shown once to the admin who invited (on screen, never sent). Activating (code plus a
  new password) makes the account `active`, signs the person in and **accepts the invitation**
  (they typed a code the company gave them, which is the consent). An expired code is re-issued
  by the admin (`employees.reissueActivation`). Five wrong codes in a row void it, and the admin
  re-issues it too. Only the code's hash is kept, bound to its account.
- **S-9** Changing one's own password needs the current one, ends every other session of that
  account, and re-wraps the account's sealed-key wrap (plan §6.3).
- **S-10** An admin reset needs `employees.manage`, and the target may hold **no
  permission the resetter lacks** (`insufficient_permissions`): otherwise a reset is a way to
  sign in as somebody with more rights. So only an `all` holder resets another `all` holder, and
  nobody resets their own password this way (S-9). Every reset goes to the audit log. It
  sets a temporary password with `mustChangePassword`. The account's sealed-key wrap is lost:
  a holder of the sealed key must grant it again (plan §6.3). This is said on the confirmation.
- **S-11** A forgotten owner password is reset **on the master only**, with the recovery key.
  That also restores the owner's sealed-key wrap.
- **S-12** A **cloud grant** (plan D14, `task-edge-sync-backend.md` §9) opens a session on a master
  enrolled with the cloud without the person's password: someone signed in online by code, Google, or
  with a cloud password other than the master's. The master checks it offline: signed by an edge key it
  pinned (`kid`), for its own edge device and cloud company, version 1, issued at most 5 minutes ahead
  of its clock, good for at most 5 minutes, not expired (30 s of skew), and its nonce never seen
  before. A failed check is `grant_invalid`, an expired grant `grant_expired`, a second use
  `grant_used`. The account is the active one with the grant's e-mail, without regard to case; none,
  or one still `pending`, is `grant_no_account` (the person is invited, or activates, first, or accepts
  in the cloud: a job the cloud says started activates the account, `employees.md` E-21); a
  disabled one `account_disabled`. It counts towards the device's sign-in rate (S-4) and goes to the
  audit log.
- **S-13** A session opened by a grant holds no sealed keys: they open with the password (plan §6.3),
  so the sealed fields answer `sealed_locked` in it. `auth.unseal` checks that session's password
  (S-4 counts it), rotates its refresh token as `auth.refresh` does, and opens the keys in it.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `auth.identify` | none (paired device) | `login` (username or e-mail) | `{method: "password" \| "activation"}` | — |
| `auth.signIn` | none | `login`, `password` | session tokens + `mustChangePassword` | `invalid_credentials`, `account_locked`, `account_disabled`, `rate_limited` |
| `auth.signInPin` | none | `username`, `pin` | POS-scoped session tokens | `invalid_credentials`, `pin_disabled`, `rate_limited` |
| `auth.activate` | none | `login`, `code`, `password` | session tokens, as `auth.signIn` | `invalid_code` (also an unknown or active login), `code_expired`, `weak_password`, `rate_limited` |
| `auth.grant` | none (paired device) | `grant` | session tokens + `accountId`, `mustChangePassword`, `sealed: false` | `grant_invalid`, `grant_expired`, `grant_used`, `grant_no_account`, `account_disabled`, `rate_limited` |
| `auth.unseal` | none (paired device) | `refreshToken`, `password` | new tokens | `session_expired`, `invalid_credentials`, `account_locked`, `rate_limited` |
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
- **S-22** A POS-scoped session (PIN) may run only the ops whose permission is in the `pos`
  section (`pos`, `pos.sell`, `pos.cancel`), plus `session.bootstrap` and `auth.*`. Anything else answers `forbidden`.
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
  "permissions": { "<businessId>": { "business": { "view": true }, "pos": { "view": true, "sell": true } } },
  "owned":       ["<businessId>"],
  "tasks":       [],
  "catalogs":    { "countries": [...], "currencies": [...] },
  "deployment":  { "mode": "local", "instanceId", "engine": "1.0.0", "timezone": "America/Caracas" }
}
```

### Rules

- **S-30** `businesses` has **exactly one** entry: the master's company (plan D6). A master set up
  without it (`business.md` B-1) answers none, no `permissions` and a `null` timezone until the
  owner creates it.
- **S-31** `tasks` holds only `{key: "business.none"}`, while the company doesn't exist: the app's
  welcome creates it. There is no invitation task: activation accepts it (S-8).
- **S-32** `catalogs` is the bundled snapshot (see `business.md`, catalogues). There is no `cdn`:
  every file is served by the master (`protocol-v1.md`, files), and the `XLanSource` resolves
  file ids to master URLs.
- **S-33** `deployment` is new and only used by the capability gate and the diagnostics screen.
  The cloud answer never carries it.
- **S-34** `client` is the account (`id`, `name`, `lastName`, `username`, `email`, `sex`,
  `picture`, `birthday`); `permissions` is **the cloud's `/init` entry exactly**: per company,
  the app's area ids the person holds, nested, only the granted ones (P-3). `owned` (the company
  ids this person owns, S-6) is new beside it; the cloud doesn't send it. `catalogs` carries its
  `version`. The app's
  LAN source lays the answer out as `/init` (the person and the catalogues at the top level), and
  `PermissionsService` reads a listed company with the P-1 rules.

---

## session.permissions

**The cloud's permission system, unchanged** (backend `lib/models/permissions/MODULE.md`). A
person holds one set of permissions, in one vocabulary, whether the cloud or the master answers:
the master stores the backend's document, checks the backend's keys and answers the backend's
shapes. `lyra_protocol` (`permissions.dart`) carries the copy of the backend's catalog, areas
and global templates, and its test compares that copy against the backend's export
(`pnpm permissions:export`): a change starts in the backend and reaches the copy in the same
change. Sync carries none of it in its first version (`task-edge-sync-backend.md`: the cloud's
word wins).

### Data

- **Catalog** (`PermissionCatalog`): sections and their actions. A key is `<section>` (entering
  it, reading what it shows) or `<section>.<action>` (one thing inside it).
- **Member** `{ account, access, all, sections, template, custom, updated, updatedBy }`, one per
  account. `access` is membership (may enter the company); `sections` is a structure normalized
  to the catalog (`{money: {access: true, charge: true, …}}`); `template` (`{scope, id}`) is
  where it was copied from; `custom` says it was changed by hand since. No member row, or one
  with `sections` null, is no permission at all.
- **Template** `{ id, name, description, all, sections }`: the global ones (`PermissionPresets`,
  `id` = code: owner, manager, marketing, seller, auditor, billing, finance; read-only) and the
  company's own (`id` = UUID).
- **Request** `{ id, account, area, keys, reason, state, created }`: an area id asked for, and
  the keys it takes (`PermissionAreas.requires`).

### Rules

- **P-1** `can(key)` is `all`, or the section's `access` **and** the action's flag:
  `can("money.void")` is `money.access && money.void`. An action is never granted without its
  section. A key the document doesn't mention reads `false`; `all` reads `true`, keys the
  catalog adds later included. There are no wildcards.
- **P-2** `all` is the owner's mark. The owner (S-6) is `all` by measurement; any other member
  is `all` only if a holder of `all` gave it.
- **P-3** **Areas.** The app gates by area ids (`docs/app-areas.json`); each maps to the keys
  its ops require (`PermissionAreas.map`: one key, every key of a list, `null` every member,
  `*` only `all`). An action's area id is granted only with its area's `view`, a `view` only
  with its parent's. The bootstrap answers the granted ids nested (S-34).
- **P-4** **Every op declares one catalog key** (or none: every member), as the cloud's routes
  do, and the engine checks it before the handler (`forbidden`). An op the cloud also serves
  takes the key of its cloud route; `server.*` and `money.export` are the master's alone.
- **P-5** **Membership.** Activation (S-8) and `employees.accept` give `access` with no
  permissions: the person enters and opens nothing until someone assigns them. After that,
  access is managed here whatever the job says. A member without access signs in to no company:
  the bootstrap lists none.
- **P-6** **Who changes whom.** Reading members and templates needs `permissions`; changing a
  member, `permissions.assign`; the company's own templates, `permissions.templates`. Nobody
  changes themselves (`permissions_self`) or the owner (`permissions_owner`). Nobody gives or
  takes what they don't hold (`escalation`): every key whose stored value an assignment or a
  revoke changes must be one the assigner can, and `all` on either side needs `all`. A member
  being given access for the first time needs an active job here (`permission_member_not_found`
  otherwise).
- **P-7** **Templates are copied.** Applying one writes its structure onto the member with
  `template` set and `custom` false; changing single keys afterwards sets `custom` (a key changed
  on an `all` member makes it explicit). Editing or removing a template never changes anyone:
  removing drops only the label from those copied from it.
- **P-8** **At once.** A write to a member applies to their open sessions on the next frame: the
  connections' permissions are replaced and they receive `permissions/changed`, after which the
  app re-reads the bootstrap. Revoking access does the same.
- **P-9** **Sealed keys** (plan §6.3). `employees` holds the `hr` scope and `money` the
  `payments` scope: they are what the cloud requires for the screens that show those fields.
  When a member comes to hold a scope, the assigner's session wraps its key to them if it holds
  it; otherwise the next sign in or refresh of any holder does, once the member has a key pair
  (their first password sign in). When a member stops holding it, their wrap is deleted. Until
  they have it the sealed fields read empty (`employees.md` E-3); nothing is refused.
- **P-10** A request's `state` is measured on read: `granted` once the person holds the area
  (however it was given), `pending` otherwise. Asking grants nothing; whoever answers it opens
  the member's permissions.
- **P-11** Refused requests: an id the app doesn't have (`permission_request_invalid`), one
  only the owner holds (`permission_request_owner`), one already held
  (`permission_request_granted`) or already pending (`permission_request_pending`): the cloud's
  codes. The app keeps its behaviour on the last two: re-read the list and the bootstrap, then
  show the error.
- **P-12** **The cloud's word wins** (plan §9.3). While the master syncs with its cloud company
  (enrolled, not revoked, not past the allowance), each person's document is the cloud's: it
  arrives by the sync (`member`, `task-edge-sync-backend.md` §11), replaces the master's whole,
  applies to open sessions as P-8 does, and is audited with device `cloud`. A cloud member with no
  account here yet gets it when admitted (P-5). The master changes no member or template
  meanwhile (`permissions_online`); `permissions.get` and `permissions.members.detail` answer
  `online: true`, and the app shows the editor read-only with where to change it. The owner stays
  `all` whatever arrives (S-6). At the first link each person's document goes up with their
  account, so the cloud admits them with it (§10 there). Revoked, or past the allowance, the
  master's own editor is the way again.

### Ops

The cloud's endpoints (`/lyra/v1/permissions`), one op each, with the same keys and shapes.
Members are named by `username`, as there.

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `permissions.get` | session | — | `{catalog: [{key, actions}], online, mine: {all, template, custom, sections}}` | — |
| `permissions.templates.list` | `permissions` | — | `[{id, scope, name, description, all, sections}]`, global first | — |
| `permissions.templates.create` | `permissions.templates` | `name`, `description?`, `from?` (a template id), `permissions?` | `{id}` | `permission_template_name_taken`, `permission_template_not_found`, `permissions_invalid`, `permissions_online` |
| `permissions.templates.edit` | `permissions.templates` | `id`, `name?`, `description?`, `permissions?` | `{id}` | `permission_template_not_found`, `permission_template_global`, `permission_template_name_taken`, `permissions_invalid`, `permissions_online` |
| `permissions.templates.remove` | `permissions.templates` | `id` | `{id}` | `permission_template_not_found`, `permission_template_global`, `permissions_online` |
| `permissions.members.list` | `permissions` | — | `[{username, name, lastName, picture, me, owner, all, template: {scope, id, name} \| null, custom}]`, the asker first | — |
| `permissions.members.detail` | `permissions` | `username` | a member + `access`, `online`, `sections` | `permission_member_not_found` |
| `permissions.members.assign` | `permissions.assign` | `username`, `template?`, `permissions?` | `{username}` | `permission_member_not_found`, `permissions_self`, `permissions_owner`, `escalation`, `permission_template_not_found`, `permissions_invalid`, `permissions_online` |
| `permissions.members.revoke` | `permissions.assign` | `username` | `{username}` | `permission_member_not_found`, `permissions_self`, `permissions_owner`, `escalation`, `permissions_online` |
| `permissions.requests.list` | session | — | own requests, newest first: `[{id, permission, reason, state, created}]` | — |
| `permissions.requests.create` | session | `permission` (an area id), `reason?` (≤ 200) | `{id}` | P-11 |

`permissions` (in templates and assign) is always partial, `{<section>: {access?, <action>?:
bool}}`; an unknown key is refused, never dropped (`permissions_invalid` with `key`).

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
- **S-42** An active account can pair a device itself with its login and password, no code
  (plan D13, `protocol-v1.md` §3, the password way). The device is `pairedBy` that account. A wrong
  password counts towards the account's lockout (S-4); a locked account answers `account_locked`;
  a login that can't sign in fails like a wrong password.

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
