# Module: pre_start

**Path** `lib/screens/pre_start`
**Role** Pages before the home: one per `/init` task (`ClientTask`, `lib/services/client/client_task.dart`), and the
deployment and LAN pages (`docs/plan-offline-lan.md` §7.4). Standalone routes, no home shell.

## Routes

| key | url | task |
|---|---|---|
| `welcome` | `/welcome` | `business.none`, `employment.invitation` |
| `deployment` | `/deployment` | LAN build, no mode chosen yet |
| `deployment_master` | `/deployment/master` | making this computer the server (`parents: ["deployment"]`) |
| `deployment_pair` | `/deployment/pair` | pairing with a server (`parents: ["deployment"]`) |
| `lan` | `/lan` | every start in `local` mode |

## Files

- `welcome/_welcome.dart` — `Welcome extends PageBuilder` (`routeKey`, `path`).
- `welcome/desktop/_body.dart` — `DesktopBody`: avatar, greeting, one `InvitationCard` per pending invitation (opens `InvitationModal`; accepted → re-`resolve()`s and always goes to `/home`), then (only
  with no company) a `WelcomeOption` to create (`CreateBusinessModal` in a `showImageModal` headed by `gradient-2.png`; on `true` re-`resolve()`s and navigates) and two
  `WelcomeChoice`s: awaiting invitation, open jobs; a quiet sign out.
- `welcome/widgets/welcome_avatar.dart` — `WelcomeAvatar`: round profile picture, initial fallback.
- `welcome/widgets/welcome_option.dart` — `WelcomeOption`: full-width main card (create a company): 120 px `gradient-1.png` band, icon + title + subtitle, action button on the right.
- `welcome/widgets/welcome_choice.dart` — `WelcomeChoice`: compact secondary card (waiting for an invitation, open jobs), arrow or a `tag`; two in an equal-height `Row`.
- `deployment/_deployment.dart` — `DeploymentChooser extends PageBuilder`.
- `deployment/desktop/_body.dart` — online / this computer is the server (only with the engine; an existing master goes
  straight to `/lan`) / connect to a server, as `WelcomeChoice`s.
- `deployment/master/_master.dart` — `MasterSetup extends PageBuilder`.
- `deployment/master/desktop/_body.dart` — owner form, optional passphrase, licence tick → `LocalServerService.setUp` →
  the 24 words (`RecoveryWords`) with a required "written down" tick → `local`/`master` → `/lan`.
- `deployment/pair/_pair.dart` — `PairDevice extends PageBuilder`: provides `LanPairingService` (searches at once).
- `deployment/pair/desktop/_body.dart` — found servers fill the address; address, port, device name, 8-digit `CodeInput`;
  wrong code / someone in the middle / unreachable each say so.
- `deployment/widgets/deployment_frame.dart` — `DeploymentFrame` (centered column, title, subtitle), `DeploymentCheck`
  (tick + label), `DeploymentNote` (note or error line).
- `deployment/widgets/recovery_words.dart` — `RecoveryWords`: numbered, three per row, selectable.
- `lan/_lan.dart` — `LanHome extends PageBuilder`.
- `lan/desktop/_body.dart` — one view per `LanStatus`: connecting, locked (master: `LanUnlock`), signed out
  (`LanSignIn`), ready (`LanConnected`), unpaired (master: `LanUnlock(enroll: true)`), unreachable, revoked, update,
  error; "use Lyra another way" (`LanService.leave`, confirmed).
- `lan/widgets/lan_sign_in.dart` — `LanSignIn`: username + password → `LanService.signIn`.
- `lan/widgets/lan_unlock.dart` — `LanUnlock`: the passphrase → `engine.unlock`, or with `enroll` → `enrollMaster`.
- `lan/widgets/lan_connected.dart` — `LanConnected`: this device's code and the CA fingerprint; the devices list
  (refreshed every 5 s, online / server / removed), remove (confirmed), "Add device" on the master (the code to type);
  sign out; stop the server (confirmed, counts connected devices).
- `welcome/widgets/invitation_card.dart` — `InvitationCard`: full-width card drawn first, large company `BusinessAvatar` + title + position + "Review" button.

## Invariants

- A task reaches its page only through `ClientService.resolve()` (splash, sign in, sign up). A task
  with no `route` on `ClientTaskKey` is skipped and the person lands on the home.
- The LAN pages never read `Sources`: in `local` mode nothing reaches the home until the domains exist (plan phase 4).
