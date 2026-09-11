import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_ready_model.dart';

/// The `table/ready` event exactly as `Normalizer.prepare` emits it: the notice
/// that an imported table finished being prepared, half a minute after the
/// import already answered.
Map<String, dynamic> get _event => {
  "id": "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7",
  "ok": true,
  "normalized": true,
  "retyped": 7,
  "narrowed": 3,
  "renamed": 5,
  "summarized": 4,
  "image": "a1b2c3d4-1111-4aaa-8bbb-000000000001",
  "ai": {"used": true, "provider": "anthropic", "cost": 0.0142}
};

void main() {
  group('the table-ready notice', () {
    test('reads what the backend did', () {
      final report = TableReadyModel.fromEvent(_event);

      expect(report.id, "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7");
      expect(report.ok, isTrue);
      expect(report.normalized, isTrue);
      expect(report.retyped, 7);
      expect(report.narrowed, 3);
      expect(report.renamed, 5);
      expect(report.summarized, 4);
      expect(report.image, "a1b2c3d4-1111-4aaa-8bbb-000000000001");
      expect(report.isEmpty, isFalse);
    });

    test('the four counters are four different things', () {
      // The preparation answers four questions per column and reports each one
      // apart: the type it should hold, how much of it the agent may see, the
      // name a person reads above it, and whether it belongs in the short
      // stock view. Collapsing them would lose which of the four moved.
      final report = TableReadyModel.fromEvent({
        "id": "table",
        "ok": true,
        "normalized": true,
        "retyped": 0,
        "narrowed": 0,
        "renamed": 2,
        "summarized": 3
      });

      expect(report.renamed, 2);
      expect(report.summarized, 3);

      // Neither of the two rewrites a stored value: what was read is still
      // good.
      expect(report.changedValues, isFalse);
    });

    test('not normalizing is a good notice too', () {
      // `NORMALIZE=0`: the table was imported exactly as it was written, and
      // the event arrives all the same. It is not a failure and carries no
      // counters.
      final report = TableReadyModel.fromEvent({
        "id": "table",
        "ok": true,
        "normalized": false,
        "image": "image-field"
      });

      expect(report.ok, isTrue);
      expect(report.normalized, isFalse);
      expect(report.retyped, 0);
      expect(report.renamed, 0);
      expect(report.summarized, 0);
      expect(report.changedValues, isFalse);
    });

    test('a failure carries the reason and still names the table', () {
      final report = TableReadyModel.fromEvent({
        "id": "table",
        "ok": false,
        "normalized": false,
        "reason": "table"
      });

      expect(report.isEmpty, isFalse);
      expect(report.ok, isFalse);
      expect(report.reason, "table");
    });

    test('what cannot be read is discarded', () {
      // The only way to drop a notice is for it not to say which table it is
      // about: there is nobody to return an error to, so none of this throws.
      expect(TableReadyModel.fromEvent(null).isEmpty, isTrue);
      expect(TableReadyModel.fromEvent("table/ready").isEmpty, isTrue);
      expect(TableReadyModel.fromEvent(const []).isEmpty, isTrue);
      expect(TableReadyModel.fromEvent({"ok": true}).isEmpty, isTrue);
    });

    test('the numbers and the flags survive arriving as text', () {
      final report = TableReadyModel.fromEvent({
        "id": "table",
        "ok": "true",
        "normalized": 1,
        "retyped": "2",
        "narrowed": null,
        "renamed": "3",
        "summarized": null,
        "image": null
      });

      expect(report.ok, isTrue);
      expect(report.normalized, isTrue);
      expect(report.retyped, 2);
      expect(report.narrowed, 0);
      expect(report.renamed, 3);
      expect(report.summarized, 0);
      expect(report.image, "");
    });
  });

  group('what has to be read again', () {
    test('retyping a column invalidates the records already read', () {
      // On retyping, the backend rewrites the stored values
      // (`Products.recast`): the fields can be the same and their values not.
      final report = TableReadyModel.fromEvent(_event);

      expect(report.changedValues, isTrue);
    });

    test('gaining the image column does not invalidate them', () {
      // Nothing was rewritten: the table has one more column and the rows
      // already read still serve, they only have to be laid out again.
      final report = TableReadyModel.fromEvent({
        "id": "table",
        "ok": true,
        "normalized": true,
        "retyped": 0,
        "narrowed": 4,
        "image": "image-field"
      });

      expect(report.changedValues, isFalse);
    });
  });
}
