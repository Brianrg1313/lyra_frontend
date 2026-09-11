import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_normalize_model.dart';

/// The response of `POST /lyra/v1/inventory/products/builder/normalize`: a table
/// imported from an Excel that has just been given the type, the visibility, the
/// name and the place in the stock summary of every column.
///
/// It comes with the whole plan beside it (`fields`, in the usual columnar
/// shape) which the model ignores on purpose: the structure is requested again
/// afterwards, and that is the one that says how the columns really ended up.
Map<String, dynamic> get _response => {
  "id": "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7",
  "image": "a1b2c3d4-1111-4aaa-8bbb-000000000001",
  "retyped": 7,
  "narrowed": 3,
  "renamed": 1,
  "summarized": 2,
  "recast": 5,
  "reindexed": true,
  "ai": {"used": true, "provider": "anthropic", "cost": 0.0142, "applied": 4},
  "fields": {
    "keys": ["id", "name", "type", "suggested_type", "changed"],
    "values": [
      ["field-1", "Precio", "text", "price", true]
    ]
  }
};

void main() {
  group('normalization report', () {
    test('reads what changed', () {
      final report = TableNormalizeModel.fromResponse(_response);

      expect(report.id, "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7");
      expect(report.retyped, 7);
      expect(report.narrowed, 3);
      expect(report.renamed, 1);
      expect(report.summarized, 2);
      expect(report.recast, 5);
      expect(report.reindexed, isTrue);
      expect(report.image, "a1b2c3d4-1111-4aaa-8bbb-000000000001");
      expect(report.isEmpty, isFalse);
    });

    test('counts the columns that ended up different', () {
      // The four things normalization can change about a column, counted
      // together only to decide whether anything changed at all.
      final report = TableNormalizeModel.fromResponse(_response);

      expect(report.changed, 13);
    });

    test('seeding the summary alone still counts as a change', () {
      // The column kept its type, its visibility and its name, and a person
      // now sees it in the short stock view: saying "nothing changed" there
      // would leave the click unanswered.
      final report = TableNormalizeModel.fromResponse({
        "id": "table",
        "summarized": 3
      });

      expect(report.changed, 3);
      expect(report.changedValues, isFalse);
    });

    test('a table that was already right changed nothing', () {
      // Every column already had the type it deserves: normalization went
      // through and wrote nothing.
      final report = TableNormalizeModel.fromResponse({
        "id": "table",
        "image": null,
        "retyped": 0,
        "narrowed": 0,
        "renamed": 0,
        "summarized": 0,
        "recast": 0,
        "reindexed": false
      });

      expect(report.isEmpty, isFalse);
      expect(report.changed, 0);
      expect(report.changedValues, isFalse);
      expect(report.image, "");
    });

    test('the stored values were rewritten', () {
      // It is the only thing that forces dropping whatever records are held:
      // the columns are the same and their values no longer are.
      expect(
        TableNormalizeModel.fromResponse({"id": "t", "recast": 2}).changedValues,
        isTrue
      );

      // Retyping without rewriting counts too: an empty column changes type
      // without a single value to rewrite, and what was read went stale all
      // the same.
      expect(
        TableNormalizeModel.fromResponse({"id": "t", "retyped": 1}).changedValues,
        isTrue
      );

      // Seeding the visibility does not touch a single value: that is read by
      // the agent, not by the sheet.
      expect(
        TableNormalizeModel.fromResponse({"id": "t", "narrowed": 4}).changedValues,
        isFalse
      );
    });

    test('a response that cannot be read is discarded', () {
      expect(TableNormalizeModel.fromResponse(null).isEmpty, isTrue);
      expect(TableNormalizeModel.fromResponse("").isEmpty, isTrue);
      expect(TableNormalizeModel.fromResponse(const {}).isEmpty, isTrue);
    });

    test('the counters survive arriving as text', () {
      final report = TableNormalizeModel.fromResponse({
        "id": "table",
        "retyped": "3",
        "narrowed": "not a number",
        "summarized": "2",
        "reindexed": "true"
      });

      expect(report.retyped, 3);
      expect(report.narrowed, 0);
      expect(report.summarized, 2);
      expect(report.reindexed, isTrue);
    });
  });
}
