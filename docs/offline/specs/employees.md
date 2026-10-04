# Spec: employees (staff, invitations, profiles, sealed fields)

**Plan** §2 (employees row), §6.3 (sealed fields), §5.4 (permission-shaped answers). **App
today** `business/business_employee*_model.dart`, `business_employees_service.dart`,
`screens/home/sections/business/employees`, `docs/app-areas.json` (`business.employees.*`).

An **employment** links an account (`session.md`) to the company with a job. Offline, an
invitation creates the account too, since there's no e-mail to invite a stranger with.

---

## employees.employment

### Data

**Card** (always readable with `employees`): `id`, `accountId`, `username`,
`name`, `lastName`, `picture`, `headline`, `jobTitle`, `department`, `branchId` (the site),
`contract`, `state`, `workStatus`, `startDate`, `endedDate`.

**Private person** (sealed, scope `hr`): `email`, `phone`, `sex`, `birthday`, `about`,
`documentType`, `documentNumber`, `nationality`, `country`, `address`, `city`, `region`,
`postalCode`, `emergencyName`, `emergencyPhone`, `emergencyRelation`.

**Job**: `title`, `department`, `code` (employee code), `managerId`, `contract`, `workday`,
`startDate`, `endDate`, `workEmail`, `workPhone`; sealed (scope `hr`): `salary`,
`salaryCurrency`, `payPeriod`, `notes`.

**Lifecycle**: `state` (`invited` / `active` / `ended` / `declined` / `cancelled`), `invited`,
`responded`, `ending {date, reason, note}`, leaves `[ {id, type, startDate, endDate, days, note} ]`.

Vocabularies are the app's enums: `EmployeeContract`, `EmployeeWorkday`, `EmployeePayPeriod`,
`EmployeeEndReason`, `EmployeeDocument`, `EmployeeSex`, `EmployeeLeaveType`.

### Rules: reading

- **E-1** The list answers active and invited employments, **the viewer's own card first**
  (kept even when they have no employment, with `id: null`), then by name. `total` counts active
  ones only. Without `employees` it answers that card alone (plan §5.4). An
  invitation nobody activated yet carries the e-mail it was made for.
- **E-2** The former list (`ended`, `declined`, `cancelled`) needs `employees` and
  answers the same card shape.
- **E-3** The detail answers the card plus the job. Private and sealed fields are filled **only**
  when the viewer holds `employees` (the cloud has no separate key for personal data, `session.md`
  P-9) and the `hr` key **or** is that person
  (`fullProfile: true`); otherwise they're empty and `fullProfile: false`. The master leaves them
  out of the answer: they never reach a client that may not read them (plan §5.4).
- **E-4** Measured on read, never stored, all on the company's calendar day:
  - `workStatus`: `not_started` before `startDate`; the leave type when a leave covers today;
    `working` otherwise; `null` for anyone not active.
  - `contractStatus`: `pending` before `startDate`; `expiring` when `endDate` is within 30 days;
    `expired` when `endDate` passed and the job is still active; `current` otherwise; and the
    lifecycle state for closed employments.
  - `tenure` (`years`, `months`, `days`, `totalDays`) up to today or the end; `companySince` and
    `companyDays` across every stint of that account.
