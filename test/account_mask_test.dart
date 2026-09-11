import 'package:flutter/services.dart' show TextEditingValue, TextSelection;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/money/account_mask.dart';

/// The shape a number is written in, as the rail's sheet declares it.
///
/// What is pinned here is the promise the mask makes: it spaces what it
/// understands and **never mangles what it does not**, because the value it
/// rewrites is the one thing on the card a customer copies to be paid — an
/// account that came back wrong is money that went somewhere else.
///
/// The backend applies the same rule on the write (`Requirements.format`), so
/// these cases are the two halves of one statement.
const _phone = AccountMask("0000 000 00 00");

TextEditingValue _typed(String text, [int? at]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: at ?? text.length)
);

void main() {
  group('what it spaces', () {
    test('lays the digits into the mask', () {
      expect(_phone.apply("04121234567"), "0412 123 45 67");
    });

    test('re-spaces what is already spaced, however it was spaced', () {
      expect(_phone.apply("0412 123 45 67"), "0412 123 45 67");
      expect(_phone.apply("0412-123-4567"), "0412 123 45 67");
      expect(_phone.apply("(0412) 1234567"), "0412 123 45 67");
    });

    test('stops where the digits stop, with no separator hanging', () {
      expect(_phone.apply("0412"), "0412");
      expect(_phone.apply("04121"), "0412 1");
    });

    test('keeps the digits that do not fit rather than cutting them', () {
      // A number longer than the mask is a number this app was wrong about, not
      // one to silently shorten: the row would then name an account nobody has.
      expect(_phone.apply("041212345671234"), "0412 123 45 671234");
    });
  });

  group('what it leaves alone', () {
    test('anything that is not a number', () {
      expect(_phone.apply("pagos@tienda.com"), "pagos@tienda.com");
      expect(_phone.apply("\$mitienda"), "\$mitienda");
    });

    test('an international number, which no national mask describes', () {
      expect(_phone.apply("+58 412 1234567"), "+58 412 1234567");
    });

    test('everything, when the rail gives the field no shape', () {
      expect(const AccountMask("").apply("04121234567"), "04121234567");
    });
  });

  group('while it is being typed', () {
    const formatter = AccountMaskFormatter(_phone);

    test('the separator appears with the digit that follows it', () {
      final value = formatter.formatEditUpdate(
        _typed("0412"),
        _typed("04121")
      );

      expect(value.text, "0412 1");
      // After the digit just typed, not after the space it pushed along.
      expect(value.selection.baseOffset, 6);
    });

    test('a backspace over a separator deletes the digit behind it', () {
      // Without this the mask writes the space straight back and the field
      // looks stuck, which is the one thing a mask must never do.
      final value = formatter.formatEditUpdate(
        _typed("0412 1", 5),
        _typed("04121", 4)
      );

      // The `2` goes, not the space: `0412 1` minus a digit is `0411`.
      expect(value.text, "0411");
      expect(value.selection.baseOffset, 3);
    });

    test('the caret stays after the digit it was after', () {
      final value = formatter.formatEditUpdate(
        _typed("0412 123 45 67"),
        _typed("0419412 123 45 67", 4)
      );

      expect(value.text, "0419 412 12 34567");
      expect(value.selection.baseOffset, 4);
    });
  });
}
