import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_view_service.dart';

/// The row cache of an open table: how much of what was read is kept and what
/// is dropped when it no longer fits.
///
/// It matters from a few thousand records on: without a ceiling, walking a
/// table end to end leaves it whole in memory.
void main() {
  group('which page is dropped', () {
    test('while they fit the budget none is dropped', () {
      expect(pageToForget([1, 2, 3], around: 3, budget: 3), isNull);
    });

    test('the one farthest from where one is looking goes', () {
      // Page 10 is being read: page 1 is the least likely to be needed again.
      expect(pageToForget([1, 8, 9, 10], around: 10, budget: 3), 1);
    });

    test('going up drops the lowest one', () {
      // And not the oldest: dropping by age would throw away exactly the page
      // next door, the one about to be looked at again.
      expect(pageToForget([1, 2, 3, 40], around: 2, budget: 3), 40);
    });
  });

  group('how many pages are kept', () {
    test('a narrow table keeps the most', () {
      expect(pageBudget(fields: 12, size: 50), 200);
    });

    test('a wide one keeps fewer, so both weigh about the same', () {
      expect(pageBudget(fields: 60, size: 50), 50);
      expect(
        pageBudget(fields: 60, size: 50) * 60 * 50,
        lessThanOrEqualTo(150000),
        reason: "the values held stay within the budget"
      );
    });

    test('however wide, a thousand rows stay', () {
      expect(pageBudget(fields: 500, size: 50), 20);
    });

    test('a table without fields yet keeps the most', () {
      expect(pageBudget(fields: 0, size: 50), 200);
    });
  });

  group('what was read survives a column change', () {
    // A column change re-reads the whole structure. Dropping the pages for it
    // meant that touching a column's title at row fifty thousand forced going
    // down the table again.
    test('renaming a column moves no value', () {
      // The FIELD_IDs are the same and in the same order.
      expect(fieldsGrewAtEnd(["a", "b"], ["a", "b"]), isTrue);
    });

    test('a new column at the end only leaves the rows short', () {
      // That cell shows empty, which is exactly what fits a newly created
      // field.
      expect(fieldsGrewAtEnd(["a", "b"], ["a", "b", "c"]), isTrue);
    });

    test('the first column of a table without fields drops nothing', () {
      expect(fieldsGrewAtEnd([], ["a"]), isTrue);
    });

    test('deleting a column moves every value', () {
      expect(fieldsGrewAtEnd(["a", "b", "c"], ["a", "c"]), isFalse);
    });

    test('a new column in the middle too', () {
      expect(fieldsGrewAtEnd(["a", "b"], ["a", "c", "b"]), isFalse);
    });

    test('the backend returning them in another order too', () {
      expect(fieldsGrewAtEnd(["a", "b"], ["b", "a"]), isFalse);
    });
  });

  group('and the fields changing place', () {
    // What [fieldsGrewAtEnd] discards can almost always be saved anyway: the
    // values of a read row are still there, only in another position. It
    // matters since columns are dragged, because otherwise each drag would
    // throw away the pages being looked at.
    test('reordering them only moves the values', () {
      expect(fieldsRemap(["a", "b", "c"], ["c", "a", "b"]), [2, 0, 1]);
    });

    test('deleting a column leaves the others where they were', () {
      expect(fieldsRemap(["a", "b", "c"], ["a", "c"]), [0, 2]);
    });

    test('a new column stays empty', () {
      // That is what fits it: nothing is loaded in it yet.
      expect(fieldsRemap(["a", "b"], ["a", "new", "b"]), [0, -1, 1]);
    });

    test('without FIELD_IDs there is nothing to match them with', () {
      // There the only safe thing is to request the rows again.
      expect(fieldsRemap(["a", ""], ["a", "b"]), isNull);
    });

    test('with repeated ids neither', () {
      expect(fieldsRemap(["a", "a"], ["a"]), isNull);
    });

    test('a table that had no fields has nothing to rearrange', () {
      // Its rows are not aligned to any field.
      expect(fieldsRemap([], ["a"]), isNull);
    });
  });

  group('a forgotten page can be requested again', () {
    test('forgetting it takes it out of the read ones', () {
      final paging = TablePaging();
      paging.read(paging.request(0), 50);
      paging.read(paging.request(900), 50);

      expect(paging.request(900), 0, reason: "it is already read");

      paging.forget(paging.pageOf(900));

      expect(paging.request(900), 19);
    });

    test('forgetting changes neither the page size nor where it ends', () {
      final paging = TablePaging();
      paging.read(paging.request(0), 50);
      paging.read(paging.request(50), 20);

      paging.forget(1);

      expect(paging.size, 50);
      expect(paging.atEnd, isTrue);
      expect(paging.known, 70);
    });

    test('a page that failed can also be forgotten', () {
      final paging = TablePaging();
      paging.read(paging.request(0), 50);
      paging.failed(paging.request(50));

      paging.forget(2);

      expect(paging.request(50), 2);
    });
  });
}
