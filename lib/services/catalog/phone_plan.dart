/// How long a phone is in each numbering plan, and what is typed at home but
/// never dialed from abroad (the trunk `0`: `0412 …` in Venezuela is
/// `+58 412 …`).
///
/// This is not a list of countries — which ones the platform offers is the
/// catalog's ([CountryCatalogService]) — but facts of the ITU plans, keyed by
/// the start of the international number. A code missing here is not refused:
/// it gets the E.164 bounds, so enabling a region never needs this file first.
class PhonePlan {
  const PhonePlan._(this.min, this.max);

  /// Digits after the country code.
  final int min;
  final int max;

  /// E.164: at most 15 digits with the code; fewer than 4 after it is not a
  /// number anywhere.
  static const _shortest = 4;
  static const _longest = 15;

  /// Whole international length (code + number) by its first digits; the
  /// longest matching key wins, so a dial written as `1809` still reads `1`.
  static const Map<String, (int, int)> _total = {
    "1": (11, 11), // North America and the Caribbean (NANP)
    "34": (11, 11), // Spain
    "351": (12, 12), // Portugal
    "33": (11, 11), // France
    "44": (11, 12), // United Kingdom
    "52": (12, 12), // Mexico
    "53": (10, 10), // Cuba
    "54": (12, 13), // Argentina, a mobile carries a 9 after the code
    "55": (12, 13), // Brazil
    "56": (11, 11), // Chile
    "57": (12, 12), // Colombia
    "58": (12, 12), // Venezuela
    "51": (10, 11), // Peru
    "502": (11, 11), // Guatemala
    "503": (11, 11), // El Salvador
    "504": (11, 11), // Honduras
    "505": (11, 11), // Nicaragua
    "506": (11, 11), // Costa Rica
    "507": (10, 11), // Panama
    "591": (11, 11), // Bolivia
    "593": (11, 12), // Ecuador
    "595": (10, 12), // Paraguay
    "598": (11, 11) // Uruguay
  };

  /// Plans where the leading `0` is part of the number and is dialed from
  /// abroad too (Italy's landlines, and the two states inside it).
  static const _keepsZero = {"39", "378", "379"};

  /// The plan of a country code (without `+`).
  static PhonePlan of(String dial) {
    String? key;

    for (final prefix in _total.keys) {
      if (dial.startsWith(prefix) && (key == null || prefix.length > key.length)) key = prefix;
    }

    final total = key == null ? null : _total[key];
    if (total == null) return PhonePlan._(_shortest, _longest - dial.length);

    return PhonePlan._(total.$1 - dial.length, total.$2 - dial.length);
  }

  /// The number as dialed after the code: digits only, without the trunk
  /// zeros written at home, where the plan does not keep them.
  static String national(String dial, String number) {
    final digits = number.replaceAll(RegExp(r"\D"), "");

    return _keepsZero.contains(dial) ? digits : digits.replaceFirst(RegExp(r"^0+"), "");
  }

  bool fits(String number) => number.length >= min && number.length <= max;
}
