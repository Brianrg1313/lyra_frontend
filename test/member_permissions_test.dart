import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/client/sources/session_lan_source.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/permissions/member_permissions_service.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/sources/permissions_lan_source.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/screens/home/sections/business/employees/employee_permissions.dart';

/// The permissions editor on the cloud's catalog (`docs/offline/specs/session.md`
/// session.permissions): the draft keeps the backend's rules, a save sends only what changed, and
/// a master's answers read as the cloud's. The rules themselves are the backend's and
/// `lyra_node/test/permissions_test.dart`'s.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  test('the editor draws every section of the catalog, in its order', () {
    expect([for (final section in PermissionSection.values) section.name], PermissionCatalog.sections.keys.toList());
  });

  group('MemberPermissionsService', () {
    test('an action turns its section on; closing a section clears only the actions the viewer holds', () async {
      final source = _Source(
        mine: Grant(sections: PermissionCatalog.fromKeys(["money", "money.charge", "money.void"])),
        member: _member(keys: ["money", "money.accounts"])
      );
      final service = MemberPermissionsService(username: "rosa", source: source);
      await service.load();

      expect(service.canChange("money.accounts"), isFalse);

      service.toggle("money", "access");
      expect(service.flag("money", "access"), isFalse);
      // Not the viewer's to take away: it stays stored, granting nothing.
      expect(service.flag("money", "accounts"), isTrue);

      service.toggle("money", "void");
      expect(service.flag("money", "access"), isTrue);
      expect(service.flag("money", "void"), isTrue);

      // Something the viewer does not hold is never toggled.
      service.toggle("pos", "access");
      expect(service.flag("pos", "access"), isFalse);
    });

    test('a save sends only the flags that differ from what the member had', () async {
      final source = _Source(mine: Grant.everything(), member: _member(keys: ["pos", "pos.sell"]));
      final service = MemberPermissionsService(username: "rosa", source: source);
      await service.load();

      expect(service.dirty, isFalse);
      service.toggle("pos", "cancel");
      service.toggle("sales", "fulfill");
      expect(service.dirty, isTrue);

      await service.save();

      expect(source.assigned.single.template, isNull);
      expect(source.assigned.single.permissions, {"pos": {"cancel": true}, "sales": {"access": true, "fulfill": true}});
      // Re-read after the write: the draft is what is stored now.
      expect(source.reads, 2);
      expect(service.dirty, isFalse);
    });

    test('a template is sent by id, with the changes made over it', () async {
      final seller = PermissionTemplateModel(
        id: "seller",
        scope: "global",
        name: "Seller",
        grant: Grant(sections: PermissionPresets.byCode("seller")!.sections)
      );
      final source = _Source(mine: Grant.everything(), member: _member(keys: []), templates: [seller]);
      final service = MemberPermissionsService(username: "rosa", source: source);
      await service.load();

      service.apply(seller);
      expect(service.flag("pos", "sell"), isTrue);
      service.toggle("pos", "cancel");
      await service.save();

      expect(source.assigned.single.template, "seller");
      expect(source.assigned.single.permissions, {"pos": {"cancel": true}});
    });

    test('a template that changes a key the viewer lacks is not offered, nor is `all` without `all`', () async {
      final finance = PermissionTemplateModel(
        id: "finance",
        scope: "global",
        name: "Finance",
        grant: Grant(sections: PermissionPresets.byCode("finance")!.sections)
      );
      final owner = PermissionTemplateModel(id: "owner", scope: "global", name: "Owner", grant: Grant.everything());
      final source = _Source(
        mine: Grant(sections: PermissionPresets.byCode("manager")!.sections),
        member: _member(keys: []),
        templates: [finance, owner]
      );
      final service = MemberPermissionsService(username: "rosa", source: source);
      await service.load();

      expect(service.canApply(finance), isFalse, reason: "a manager holds no money.accounts");
      expect(service.canApply(owner), isFalse);
    });

    test('nothing changes for the viewer themselves, the owner, or an `all` member seen without `all`', () async {
      Future<MemberPermissionsService> open(PermissionMemberModel member, Grant mine) async {
        final service = MemberPermissionsService(username: member.username, source: _Source(mine: mine, member: member));
        await service.load();
        return service;
      }

      final manager = Grant(sections: PermissionPresets.byCode("manager")!.sections);

      expect((await open(_member(keys: [], me: true), Grant.everything())).readOnly, isTrue);
      expect((await open(_member(keys: [], owner: true), Grant.everything())).readOnly, isTrue);
      expect((await open(_member(keys: [], all: true), manager)).readOnly, isTrue);
      expect((await open(_member(keys: [], all: true), Grant.everything())).readOnly, isFalse);
    });

    test('someone with a job and no access yet is let in by a save with nothing ticked', () async {
      final source = _Source(mine: Grant.everything(), member: _member(keys: [], access: false));
      final service = MemberPermissionsService(username: "rosa", source: source);
      await service.load();

      expect(service.dirty, isTrue);
      await service.save();

      expect(source.assigned.single.username, "rosa");
      expect(source.assigned.single.template, isNull);
      expect(source.assigned.single.permissions, isEmpty);
    });

    test('revoking takes the access away and re-reads the member', () async {
      final source = _Source(mine: Grant.everything(), member: _member(keys: ["pos"]));
      final service = MemberPermissionsService(username: "rosa", source: source);
      await service.load();

      await service.revoke();

      expect(source.revoked, ["rosa"]);
      expect(source.reads, 2);
    });

    test('without a username it is the viewer\'s own, read-only', () async {
      final service = MemberPermissionsService(source: _Source(mine: Grant(sections: PermissionCatalog.fromKeys(["pos", "pos.sell"]))));
      await service.load();

      expect(service.readOnly, isTrue);
      expect(service.flag("pos", "sell"), isTrue);
      expect(service.templates, isEmpty);
    });
  });

  group('EmployeePermissions', () {
    testWidgets("one's own permissions only show", (tester) async {
      _size(tester);
      await tester.pumpWidget(_app(EmployeePermissions(
        source: _Source(mine: Grant(sections: PermissionCatalog.fromKeys(["pos", "pos.sell"])))
      )));
      await tester.pumpAndSettle();

      expect(find.text("These are your permissions in this business. Only someone who manages the team can change them."), findsOneWidget);
      expect(find.text("Sell and charge tickets"), findsOneWidget);
      expect(find.byType(FeedbackButton), findsNothing);
    });

    testWidgets('a switch makes a draft, and saving sends it', (tester) async {
      _size(tester);
      final source = _Source(mine: Grant.everything(), member: _member(keys: []));

      await tester.pumpWidget(_app(EmployeePermissions(username: "rosa", person: "Rosa", source: source)));
      await tester.pumpAndSettle();

      expect(find.text("Remove access"), findsOneWidget);

      await tester.tap(find.byWidgetPredicate((widget) => widget is FeedbackButton && widget.message == "Cancel tickets: Point of sale"));
      await tester.pumpAndSettle();
      expect(find.text("Remove access"), findsNothing);

      await tester.tap(find.text("Save"));
      await tester.pumpAndSettle();

      expect(source.assigned.single.permissions, {"pos": {"access": true, "cancel": true}});
    });
  });

  group('over a master', () {
    test('a member reads as the cloud\'s, and an assignment travels in the op\'s keys', () async {
      final master = _Master()..answers[Ops.permissionsMembersDetail.name] = {
        "username": "rosa",
        "name": "Rosa",
        "lastName": "Díaz",
        "me": false,
        "owner": false,
        "all": false,
        "template": {"scope": "global", "id": "seller", "name": "Seller"},
        "custom": true,
        "access": true,
        "sections": PermissionCatalog.fromKeys(["pos", "pos.sell"])
      };
      final source = PermissionsLanSource(master);

      final member = await source.member("rosa");
      expect(member.lastName, "Díaz");
      expect(member.template?.id, "seller");
      expect(member.custom, isTrue);
      expect(member.grant.can("pos.sell"), isTrue);
      expect(master.calls.single.$1, Ops.permissionsMembersDetail.name);
      expect(master.calls.single.$2, {"username": "rosa"});

      await source.assign("rosa", template: "seller", permissions: {"pos": {"cancel": true}});
      expect(master.calls.last.$1, Ops.permissionsMembersAssign.name);
      expect(master.calls.last.$2, {
        "username": "rosa",
        "template": "seller",
        "permissions": {"pos": {"cancel": true}}
      });
    });

    test("the viewer's own requests are listed", () async {
      final master = _Master()..answers[Ops.permissionsRequestsList.name] = [
        {"id": "r-1", "permission": "finance.view", "reason": null, "state": "pending", "created": "2026-10-04T10:00:00.000Z"}
      ];

      final requests = await SessionLanSource(master).permissionRequests();

      expect(requests.single.permission, "finance.view");
      expect(requests.single.createdAt, DateTime.utc(2026, 10, 4, 10));
    });
  });
}

