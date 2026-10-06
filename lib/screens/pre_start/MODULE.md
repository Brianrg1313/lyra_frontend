# Module: pre_start

**Path** `lib/screens/pre_start`
**Role** Pages before the home: one per `/init` task (`ClientTask`, `lib/services/client/client_task.dart`), and the
deployment and LAN pages (`docs/plan-offline-lan.md` §7.4). Standalone routes, no home shell.

## Routes

| key | url | task |
|---|---|---|
| `welcome` | `/welcome` | `business.none`, `employment.invitation` |
| `deployment_master` | `/deployment/master` | making this computer the server (`parents: ["login"]`, offered by the sign in) |
| `deployment_pair` | `/deployment/pair` | pairing with a server (`parents: ["login"]`; a browser on a master's page starts here) |
| `lan` | `/lan` | every start of a paired device or a master |

## Files

- `welcome/_welcome.dart` — `Welcome extends PageBuilder` (`routeKey`, `path`).
- `welcome/desktop/_body.dart` — `DesktopBody`: avatar, greeting, one `InvitationCard` per pending invitation (opens `InvitationModal`; accepted → re-`resolve()`s and always goes to `/home`), then (only
  with no company) a `WelcomeOption` to create (`CreateBusinessModal` in a `showImageModal` headed by `gradient-2.png`; on `true` re-`resolve()`s and navigates) and two
  `WelcomeChoice`s: awaiting invitation, open jobs (not with `singleCompany`: a master's owner lands here when it has no
  company yet); a quiet sign out.
- `welcome/widgets/welcome_option.dart` — `WelcomeOption`: full-width main card (create a company): 120 px `gradient-1.png` band, icon + title + subtitle, action button on the right.
- `welcome/widgets/welcome_choice.dart` — `WelcomeChoice`: compact secondary card (waiting for an invitation, open jobs), arrow or a `tag`; two in an equal-height `Row`.
- `deployment/master/_master.dart` — `MasterSetup extends PageBuilder`.
- `deployment/master/desktop/_body.dart` — owner form (no company: the welcome creates it), optional passphrase, licence
  tick (only the drawn fields are validated, each with its message under it) → `LocalServerService.setUp` → the 24 words (`RecoveryWords`) with a required "written down" tick →
  `Deployment.attach(master)` → `/lan`; "use Lyra another way" back to `/login`. With `owner` (the sign in's "Create
  Master Server") the owner's e-mail and password come from there: no username or password fields, the username made
  from the e-mail (`LocalServerService.usernameOf`), the engine opened and signed in with them before `/lan` (which then
  resolves to `/welcome`), and "back" runs `onBack`. With `account` (the server section online) the e-mail and names come
  from the signed-in account and the password is asked; `company` goes to the setup (the cloud company's, linked), and
  `onDone(password)` takes over after the words (`HybridService.adopt`).
- `deployment/pair/_pair.dart` — `PairDevice extends PageBuilder`: provides `LanPairingService` (searches at once, not on
  web).
- `deployment/pair/desktop/_body.dart` — phones: "scan the QR" (`QrScanner` in a modal); found servers fill the address;
  address, port, device name, 8-digit `CodeInput`; a browser shows only the master it was served by, the name and the
  code; wrong code / someone in the middle / unreachable each say so; "use Lyra another way" back to `/login` (not in a
  browser).
- `deployment/pair/widgets/qr_scanner.dart` — `QrScanner`: camera (`mobile_scanner`), the first Lyra `PairingOffer` read
  closes the modal; another QR is said to be foreign.
- `deployment/widgets/deployment_frame.dart` — `DeploymentFrame` (centered column, title, subtitle), `DeploymentCheck`
  (tick + label), `DeploymentNote` (note or error line).
- `deployment/widgets/recovery_words.dart` — `RecoveryWords`: numbered, three per row, selectable.
- `lan/_lan.dart` — `LanHome extends PageBuilder`.
- `lan/desktop/_body.dart` — one view per `LanStatus`: connecting, locked (master: `LanUnlock`), signed out
  (→ `/login`, whose `AuthMaster` signs in), ready (loads the session with `ClientService.resolve` and opens the home; `enter` seam; a session
  that can't be loaded stops with a message and a retry instead of coming back here forever), unpaired
  (master: `LanUnlock(enroll: true)`), unreachable, revoked, update, error; "use Lyra another way" (`LanService.leave`, confirmed, then `/login`; not in a
  browser).
- `lan/widgets/lan_unlock.dart` — `LanUnlock`: the passphrase → `engine.unlock`, or with `enroll` → `enrollMaster`.
- `welcome/widgets/invitation_card.dart` — `InvitationCard`: full-width card drawn first, large company `BusinessAvatar` + title + position + "Review" button.

## Invariants

- A task reaches its page only through `ClientService.resolve()` (splash, sign in, sign up). A task
  with no `route` on `ClientTaskKey` is skipped and the person lands on the home.
- The LAN pages never read `Sources` themselves: once signed in, `ClientService.resolve` reads the master through the
  LAN sources and the app opens the home. The server's devices live in the home (`sections/local_server`).
