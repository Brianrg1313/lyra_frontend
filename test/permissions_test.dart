import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/permissions/permissions_service.dart';

/// `/init`'s `permissions`: per company, only what is granted, nested. A lookup is a walk and
/// anything absent on the path is denied, so the app hides what would be a 403.
Map<String, dynamic> _payload() => {
  "b-1": {
    "business": {"view": true, "employees": {"view": true, "invite": true}},
    "sales": {"view": true, "process": {"view": true}}
  },
  "b-2": {
    "pos": {"view": true, "sell": true}
  }
};

void main() {
  tearDown(() => PermissionsService().clear());

  test('nothing is hidden before /init brings permissions', () {
    expect(PermissionsService().isLoaded, isFalse);
    expect(PermissionsService().can("finance.payments.record", business: "b-1"), isTrue);
  });

  group('once seeded', () {
    setUp(() => PermissionsService().seed(_payload()));

    test('a granted action is allowed, per company', () {
      final permissions = PermissionsService();

      expect(permissions.can("business.employees.invite", business: "b-1"), isTrue);
      expect(permissions.canOpen("sales.process", business: "b-1"), isTrue);
      expect(permissions.can("pos.sell", business: "b-2"), isTrue);
      expect(permissions.can("pos.sell", business: "b-1"), isFalse);
    });

    test('anything absent on the path is denied', () {
      final permissions = PermissionsService();

      expect(permissions.can("business.settings.edit", business: "b-1"), isFalse);
      expect(permissions.canOpen("finance", business: "b-1"), isFalse);
      expect(permissions.can("sales.done.view", business: "b-1"), isFalse);
      expect(permissions.can("sales.view", business: "unknown"), isFalse);
    });

    test('an area is not an action', () {
      expect(PermissionsService().can("business.employees", business: "b-1"), isFalse);
    });

    test('account areas never depend on a company', () {
      expect(PermissionsService().canOpen("dashboard", business: "b-2"), isTrue);
    });

    test('a company created in this session grants everything', () {
      PermissionsService().own("b-3");

      expect(PermissionsService().can("finance.methods.delete", business: "b-3"), isTrue);
    });

    test('clear forgets every grant', () {
      PermissionsService().clear();

      expect(PermissionsService().isLoaded, isFalse);
    });
  });
}
