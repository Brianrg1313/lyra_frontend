import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/business/employee_activation_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/screens/home/sections/business/employees/_employees.dart';
import 'package:app/screens/home/sections/business/employees/employee_edit.dart';
import 'package:app/screens/modals/business/invite_employee/_invite_employee.dart';

/// The employees tab is two panels: the people on the left — the viewer's own
/// card always first — and the selected person's detail on the right. The
/// first read opens the viewer's card; touching another row opens theirs.
///
/// The detail is edited in place, one backend key per save, and only what the
/// company may still write opens a field. A typed change travels with the
/// check or Enter, never by clicking away; a phone is a code and digits, a day
/// its three parts.
///
/// Also pins the list and detail parse: the rows arrive compressed, the
/// viewer's card goes first whatever order they came in (and survives without
/// an employment id), and a withheld profile is not an empty one.

/// The service with the reads already answered: asking for real would hit the
/// backend.
class _Employees extends BusinessEmployeesService {
  int loads = 0;
  final List<String> details = [];
  final List<(String, String, String?)> invites = [];

  /// What [inviteTemplates] offers; none, as for a viewer who may not give permissions.
  List<PermissionTemplateModel> templates = const [];

  @override
  Future<List<PermissionTemplateModel>> inviteTemplates() async => templates;

  @override
  Future<void> load({bool force = false}) async => loads++;

  @override
  Future<void> loadDetail(String id, {bool force = false}) async => details.add(id);

  /// What an invitation answers: a master's activation code when set.
  EmployeeActivation? activation;

  @override
  Future<EmployeeInvitationSent?> invite(BuildContext context, {
    required String email,
    required String jobTitle,
    String? template
  }) async {
    invites.add((email, jobTitle, template));
    return (id: null, activation: activation);
  }

  /// Every write, whichever endpoint it took; [ownEdits] the ids that went
  /// through the viewer's own profile.
  final List<(String, Map<String, dynamic>)> edits = [];
  final List<String> ownEdits = [];

  @override
  Future<bool> edit(BuildContext context, String id, Map<String, dynamic> changes) async {
    edits.add((id, changes));
    return true;
  }

  @override
  Future<bool> editOwn(BuildContext context, String id, Map<String, dynamic> changes) async {
    ownEdits.add(id);
    return edit(context, id, changes);
  }
}

/// A field that takes typing: the header's name is a read-only one.
final _field = find.byWidgetPredicate((widget) => widget is EditableText && !widget.readOnly);

/// The field of an open tile, not the panel's search box.
final _tile = find.descendant(of: find.byType(EmployeeEditFrame), matching: _field);

/// A detail, the viewer's (`e-1`) unless [id] says otherwise, active and with
/// the whole profile; [editable] says whether the company may still write it.
BusinessEmployeeDetail _detail({String id = "e-1", bool editable = true}) => BusinessEmployeeDetail.from({
  "id": id,
  "state": "active",
  "work_status": "working",
  "visibility": "full",
  "profile_editable": editable,
  "person": {
    "username": "ana",
    "name": "Ana",
    "last_name": "Ruiz",
    "phone": "+584120000000",
    "country": "VE",
    "postal_code": "1050",
    "birthday": "1990-03-04"
  },
  "job": {"job_title": "Owner"}
})!;

Widget _app(BusinessEmployeesService service, {double width = 1400}) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessEmployeesService>.value(value: service),
      // App-wide in the app: the country fields pick from it.
      ChangeNotifierProvider<CountryCatalogService>.value(value: CountryCatalogService()),
      // App-wide too: a phone with no code is offered the company's.
      ChangeNotifierProvider<BusinessService>(create: (_) => BusinessService()),
      // App-wide too: the actions offer someone else's permissions only with the grant.
      ChangeNotifierProvider<PermissionsService>.value(value: PermissionsService())
    ],
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: SizedBox(width: width, child: const BusinessEmployeesTab()));
    })
  )
);

const _me = BusinessEmployeeModel(
  id: "e-1",
  me: true,
  username: "ana",
  name: "Ana",
  lastName: "Ruiz",
  jobTitle: "Owner",
  state: EmployeeState.active,
  workStatus: EmployeeWorkStatus.working
);

