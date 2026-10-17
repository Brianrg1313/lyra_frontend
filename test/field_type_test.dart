import 'package:flutter/services.dart' show SystemMouseCursors;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_type.dart';

void main() {
  test('the two semantic types head the list of types', () {
    // They are what the AI reads and searches by meaning: the ones worth seeing
    // first when choosing, not two more in the middle of a list of twenty-four.
    expect(
      TableFieldType.ordered.take(2),
      [TableFieldType.title, TableFieldType.description]
    );
  });

  test('every type is listed, and only once', () {
    final ordered = TableFieldType.ordered;

    expect(ordered.length, TableFieldType.values.length);
    expect(ordered.toSet().length, ordered.length);
  });

  test('after the semantic types the order is the declared one', () {
    expect(
      TableFieldType.ordered.skip(2),
      TableFieldType.values.where((type) => !type.semantic)
    );
  });

  group('the codes are the backend ones', () {
    test('the code is the name in upper case', () {
      // It is the only thing that travels when a table is created or read: if
      // this list and the backend's `TYPE` rule drift apart, the column is
      // created with a type the other side doesn't have.
      for (final type in TableFieldType.values) {
        expect(type.value, type.name.toUpperCase());
      }
    });

    test('every code is read back', () {
      for (final type in TableFieldType.values) {
        expect(TableFieldType.from(type.value), type, reason: type.value);
        expect(
          TableFieldType.from(type.value.toLowerCase()),
          type,
          reason: type.value
        );
      }
    });

    test('an unknown type is read as text', () {
      // The column is still seen and edited instead of lost.
      expect(TableFieldType.from("QUANTUM"), TableFieldType.text);
      expect(TableFieldType.from(null), TableFieldType.text);
    });

    test('the two old names are still read', () {
      // The database migrates them on its own, but an installation that hasn't
      // migrated yet still has to draw its columns.
      expect(TableFieldType.from("SELECT"), TableFieldType.options);
      expect(TableFieldType.from("VECTOR"), TableFieldType.description);
    });

    test('a discount column is a discount, not text', () {
      // The POS takes it off the price, so reading it as loose text hid the
      // one column that changes what a customer pays.
      expect(TableFieldType.from("DISCOUNT"), TableFieldType.discount);
      expect(TableFieldType.discount, isNot(TableFieldType.percentage));
    });
  });

  group('the families of a type', () {
    test('the text the AI indexes is two types', () {
      expect(
        TableFieldType.values.where((type) => type.semantic),
        [TableFieldType.title, TableFieldType.description]
      );
    });

    test('the types that pick from a list are three', () {
      expect(
        TableFieldType.values.where((type) => type.listed),
        [TableFieldType.options, TableFieldType.categories, TableFieldType.sizes]
      );
    });

    test('only the multi-tag types store more than one value', () {
      expect(
        TableFieldType.values.where((type) => type.multiple),
        [TableFieldType.categories, TableFieldType.sizes]
      );
    });

    test('the types that carry a column symbol are four', () {
      // Discount and percentage are left out on purpose: there the unit is the
      // type.
      expect(
        TableFieldType.values.where((type) => type.united),
        [TableFieldType.price, TableFieldType.currency, TableFieldType.measure, TableFieldType.stock]
      );

      expect(TableFieldType.discount.united, isFalse);
      expect(TableFieldType.percentage.united, isFalse);
    });

    test('a discount is a number, written like one', () {
      expect(TableFieldType.discount.money, isFalse);
      expect(TableFieldType.discount.editable, isTrue);
      expect(TableFieldType.discount.alignment, TableFieldType.percentage.alignment);
      expect(TableFieldType.discount.keyboard, TableFieldType.percentage.keyboard);
    });
  });

  group('the cursor says what is done in the cell', () {
    test('where it is typed, the text cursor', () {
      // It is what is seen before touching, and until now it was a spreadsheet
      // one: the same for the cell that is typed and the one that opens something.
      for (final type in [
        TableFieldType.text,
        TableFieldType.title,
        TableFieldType.description,
        TableFieldType.price,
        TableFieldType.sku,
        TableFieldType.date
      ]) {
        expect(type.cursor, SystemMouseCursors.text, reason: type.value);
      }
    });

    test('where it is touched and opens, a button cursor', () {
      // The cells with no editor: both lists are picked and an image opens its
      // menu.
      expect(TableFieldType.options.cursor, SystemMouseCursors.click);
      expect(TableFieldType.categories.cursor, SystemMouseCursors.click);
      expect(TableFieldType.sizes.cursor, SystemMouseCursors.click);
      expect(TableFieldType.image.cursor, SystemMouseCursors.click);
    });

    test('it is the same question that decides whether there is an editor', () {
      for (final type in TableFieldType.values) {
        expect(
          type.cursor,
          type.picker ? SystemMouseCursors.click : SystemMouseCursors.text,
          reason: type.value
        );
      }
    });
  });
}
