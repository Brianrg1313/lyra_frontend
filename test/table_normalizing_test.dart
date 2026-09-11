import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_normalizing_model.dart';

/// The `table/normalizing` event exactly as `Normalizer.prepare` emits it: the
/// notice that the backend started preparing an imported table, sent right
/// behind the response that created it.
Map<String, dynamic> get _event => {
  "id": "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7",
  "normalize": true,
  "ai": true
};

void main() {
  group('the table-being-prepared notice', () {
    test('reads what the backend is about to do', () {
      final report = TableNormalizingModel.fromEvent(_event);

      expect(report.id, "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7");
      expect(report.normalize, isTrue);
      expect(report.ai, isTrue);
      expect(report.isEmpty, isFalse);
    });

    test('it also arrives when nothing is going to be normalized', () {
      // `NORMALIZE=0`: the file is kept exactly as it was written, and the
      // event travels all the same so a client can pair it with `table/ready`
      // unconditionally instead of guessing which imports produce them. The
      // table is still not finished there — it is missing its image column.
      final report = TableNormalizingModel.fromEvent({
        "id": "table",
        "normalize": false,
        "ai": false
      });

      expect(report.isEmpty, isFalse);
      expect(report.normalize, isFalse);
      expect(report.ai, isFalse);
    });

    test('the flags are read in the three shapes a flag travels in', () {
      bool ai(dynamic raw) =>
        TableNormalizingModel.fromEvent({"id": "x", "ai": raw}).ai;

      expect(ai(true), isTrue);
      expect(ai(1), isTrue);
      expect(ai("1"), isTrue);
      expect(ai("true"), isTrue);

      expect(ai(false), isFalse);
      expect(ai(0), isFalse);
      expect(ai("0"), isFalse);
      expect(ai(null), isFalse);
    });

    test('a notice with no table is the only one discarded', () {
      // There is nobody to return an error to, so an unreadable notice comes
      // out empty and whoever receives it drops it. The cost of that is a
      // table that is not marked as busy, never a wrong mark.
      expect(TableNormalizingModel.fromEvent(null).isEmpty, isTrue);
      expect(TableNormalizingModel.fromEvent("table/normalizing").isEmpty, isTrue);
      expect(TableNormalizingModel.fromEvent({"normalize": true}).isEmpty, isTrue);
    });
  });
}
