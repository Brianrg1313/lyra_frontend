import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_card.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_row.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';
import 'package:app/toolkit/settings/routes.dart';

/// **A table that is still being imported does not open.**
///
/// It is in the listing from the moment the structure import answers, which is
/// a good half a minute before it is finished: every column is still `text`,
/// named as the file named them, and not a single row has been uploaded. A
/// sheet in that state does not read as an import that is halfway, it reads as
/// one that failed — and what people do about that is import the file again,
/// which is how a company ends up with three copies of its price list.
///
/// So the entry says what is missing and refuses to open, and the entry alone
/// is what enforces it: the stage is not a property of the table row the
/// backend sends, it is what `TablesService` is tracking about it (`table/
/// normalizing`, the upload it is running, `table/ready`).
const _tableId = "550e8400-e29b-41d4-a716-446655440000";

TableLiteModel get _table => const TableLiteModel(
  id: _tableId,
  title: "Precios mayoristas",
  fields: 12,
  records: 340
);

/// The listing entry with the service that knows what its table is up to. The
/// stage is seeded the way the backend's notice seeds it, so the rule can be
/// pinned without a socket and without an upload.
Widget _app(Widget entry, {TableImportStage? stage}) {
  final tables = TablesService();

  if (stage != null) tables.seedImport(_tableId, stage);

  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: ChangeNotifierProvider<TablesService>.value(
        value: tables,
        child: SizedBox(
          width: TableCard.maxWidth,
          height: TableCard.height,
          child: entry
        )
      ));
    })
  );
}

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    // What is being pinned is whether the tap navigates, so the real route
    // table is the one that has to answer: with routes of its own the test
    // would prove that its own map resolves.
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  /// Standing on the listing, which is where the entry is tapped from.
  setUp(() => Navis.navigate(HomeSection.inventory.path));

  group('a table being imported', () {
    test('is busy through both halves of the import', () {
      // Both stages are the table being half done: the backend typing its
      // columns and the rows going up. Neither is a table worth opening.
      final tables = TablesService();

      expect(tables.isBusy(_tableId), isFalse);

      tables.seedImport(_tableId, TableImportStage.preparing);
      expect(tables.isBusy(_tableId), isTrue);
      expect(tables.importStage(_tableId), TableImportStage.preparing);

      tables.seedImport(_tableId, TableImportStage.loading);
      expect(tables.isBusy(_tableId), isTrue);

      // A table nobody is importing is not busy, which is every other table.
      expect(tables.isBusy("another"), isFalse);
    });

    testWidgets('the card says what is missing instead of opening it',
      (tester) async {
        await tester.pumpWidget(_app(
          TableCard(table: _table),
          stage: TableImportStage.preparing
        ));

        await tester.pump();

        await tester.tap(find.byType(TableCard));

        // Past the breather the floating flag takes before showing the notice:
        // it is what the tap does instead of navigating, and left running it
        // outlives the test.
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(Navis.currentKey.value, HomeSection.inventory.key);
      }
    );

    testWidgets('the phone row holds the same line', (tester) async {
      await tester.pumpWidget(_app(
        TableListRow(table: _table),
        stage: TableImportStage.loading
      ));

      await tester.pump();

      await tester.tap(find.byType(TableListRow));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(Navis.currentKey.value, HomeSection.inventory.key);
    });

    testWidgets('a finished table opens without saying anything',
      (tester) async {
        // The other half of the rule: nothing was seeded, so the tap goes
        // through — the lock is the stage and not the card.
        await tester.pumpWidget(_app(TableCard(table: _table)));
        await tester.pump();

        await tester.tap(find.byType(TableCard));
        await tester.pump();

        expect(Navis.currentKey.value, TableViewSection.routeKey);
      }
    );
  });
}