PermissionMemberModel _member({required List<String> keys, bool me = false, bool owner = false, bool all = false, bool access = true}) =>
  PermissionMemberModel(
    username: "rosa",
    name: "Rosa",
    me: me,
    owner: owner,
    access: access,
    grant: Grant(all: owner || all, sections: PermissionCatalog.fromKeys(keys))
  );

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [S.delegate, GlobalWidgetsLocalizations.delegate, GlobalMaterialLocalizations.delegate],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: child);
  })
);

class _Source implements PermissionsSource {
  _Source({required Grant mine, PermissionMemberModel? member, List<PermissionTemplateModel> templates = const []})
    : _mine = mine, _member = member, _templates = templates;

  final Grant _mine;
  final PermissionMemberModel? _member;
  final List<PermissionTemplateModel> _templates;

  final assigned = <({String username, String? template, Map<String, Map<String, bool>>? permissions})>[];
  final revoked = <String>[];
  int reads = 0;

  @override
  Future<Grant> mine() async => _mine;

  @override
  Future<List<PermissionTemplateModel>> templates() async => _templates;

  @override
  Future<PermissionMemberModel> member(String username) async {
    reads++;
    return _member!;
  }

  @override
  Future<void> assign(String username, {String? template, Map<String, Map<String, bool>>? permissions}) async =>
    assigned.add((username: username, template: template, permissions: permissions));

  @override
  Future<void> revoke(String username) async => revoked.add(username);
}

class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final List<(String, Map<String, Object?>)> calls = [];

  @override
  LanStatus get status => LanStatus.ready;

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));

    return answers[op.name];
  }
}
