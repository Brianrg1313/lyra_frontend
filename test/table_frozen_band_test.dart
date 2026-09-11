import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

/// A frozen band draws a 1 px divider towards the scrollable area, and a
/// border is painted **inside** the box: a band sized to its columns alone
/// hands its header row and every body row one pixel less than the width their
/// cells were laid out with, and the table overflows by exactly 1.00 px.
///
/// It is pinned here because it is invisible in the app: three tables freeze a
/// column (the sales board, the payment history, the receivables), the stripes
/// only show in debug, and the pixel is lost inside `core` where no column
/// width could ever compensate for it.
Widget _table({int left = 1, int right = 1}) => MaterialApp(
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(
      body: SizedBox(
        width: 600,
        height: 300,
        child: DataTableView<String>(
          items: const ["a", "b", "c"],
          frozenColumns: left,
          trailingFrozenColumns: right,
          columns: [
            TableColumn(
              id: "stage",
              title: "Estado",
              width: 200,
              cell: (context, item, _) => Text(item)
            ),
            TableColumn(
              id: "customer",
              title: "Cliente",
              minWidth: 150,
              flex: 2,
              cell: (context, item, _) => Text(item)
            ),
            TableColumn(
              id: "action",
              title: "",
              width: 50,
              cell: (context, item, _) => const Icon(Icons.check)
            )
          ]
        )
      )
    );
  })
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('a frozen band fits the columns it was measured with',
    (tester) async {
      await tester.pumpWidget(_table());
      await tester.pump();

      // The header is the row that overflows first: its cells are the column
      // widths with nothing flexible in them to absorb the missing pixel.
      expect(tester.takeException(), isNull);
    }
  );

  testWidgets('a table with no frozen column keeps the whole width',
    (tester) async {
      // The band that is not drawn must not reserve its divider either: the
      // scrollable area would end a pixel short of the viewport and the table
      // would offer a horizontal scroll over nothing.
      await tester.pumpWidget(_table(left: 0, right: 0));
      await tester.pump();

      final band = tester.getSize(find.byType(SingleChildScrollView).first);

      expect(band.width, 600);
      expect(tester.takeException(), isNull);
    }
  );
}
