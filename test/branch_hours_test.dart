import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show Grant, PermissionCatalog;

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/screens/modals/business/branch_hours/_branch_hours.dart';
import 'package:app/screens/modals/shared/opening_hours/week_editor.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// A branch's hours edited from the branch itself (`sedes-frontend.md` §11):
/// its own week and closed days, editable only with `appointments.configure`.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  const branch = BusinessBranchModel(id: "b2", name: "Chacao");

  OpeningHoursService seeded() => OpeningHoursService(branch: "b2")..seed(
    const [OpeningStretch(weekday: 1, opens: 540, closes: 1080)],
    closures: const [ClosedDay(day: "2026-12-25", reason: "Navidad")]
  );

  Future<void> pump(WidgetTester tester, OpeningHoursService hours, List<String> keys) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

        return Scaffold(body: BranchHoursModal(
          branch: branch,
          hours: hours,
          grant: Grant(sections: PermissionCatalog.fromKeys(keys))
        ));
      })
    ));
    await tester.pump();
  }

  testWidgets("names the branch and lets the week and closed days be edited", (tester) async {
    final hours = seeded();

    await pump(tester, hours, ["appointments", "appointments.configure"]);

    expect(find.text(S.current.branch_hours_subtitle("Chacao")), findsOneWidget);
    expect(find.text(S.current.shipping_week_title), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is SettingsAction && w.message == S.current.shipping_week_add), findsNWidgets(7));
    expect(find.text(S.current.shipping_closed_add), findsOneWidget);
    expect(find.text("2026-12-25"), findsOneWidget);
    hours.dispose();
  });

  testWidgets("without appointments.configure the hours are only read", (tester) async {
    final hours = seeded();

    await pump(tester, hours, ["appointments"]);

    expect(find.text("09:00–18:00"), findsOneWidget);
    expect(find.byType(SettingsAction), findsNothing);
    expect(find.text(S.current.shipping_closed_add), findsNothing);
    hours.dispose();
  });
  testWidgets("a week with weekday and weekend hours opens grouped, and is typed every day or day by day", (tester) async {
    final hours = OpeningHoursService(branch: "b2")..seed([
      for (final weekday in [1, 2, 3, 4, 5]) OpeningStretch(weekday: weekday, opens: 540, closes: 1080),
      for (final weekday in [6, 0]) OpeningStretch(weekday: weekday, opens: 600, closes: 840)
    ]);
    Finder adds() => find.byWidgetPredicate((w) => w is SettingsAction && w.message == S.current.shipping_week_add);

    await pump(tester, hours, ["appointments", "appointments.configure"]);

    expect(adds(), findsNWidgets(2));
    expect(find.text(S.current.shipping_week_range("Monday", "Friday")), findsOneWidget);
    expect(find.text(S.current.shipping_week_pair("Saturday", "Sunday")), findsOneWidget);

    await tester.tap(find.text(S.current.shipping_week_mode_every));
    await tester.pump();

    expect(adds(), findsOneWidget);
    expect(find.text(S.current.shipping_week_every), findsOneWidget);
    expect(find.text(S.current.save), findsOneWidget);

    await tester.tap(find.text(S.current.shipping_week_mode_daily));
    await tester.pump();

    // Every day took Monday's hours: Saturday now has them too.
    expect(adds(), findsNWidgets(7));
    expect(find.text("Saturday"), findsOneWidget);
    expect(find.text("10:00"), findsNothing);
    expect(find.text("09:00"), findsNWidgets(7));
    hours.dispose();
  });

  test("the mode a saved week opens on is the coarsest it fits", () {
    Map<int, List<(String, String)>> week(List<(String, String)> weekdays, List<(String, String)> weekend) => {
      for (final day in [1, 2, 3, 4, 5]) day: weekdays,
      for (final day in [6, 0]) day: weekend
    };

    expect(WeekEditor.modeOf(week([("09:00", "18:00")], [("09:00", "18:00")])), WeekMode.every);
    expect(WeekEditor.modeOf(week([], [])), WeekMode.every);
    expect(WeekEditor.modeOf(week([("09:00", "18:00")], [])), WeekMode.split);
    expect(WeekEditor.modeOf({...week([("09:00", "18:00")], []), 3: [("09:00", "13:00")]}), WeekMode.daily);
  });
}
