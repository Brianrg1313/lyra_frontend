# Module: pre_start

**Path** `lib/screens/pre_start`
**Role** Pages a signed-in person must go through before the home: one per `/init` task
(`ClientTask`, `lib/services/client/client_task.dart`). Standalone routes, no home shell.

## Routes

| key | url | task |
|---|---|---|
| `welcome` | `/welcome` | `business.none`, `employment.invitation` |

## Files

- `welcome/_welcome.dart` — `Welcome extends PageBuilder` (`routeKey`, `path`).
- `welcome/desktop/_body.dart` — `DesktopBody`: avatar, greeting, one `InvitationCard` per pending invitation (opens `InvitationModal`; accepted → re-`resolve()`s and always goes to `/home`), then (only
  with no company) a `WelcomeOption` to create (`CreateBusinessModal` in a `showImageModal` headed by `gradient-2.png`; on `true` re-`resolve()`s and navigates) and two
  `WelcomeChoice`s: awaiting invitation, open jobs; a quiet sign out.
- `welcome/widgets/welcome_avatar.dart` — `WelcomeAvatar`: round profile picture, initial fallback.
- `welcome/widgets/welcome_option.dart` — `WelcomeOption`: full-width main card (create a company): 120 px `gradient-1.png` band, icon + title + subtitle, action button on the right.
- `welcome/widgets/welcome_choice.dart` — `WelcomeChoice`: compact secondary card (waiting for an invitation, open jobs), arrow or a `tag`; two in an equal-height `Row`.
- `welcome/widgets/invitation_card.dart` — `InvitationCard`: full-width card drawn first, large company `BusinessAvatar` + title + position + "Review" button.

## Invariants

- A task reaches its page only through `ClientService.resolve()` (splash, sign in, sign up). A task
  with no `route` on `ClientTaskKey` is skipped and the person lands on the home.