const _luis = BusinessEmployeeModel(
  id: "e-2",
  username: "luis",
  name: "Luis",
  lastName: "Mora",
  jobTitle: "Cashier",
  state: EmployeeState.invited
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    CountryCatalogService().seed({
      "keys": ["code", "name", "phone", "currency", "flag"],
      "values": [["VE", "Venezuela", "58", "VES", "flag-ve"]]
    });
  });

  group('list parse', () {
    test('the viewer goes first, even when it came later', () {
      final rows = BusinessEmployeeModel.listFrom({
        "keys": ["id", "me", "username", "name", "last_name", "state", "work_status"],
        "values": [
          ["e-2", false, "luis", "Luis", "Mora", "invited", null],
          ["e-1", true, "ana", "Ana", "Ruiz", "active", "vacation"]
        ]
      });

      expect(rows.map((row) => row.id), ["e-1", "e-2"]);
      expect(rows.first.me, isTrue);
      expect(rows.first.workStatus?.kind, EmployeeWorkKind.away);
      expect(rows.first.workStatus?.leave, EmployeeLeaveType.vacation);
      expect(rows.last.workStatus, isNull);
    });

    test('the viewer with no job filed keeps a card; a row with no id otherwise is dropped', () {
      final rows = BusinessEmployeeModel.listFrom([
        {"id": null, "me": true, "username": "ana", "state": null},
        {"id": null, "me": false, "username": "ghost"}
      ]);

      expect(rows, hasLength(1));
      expect(rows.single.id, isNull);
      expect(rows.single.key, BusinessEmployeeModel.meKey);
      expect(rows.single.state, isNull);
    });

    test('an invitation to an email with no account is named by that email', () {
      final rows = BusinessEmployeeModel.listFrom([
        {"id": "e-3", "username": "9f2c0a7b", "name": null, "email": "rosa@mail.com", "state": "invited"},
        {"id": "e-4", "username": "pedro", "name": null}
      ]);

      expect(rows.first.fullName, "rosa@mail.com");
      expect(rows.last.fullName, "pedro");
    });

    test('former rows are ended and never the viewer', () {
      final rows = BusinessEmployeeModel.listFrom(
        [{"id": "e-9", "me": true, "username": "old", "ended_date": "2025-12-31"}],
        former: true
      );

      expect(rows.single.state, EmployeeState.ended);
      expect(rows.single.me, isFalse);
      expect(rows.single.endedDate, DateTime(2025, 12, 31));
    });
  });

  group('detail parse', () {
    test('a card-only profile is withheld and a missing salary is not zero', () {
      final detail = BusinessEmployeeDetail.from({
        "id": "e-2",
        "state": "invited",
        "contract_status": "pending",
        "visibility": "card",
        "person": {"username": "luis", "name": "Luis", "last_name": "Mora"},
        "job": {"job_title": "Cashier", "salary": null, "branch": {"id": "b-1", "name": "Center"}},
        "tenure": {"years": 0, "months": 0, "days": 0, "total_days": 0},
        "company_tenure": {"since": null, "total_days": 0},
        "upcoming_leaves": []
      })!;

      expect(detail.fullProfile, isFalse);
      expect(detail.contractStatus, EmployeeContractStatus.pending);
      expect(detail.job.salary, isNull);
      expect(detail.job.branchName, "Center");
      expect(detail.person.fullName, "Luis Mora");
    });

    test('the running leave and the upcoming ones are read', () {
      final detail = BusinessEmployeeDetail.from({
        "id": "e-1",
        "state": "active",
        "work_status": "sick",
        "visibility": "full",
        "job": {"salary": "1200.50", "salary_currency": "usd", "pay_period": "month"},
        "leave": {"id": "l-1", "type": "sick", "start_date": "2026-09-20", "end_date": "2026-09-27", "days": 8},
        "upcoming_leaves": [
          {"id": "l-2", "type": "vacation", "start_date": "2026-12-20", "end_date": "2027-01-02", "days": 14},
          {"type": "vacation"}
        ],
        "company_tenure": {"since": "2020-01-15", "total_days": 2400}
      })!;

      expect(detail.fullProfile, isTrue);
      expect(detail.workStatus?.leave, EmployeeLeaveType.sick);
      expect(detail.leave?.days, 8);
      expect(detail.upcomingLeaves.map((leave) => leave.id), ["l-2"]);
      expect(detail.job.salary, 1200.5);
      expect(detail.job.salaryCurrency, "USD");
      expect(detail.job.payPeriod, EmployeePayPeriod.month);
      expect(detail.companySince, DateTime(2020, 1, 15));
      expect(detail.companyDays, 2400);
    });
  });

  // Before the tab's tests: those leave their services alive, and a live one
  // takes the request.
  group('own card', () {
    test('the side bar\'s profile opens the viewer\'s card, now or at the first read', () {
      final open = _Employees()..seed(current: [_me, _luis], total: 1);

      open.select("e-2");
      BusinessEmployeesService.openOwn();
      expect(open.selectedKey, "e-1");

      // Asked with no page mounted: the remembered person gives way at the
      // next one's first read.
      open.dispose();
      BusinessEmployeesService.openOwn();
      final later = _Employees();
      addTearDown(later.dispose);
      later.seed(current: [_luis, _me], total: 1);
      expect(later.selectedKey, "e-1");
    });
  });

  group('tab', () {
    testWidgets('asks for the people when it opens', (tester) async {
      final service = _Employees();

      await tester.pumpWidget(_app(service));
      // No `pumpAndSettle`: while it loads the tab shows the spinner, which
      // never stops animating.
      await tester.pump();

      expect(service.loads, 1);
    });

    testWidgets('opens on the viewer, first in the list, and a tap switches the detail', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final service = _Employees()..seed(current: [_me, _luis], total: 1);

      await tester.pumpWidget(_app(service));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(service.selectedKey, "e-1");
      expect(service.details, ["e-1"]);

      // The viewer's row is above the invited one.
      final ana = tester.getTopLeft(find.text("Ana Ruiz").first);
      final luis = tester.getTopLeft(find.text("Luis Mora"));
      expect(ana.dy, lessThan(luis.dy));

      await tester.tap(find.text("Luis Mora"));
      await tester.pump();
      await tester.pump();

      expect(service.selectedKey, "e-2");
      expect(service.details, ["e-1", "e-2"]);
      // The name now shows twice: in its row and in the detail header.
      expect(find.text("Luis Mora"), findsNWidgets(2));
    });

    testWidgets('the heading offers to invite', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_Employees()..seed(current: [_me], total: 1)));
      await tester.pump();

      expect(find.text("Invite"), findsOneWidget);
    });

    testWidgets('without the view it is only the own profile: no invite or counts, its own actions', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(PermissionsService().clear);

      businessService.seed({"keys": ["id", "name"], "values": [["b-1", "One"]]});
      PermissionsService().seed({"b-1": {"business": {"view": true}}});

      final service = _Employees()..seed(current: [_me], total: 1, details: [_detail()]);

      await tester.pumpWidget(_app(service));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(service.selectedKey, "e-1");
      expect(find.text("Invite"), findsNothing);
      expect(find.text("1 active"), findsNothing);
      // Their own permissions, settings, activity: to look at.
      expect(find.text("Permissions"), findsOneWidget);
    });

    // Mounted directly, like the other modal tests: `showModal` picks the
    // phone sheet under the test binding.
    testWidgets('the invite form sends the email, lowercased, and the job title', (tester) async {
      final service = _Employees();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (context) {
          AppSize.instance(context);

          return Scaffold(body: Center(child: InviteEmployeeModal(employees: service)));
        })
      ));
      await tester.pump();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), "Rosa@Mail.com");
      await tester.enterText(fields.at(1), "Cashier");
      await tester.tap(find.text("Send invitation"));
      await tester.pump();

      expect(service.invites, [("rosa@mail.com", "Cashier", null)]);
      expect(find.text("Permissions"), findsNothing);
    });

    testWidgets('the invite form sends the permissions template picked', (tester) async {
      final service = _Employees()..templates = [
        PermissionTemplateModel(id: "seller", scope: "global", name: "seller", grant: Grant.none()),
        PermissionTemplateModel(id: "t-1", scope: "company", name: "Night shift", grant: Grant.none())
      ];

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (context) {
          AppSize.instance(context);

          return Scaffold(body: Center(child: InviteEmployeeModal(employees: service)));
        })
      ));
      await tester.pump();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), "rosa@mail.com");
      await tester.enterText(fields.at(1), "Cashier");
      await tester.tap(find.byWidgetPredicate((widget) => widget is SelectInput));
      await tester.pump();
      await tester.tap(find.descendant(of: find.byType(SelectOptionTile), matching: find.text("Night shift")));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text("Send invitation"));
      await tester.pump();

      expect(service.invites, [("rosa@mail.com", "Cashier", "t-1")]);
    });

    testWidgets('a master\'s invitation gives way to its activation code, shown once (E-10)', (tester) async {
      final service = _Employees()..activation = EmployeeActivation(code: "12345678", expires: DateTime(2026, 10, 4, 9));

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (context) {
          AppSize.instance(context);

          return Scaffold(body: Center(child: InviteEmployeeModal(employees: service)));
        })
      ));
      await tester.pump();

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), "rosa@mail.com");
      await tester.enterText(fields.at(1), "Cashier");
      await tester.tap(find.text("Send invitation"));
      await tester.pump();

      expect(find.text("1234 5678"), findsOneWidget);
      expect(find.text("Copy code"), findsOneWidget);
      expect(find.text("Send invitation"), findsNothing);

      // The tapped button's feedback.
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('a narrow panel drops the contract and date columns without overflowing', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final service = _Employees()..seed(current: [_me, _luis], total: 1);

      await tester.pumpWidget(_app(service, width: 800));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("Contract"), findsNothing);
      expect(find.text("Waiting to accept"), findsOneWidget);
    });

    testWidgets('groups people by where they are today; only a leave gets its own tag', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final rosa = BusinessEmployeeModel(
        id: "e-3",
        username: "rosa",
        name: "Rosa",
        lastName: "Paz",
        state: EmployeeState.active,
        workStatus: EmployeeWorkStatus.from("vacation")
      );
      final service = _Employees()..seed(current: [_me, _luis, rosa], total: 2);

      await tester.pumpWidget(_app(service));
      await tester.pump();

      expect(tester.takeException(), isNull);

      double top(String text) => tester.getTopLeft(find.text(text).first).dy;

      // Working, then away, then waiting — the viewer first in its group.
      expect(top("Working today"), lessThan(top("Ana Ruiz")));
      expect(top("Ana Ruiz"), lessThan(top("Away today")));
      expect(top("Away today"), lessThan(top("Rosa Paz")));
      expect(top("Rosa Paz"), lessThan(top("Waiting to accept")));
      expect(top("Waiting to accept"), lessThan(top("Luis Mora")));
      expect(find.text("On vacation"), findsOneWidget);
    });

    testWidgets('draws a loaded detail without overflowing', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final service = _Employees()..seed(
        current: [_me, _luis],
        total: 1,
        details: [BusinessEmployeeDetail.from({
          "id": "e-1",
          "state": "active",
          "contract_status": "expiring",
          "work_status": "working",
          "visibility": "full",
          "person": {"username": "ana", "name": "Ana", "last_name": "Ruiz", "email": "ana@example.com"},
          "job": {"job_title": "Owner", "contract": "fixed_term", "notes": "Keys to the store"},
          "tenure": {"years": 2, "months": 3, "days": 4, "total_days": 824},
          "invited_date": "2024-06-01T12:00:00.000Z",
          "responded": "2024-06-01T12:00:00.000Z"
        })!]
      );

      await tester.pumpWidget(_app(service));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("ana@example.com"), findsOneWidget);
      expect(find.text("Contract ending soon"), findsOneWidget);
      expect(find.text("2 years, 3 months"), findsOneWidget);
    });
  
    testWidgets('personal data goes first, above the job', (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final service = _Employees()..seed(current: [_me, _luis], total: 1, details: [_detail()]);

      await tester.pumpWidget(_app(service));
      await tester.pump();

      expect(tester.getTopLeft(find.text("Personal data")).dy, lessThan(tester.getTopLeft(find.text("Job")).dy));
      expect(find.text("First name"), findsOneWidget);
      expect(find.text("Last name"), findsOneWidget);
    });

    testWidgets('a typed field is edited in its tile and Enter sends only its key', (tester) async {
      final service = await _open(tester);

      await tester.tap(find.text("1050"));
      await tester.pump();

      // No modal: the field opens where the value was, and takes digits only.
      expect(_tile, findsOneWidget);

      await tester.enterText(_tile, "10a70");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(service.edits.single.$1, "e-1");
      expect(service.edits.single.$2, {"POSTAL_CODE": "1070"});
      expect(_tile, findsNothing);
      // The viewer's own personal data travels through their profile.
      expect(service.ownEdits, ["e-1"]);
    });

    testWidgets('the viewer edits their own personal data without any permission', (tester) async {
      addTearDown(PermissionsService().clear);
      businessService.seed({"keys": ["id", "name"], "values": [["b-1", "One"]]});
      PermissionsService().seed({"b-1": {"business": {"view": true}}});

      final service = await _open(tester);

      await tester.tap(find.text("1050"));
      await tester.pump();
      await tester.enterText(_tile, "1070");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(service.ownEdits, ["e-1"]);
      expect(service.edits.single.$2, {"POSTAL_CODE": "1070"});
    });

    testWidgets('a click outside drops the change; the check sends it', (tester) async {
      final service = await _open(tester);

      await tester.tap(find.text("1050"));
      await tester.pump();
      await tester.enterText(_tile, "2000");
      await tester.pump();

      await tester.tap(find.text("Personal data"));
      await tester.pump();

      expect(service.edits, isEmpty);
      expect(_tile, findsNothing);
      expect(find.text("1050"), findsOneWidget);

      await tester.tap(find.text("1050"));
      await tester.pump();
      await tester.enterText(_tile, "2000");
      await tester.pump();

      await tester.tap(find.byIcon(CI.check));
      await tester.pump();

      expect(service.edits.single.$2, {"POSTAL_CODE": "2000"});
      expect(_tile, findsNothing);
    });

    testWidgets('picking a country code keeps the phone open', (tester) async {
      final service = await _open(tester);

      await tester.tap(find.text("+584120000000"));
      await tester.pump();
      await tester.pump();

      // The code list hangs outside the tile; a pick there is not leaving.
      await tester.tap(find.byWidgetPredicate((widget) => widget is SelectInput));
      await tester.pump();
      await tester.tap(find.descendant(of: find.byType(SelectOptionTile), matching: find.text("Venezuela")));
      await tester.pump();
      await tester.pump();

      expect(_tile, findsWidgets);

      await tester.tap(find.text("Personal data"));
      await tester.pump();

      expect(_tile, findsNothing);
      expect(service.edits, isEmpty);
    });

    testWidgets('the check shows only once the field differs from what is saved', (tester) async {
      await _open(tester);

      await tester.tap(find.text("1050"));
      await tester.pump();

      expect(find.byIcon(CI.check), findsNothing);

      await tester.enterText(_tile, "1051");
      await tester.pump();

      expect(find.byIcon(CI.check), findsOneWidget);

      await tester.enterText(_tile, "1050");
      await tester.pump();

      expect(find.byIcon(CI.check), findsNothing);
    });

    testWidgets('the search keeps the tiles that match, by name or value, accents aside', (tester) async {
      await _open(tester);

      expect(find.text("Postal code"), findsOneWidget);

      await tester.enterText(_field.first, "codigo postal");
      await tester.pump();

      // Nothing is called that in English: nothing but the box is left.
      expect(find.text("Postal code"), findsNothing);

      await tester.enterText(_field.first, "postal");
      await tester.pump();

      expect(find.text("Postal code"), findsOneWidget);
      expect(find.text("Personal data"), findsOneWidget);
      expect(find.text("First name"), findsNothing);
      expect(find.text("Job"), findsNothing);

      await tester.enterText(_field.first, "ruiz");
      await tester.pump();

      expect(find.text("Last name"), findsOneWidget);
      expect(find.text("Postal code"), findsNothing);

      // A section's title shows it whole.
      await tester.enterText(_field.first, "job");
      await tester.pump();

      expect(find.text("Job"), findsOneWidget);
      expect(find.text("Postal code"), findsNothing);
    });

    testWidgets('a phone keeps its country code and types only the number', (tester) async {
      final service = await _open(tester);

      await tester.tap(find.text("+584120000000"));
      await tester.pump();
      await tester.pump();

      expect(find.text("4120000000"), findsOneWidget);

      await tester.enterText(_tile.last, "4149999999");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(service.edits.single.$2, {"PHONE": "+584149999999"});
    });

    testWidgets('a day is edited as day, month and year', (tester) async {
      final service = await _open(tester);

      await tester.tap(find.text("Birthday"));
      await tester.pump();
      await tester.pump();

      expect(find.text("March"), findsOneWidget);

      await tester.enterText(_tile.first, "5");
      await tester.enterText(_tile.last, "1991");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(service.edits.single.$2, {"BIRTHDAY": "1991-03-05"});
    });

    testWidgets("another's profile the company may not write is read, not edited", (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final service = _Employees()
        ..seed(current: [_me, _luis], total: 1, details: [_detail(id: "e-2", editable: false)])
        ..select("e-2");

      await tester.pumpWidget(_app(service));
      await tester.pump();

      // A tap copies the phone instead of opening a field.
      await tester.tap(find.text("+584120000000"));
      await tester.pump();

      expect(_tile, findsNothing);
      expect(service.edits, isEmpty);
    });
  });
}

/// Opens the viewer's editable detail on a screen tall enough to hold it.
Future<_Employees> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final service = _Employees()..seed(current: [_me, _luis], total: 1, details: [_detail()]);

  await tester.pumpWidget(_app(service));
  await tester.pump();

  return service;
}
