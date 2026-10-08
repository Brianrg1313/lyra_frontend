import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/account/employment_record_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_history.dart';

/// The person's work history (`GET /profile/employments`) in their own settings: rows arrive
/// compressed with the company nested, a job held is "current" from its start, an ended one is
/// its range, and an invitation has no tenure to show.
void main() {
  setUpAll(() => ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000)));

  final table = {
    "keys": ["id", "business", "branch", "job_title", "department", "contract", "workday", "state",
      "start_date", "end_date", "ended_date", "tenure", "invited_date"],
    "values": [
      ["j-3", {"id": "b-3", "name": "Nueva SA", "logo": null}, null, "Cashier", "", null, null, "invited",
        null, null, null, null, "2026-10-01T10:00:00Z"],
      ["j-2", {"id": "b-2", "name": "Panadería Sol", "logo": null}, "Centro", "Manager", "Sales", "permanent", "full_time", "active",
        "2025-03-01", null, null, {"years": 1, "months": 7, "days": 5, "total_days": 584}, "2025-02-20T09:00:00Z"],
      ["j-1", {"id": "b-1", "name": "Ferretería Luz", "logo": null}, null, "Clerk", "", "fixed_term", null, "ended",
        "2023-01-10", "2023-12-31", "2024-02-29", {"years": 1, "months": 1, "days": 19, "total_days": 415}, "2023-01-02T09:00:00Z"],
      [null, {"id": "b-0"}, null, "", "", null, null, "ended", null, null, null, null, null]
    ]
  };

  test('rows are read by name, the company nested, a row without an id dropped', () {
    final jobs = EmploymentRecord.listFrom(table);

    expect(jobs.map((job) => job.id), ["j-3", "j-2", "j-1"]);
    expect(jobs[1].businessName, "Panadería Sol");
    expect(jobs[1].branch, "Centro");
    expect(jobs[1].contract, EmployeeContract.permanent);
    expect(jobs[1].state, EmployeeState.active);
    expect(jobs[1].tenure?.years, 1);
    expect(jobs[2].endedDate, DateTime(2024, 2, 29));
    expect(jobs[0].tenure, isNull);
  });

  testWidgets('the block names each company with where the person stands in it', (tester) async {
    final service = AccountHistoryService()..seed(table);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: ChangeNotifierProvider<AccountHistoryService>.value(
        value: service,
        child: Builder(builder: (context) {
          AppSize.instance(context);
          return const Material(child: SingleChildScrollView(child: SizedBox(width: 480, child: OwnHistory())));
        })
      )
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Panadería Sol"), findsOneWidget);
    expect(find.text("Manager · Sales · Centro"), findsOneWidget);
    expect(find.text("Current"), findsOneWidget);
    expect(find.text("Former"), findsOneWidget);
    expect(find.text("Invitation pending"), findsOneWidget);
    expect(find.textContaining("Since"), findsOneWidget);
  });

  test('nothing listed is empty, not an error', () {
    final service = AccountHistoryService()..seed({"keys": ["id"], "values": []});

    expect(service.status, AccountHistoryStatus.empty);
  });
}