- **E-5** `upcomingLeaves`: the next five, soonest first.
- **E-6** `profileEditable` is true while the employment is `active` (the company writes the
  person's own profile, not a copy).
- **E-7** `salary: null` is "not filed", never zero.

### Rules: writing

- **E-10** `employees.invite` takes `email` **or** `username`, `jobTitle`, and optionally names.
  - An existing account → an `invited` employment. That person accepts from their pre-start
    screen (`employment.invitation` task) on their next sign in. (Only possible in hybrid or
    after a rehire: in `local`, accounts only exist through invitations.)
  - No such account → a `pending` account **and** an `invited` employment, and the answer
    carries the **activation code** (`session.md`, S-8) for the admin to hand over. The code is
    shown once.
  - Already active or invited here → `already_employed` / `already_invited`.
- **E-11** `employees.reissueActivation` (same permission) voids the old code and answers a new
  one. Only for `pending` accounts.
- **E-12** `employees.edit` writes the backend-style keys the app sends (`JOB_TITLE`,
  `MANAGER_ID`, `FIRST_NAME`, `SALARY`, …). A key sent empty clears it. Private-person keys are
  refused unless `profileEditable` (`profile_locked`). The op needs `employees.manage`, the
  cloud's key for inviting and editing a job. A closed employment isn't edited
  (`employment_closed`).
- **E-13** `profile.edit` lets a person write their **own** private data, with no company
  permission. The account is the session's, never a body field. The job is not theirs to write.
- **E-14** `MANAGER_ID` must be an invited or active employment of the company (the list the app
  offers), and not the person
  themselves or someone who reports to them (`manager_cycle`).
- **E-15** `SALARY` ≥ 0 with the currency's decimals; `SALARY_CURRENCY` must be the main or an
  exchange currency; `START_DATE` ≤ `END_DATE` (`invalid_dates`). Dates are calendar days.
- **E-16** Each sealed value is sealed on its own to the `hr` scope's public key and to the
  person's (plan §6.3), so writing one needs the permission, not a key. Reading needs the
  session's `hr` key or, for one's own, the person's key (a password session, not a PIN); without
  it the detail answers `fullProfile: false`. A value written before the person had a key pair
  (invited, never signed in) gets their copy the next time an `hr` holder reads it. Reads by an
  `hr` holder are recorded in the audit log **once per session per employee**, not on every read.
- **E-17** An account's e-mail is its sign-in name and is never written from here (as today).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `employees.list` | session (E-1 shapes it) | — | `{employees: [card], total}` | — |
| `employees.former` | `employees` | — | `[card]` | — |
| `employees.detail` | session: `employees`, or self | `id` | `BusinessEmployeeDetail` | `not_found` |
| `employees.invite` | `employees.manage` | `email` \| `username`, `jobTitle`, `firstName?`, `lastName?` | `{id, activation: {code, expires} \| null}` | `already_employed`, `already_invited`, `account_exists`, `invalid_field` |
| `employees.reissueActivation` | `employees.manage` | `id` | `{code, expires}` | `not_pending` |
| `employees.edit` | `employees.manage` | `id`, keys | `{}` | `employment_closed`, `profile_locked`, `manager_cycle`, `invalid_dates`, `invalid_field` |
| `profile.edit` | session | names and private keys | `{}` | `forbidden` (a job or pay key), `invalid_field` |
| `employees.accept` | session (the invited person) | `id` | `{}` | `not_found`, `not_invited` |

Cards and the detail use the spec's camelCase names (`lastName`, `jobTitle`, `contractStatus`);
the app's `EmployeesLanSource` maps them onto the keys its models read. An activation code leaves
the engine only in the answer that made it: the `commandId` ledger keeps that answer without it,
so a replay shows `activation: null` and the admin reissues. `employees.accept` serves a rehire
(an active account invited again). The bootstrap doesn't list that invitation as a pre-start task
yet, so in `local` a rehire waits until it does.

---

## Differences from cloud

- An invitation offline creates the account and hands over an activation code, instead of
  sending an e-mail.
- Salaries and private data are **sealed** on the master (plan §6.3): they can't be read while no
  one who may read them is signed in, which also rules out any unattended report on them.

## Open questions

1. ~~Showing the activation code.~~ Decided: a result sheet with the code and a "copy" button,
   reached only when the answer carries `activation` (built in phase 4).
2. ~~Leaves and job endings.~~ **Decided 2026-09-30:** planned for later. Until the app has a
   writer for them they stay empty in `local`, and their spec is written when the cloud builds
   them (plan principle 9).
3. ~~The HR permission.~~ Decided: `employees` holds the `hr` key (`session.md` P-9; it was the
   app's `view_personal` until the master took the cloud's permissions, 2026-10-04).
