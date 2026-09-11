import 'package:flutter/services.dart' show TextEditingValue, TextInputFormatter, TextSelection;

/// The shape a number is written in, as the rail's sheet declares it
/// (`MoneyMethodField.format`): a mask of digit slots and the separators
/// between them, `0000 000 00 00` for a Venezuelan phone.
///
/// **The spacing is part of the value, not decoration.** A phone read out in
/// four blocks is one a customer mistypes less, and it is what a customer is
/// shown, dictated and asked to copy — so it is what gets stored. The backend
/// applies the same mask on the write (`Requirements.format`), which is what
/// keeps an account created from the POS or an import spaced like one created
/// here.
///
/// **It never drops a character.** A value with anything but digits and the
/// punctuation a number is written with —an email, an alias, a wallet address—
/// comes back untouched, and so does one starting with `+`: an international
/// number does not fit a national mask, and mangling a real account is worse
/// than not spacing it. Digits past the end of the mask are appended rather
/// than cut, so a longer number can still be typed and saved.
class AccountMask {
  const AccountMask(this.mask);

  /// The mask itself. Empty means the field has no fixed shape, and then
  /// [apply] is the identity.
  final String mask;

  /// The character that stands for "a digit goes here". Everything else in a
  /// mask is written as it stands, which is why a mask reads as an example of
  /// the thing itself.
  static const String slot = "0";

  /// What can be spaced. Anything outside it is a value the mask has nothing to
  /// say about.
  static final RegExp _numeric = RegExp(r"^[0-9 ()+.-]+$");

  static final RegExp _notDigit = RegExp(r"[^0-9]");

  bool get isEmpty => mask.isEmpty;

  /// The value, spaced. See the note above on what it refuses to touch.
  String apply(String value) {
    final text = value.trim();

    if (mask.isEmpty ||
        text.isEmpty ||
        text.startsWith("+") ||
        !_numeric.hasMatch(text)) {
      return text;
    }

    final digits = text.replaceAll(_notDigit, "");
    if (digits.isEmpty) return text;

    final buffer = StringBuffer();
    int at = 0;

    for (final character in mask.split("")) {
      if (at >= digits.length) break;

      if (character == slot) {
        buffer.write(digits[at]);
        at += 1;

        continue;
      }

      buffer.write(character);
    }

    return buffer.toString() + digits.substring(at);
  }

  /// How many digits there are in the first [length] characters of [text]. It
  /// is what puts the caret back where it was after the mask rewrote the line:
  /// the separators move, the digits do not.
  int digitsBefore(String text, int length) {
    int count = 0;

    for (int i = 0; i < length && i < text.length; i++) {
      if (!_notDigit.hasMatch(text[i])) count += 1;
    }

    return count;
  }

  /// Where the last digit before [before] sits, or -1 when there is none. It is
  /// what a backspace over a separator actually meant to delete.
  int lastDigitBefore(String text, int before) {
    for (int i = (before > text.length ? text.length : before) - 1; i >= 0; i--) {
      if (!_notDigit.hasMatch(text[i])) return i;
    }

    return -1;
  }

  bool isDigit(String character) => !_notDigit.hasMatch(character);

  /// The offset that sits right after [count] digits of [text].
  int offsetAfter(String text, int count) {
    if (count <= 0) return 0;

    int seen = 0;

    for (int i = 0; i < text.length; i++) {
      if (!_notDigit.hasMatch(text[i])) {
        seen += 1;

        if (seen == count) return i + 1;
      }
    }

    return text.length;
  }
}

/// Writes the mask **while** the number is being typed.
///
/// It is a formatter and not a reformat on submit: a value corrected after the
/// field loses focus rewrites what somebody just typed behind their back, and
/// they go back to check what they actually put. Here the separators appear as
/// the digits do, so what is on screen is always what will be saved.
///
/// The caret is placed back after the same digit it was after, not at the same
/// offset: inserting a space in front of it would otherwise push it one
/// character to the right on every block, and deleting a separator would leave
/// it stranded.
///
/// **A backspace over a separator deletes the digit behind it.** Otherwise the
/// mask writes the separator straight back and the field looks stuck: the one
/// thing a mask must never do is refuse to be erased.
class AccountMaskFormatter extends TextInputFormatter {
  const AccountMaskFormatter(this.mask);

  final AccountMask mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value
  ) {
    if (mask.isEmpty) return value;

    var text = value.text;
    var caret = value.selection.baseOffset < 0 ? text.length : value.selection.baseOffset;

    if (text.length < old.text.length && _onlySeparators(old.text, caret, old.text.length - text.length)) {
      final digit = mask.lastDigitBefore(text, caret);

      if (digit >= 0) {
        text = text.substring(0, digit) + text.substring(digit + 1);
        caret = digit;
      }
    }

    final digits = mask.digitsBefore(text, caret);
    final formatted = mask.apply(text);

    if (formatted == value.text && caret == value.selection.baseOffset) return value;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: mask.offsetAfter(formatted, digits)
      )
    );
  }

  /// Whether what was just removed carried no digit at all — a lone space, the
  /// dash between two blocks.
  bool _onlySeparators(String before, int at, int length) {
    if (at < 0 || length <= 0 || at + length > before.length) return false;

    for (int i = at; i < at + length; i++) {
      if (mask.isDigit(before[i])) return false;
    }

    return true;
  }
}
