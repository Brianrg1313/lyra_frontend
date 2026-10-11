/// One thing a rail needs filled in, from the `fields` of `GET /business/payments`
/// (and of `GET /money/methods`, keyed by rail).
///
/// It is what makes the account form a different form per rail instead of the
/// same six boxes for everything: a Pago Movil is a bank, an id and a phone and
/// has **no holder**; a Zelle is a name and an address and has no bank; cash
/// has neither. The backend writes the sheet
/// (`model:/money/requirements.js`) and refuses what it says cannot be saved,
/// so a form drawn from it cannot ask for something the write will reject —
/// nor let through something it requires.
///
/// [label] and [hint] arrive **written**, not as keys this app looks up: what a
/// column is called depends on the rail —the same `account` is a phone on a Pago
/// Movil and a wallet address on a crypto row— and keying off the column would
/// mean carrying a table here that says "for this rail, call it Bank", which is
/// the backend's sheet written twice. They come in the console's own language
/// (`model:/money/requirements.js`), so the panel does not read half in one
/// language and half in another.
class MoneyMethodField {
  const MoneyMethodField({
    required this.field,
    this.type = "text",
    this.label = "",
    this.hint = "",
    this.options = "",
    this.format = "",
    this.required = false
  });

  /// Which column it writes: `holder`, `document`, `institution` or `account`.
  /// It is also the key of the request, uppercased.
  final String field;

  /// How it is asked for: `text`, `phone`, `email`, `select` or `document`.
  /// The last two are the ones checked against a catalog; a `document` is a
  /// type out of [options] and a number, stored together (`V-12345678`).
  final String type;

  /// What this field is called **for this rail** ("Banco", "Telefono").
  final String label;

  /// An example of what goes in it, for the placeholder.
  final String hint;

  /// Catalog a `select` (or the prefix of a `document`) is filled from:
  /// `banks`, `documents`, `networks`. Empty when the field is free text.
  final String options;

  /// The shape the number is written in, as a mask of digit slots and the
  /// separators between them (`0000 000 00 00`). Empty when the field has no
  /// fixed shape — an alias, an address, a bank account of a country whose
  /// rails are not national.
  ///
  /// It is the rail's answer and not the app's: a Pago Movil phone is read out
  /// in four blocks and a CLABE in five, and which is which depends on the
  /// country the rail belongs to. It is applied by `AccountMask`.
  final String format;

  /// Whether the account cannot be saved without it.
  final bool required;

  factory MoneyMethodField.fromJson(Map<String, dynamic> data) =>
    MoneyMethodField(
      field: (data["field"] ?? "").toString(),
      type: (data["type"] ?? "text").toString(),
      label: (data["label"] ?? "").toString(),
      hint: (data["hint"] ?? "").toString(),
      options: (data["options"] ?? "").toString(),
      format: (data["format"] ?? "").toString(),
      required: data["required"] == true || data["required"] == 1
    );

  bool get isValid => field.isNotEmpty;

  /// The key this field travels under in the write bodies.
  String get key => field.toUpperCase();
}

/// One choice of a closed field: a bank with the code it is routed by, a
/// document type, a crypto network.
///
/// What is stored is the [code] and never the [name] — a bank that renames must
/// not turn every account that named it into a different bank — so the name is
/// only ever what is drawn.
class MoneyPaymentOption {
  const MoneyPaymentOption({required this.code, required this.name});

  final String code;
  final String name;

  /// How the option is offered in the list: the code beside the name
  /// (`0134 - Banesco`). Both halves are on the line because both are read —
  /// half the people filling this in are copying a code off a screenshot and
  /// the other half only know what the bank is called, and a list that shows
  /// one of the two makes the other search for it.
  ///
  /// Just the name when it already carries the code (`Tron (TRC20)`), which
  /// would otherwise say it twice.
  String get title => name.contains(code) ? name : "$code - $name";

  factory MoneyPaymentOption.fromJson(Map<String, dynamic> data) =>
    MoneyPaymentOption(
      code: (data["code"] ?? "").toString(),
      name: (data["name"] ?? "").toString()
    );

  bool get isValid => code.isNotEmpty && name.isNotEmpty;
}

/// How a payment method's commission is charged.
///
/// `none` is a value and not a missing one: most rails charge nothing, and a
/// method that says so is different from one whose commission was never read.
enum MoneyFeeType {
  none,
  fixed,
  percent;

  static MoneyFeeType from(dynamic raw) => switch (raw?.toString().toLowerCase()) {
    "fixed" => fixed,
    "percent" => percent,
    _ => none
  };

  String get value => name;
}

/// What a payment method charges on top of the sale, from `fee` of
/// `GET /money/methods` (`{type, value}`).
///
/// It is **added to what the customer is charged**, and the backend does the
/// adding: a card terminal that keeps 3% or a Zelle that costs a dollar per
/// transfer is the company's cost unless the charge carries it. Nothing here
/// computes it, as nothing in this app adds money up.
///
/// A [MoneyFeeType.fixed] [value] is an amount **in the method's own
/// currency** (a Pago Movil's commission is in bolivars); a
/// [MoneyFeeType.percent] one is written 3 and never 0.03, the way the POS tax
/// is.
class MoneyFee {
  const MoneyFee({this.type = MoneyFeeType.none, this.value = 0});

  final MoneyFeeType type;
  final double value;

  factory MoneyFee.fromJson(dynamic data) {
    if (data is! Map) return const MoneyFee();

    final type = MoneyFeeType.from(data["type"]);
    final value = switch (data["value"]) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text.trim()) ?? 0,
      _ => 0.0
    };

    // A commission of nothing is no commission, whatever the type says: it is
    // what a row edited by hand looks like, and a `0%` on a card is noise.
    return type == MoneyFeeType.none || value <= 0
      ? const MoneyFee()
      : MoneyFee(type: type, value: value);
  }

  bool get isNone => type == MoneyFeeType.none;
}

/// A rail the company **may** turn on, from `GET /business/payments`.
///
/// It is the catalog the account form picks from, and it is not the same list
/// as [MoneyMethod]: this is what can be accepted in the country the company
/// operates in —Pago Movil and Zelle in Caracas, Mercado Pago in Buenos
/// Aires—, and that one is what it actually turned on, with the account number
/// a customer is told.
///
/// [method] is the settlement kind the rail settles as, and it is what every
/// figure on the money screen is grouped by: the picker never sends
/// `pago_movil` anywhere, it sends `mobile` and remembers the rail beside it.
class MoneyRail {
  const MoneyRail({
    required this.code,
    required this.name,
    this.method = "",
    this.methodName = "",
    this.scope = "",
    this.icon = "",
    this.currency = "",
    this.reference = false,
    this.change = false
  });

  /// The rail's code. It is what `CODE` takes when an account is created, and
  /// it cannot be changed afterwards.
  final String code;

  /// What the rail is called, as the backend writes it.
  final String name;

  /// Settlement kind it settles as (`cash`, `transfer`, `mobile`). It is not
  /// sent when creating an account: the backend takes it from the rail.
  final String method;

  /// Name of that settlement kind, when the catalog brings it.
  final String methodName;

  /// Where the rail is available: the country it belongs to, or the global
  /// scope for the ones that exist everywhere.
  final String scope;

  /// Asset id of its logo, not a URL: it is completed with the `assets` base
  /// `/init` hands over, exactly as a country's flag is.
  final String icon;

  /// The one currency the rail moves, when it only moves one: a Pago Movil is
  /// bolivars whatever the shop's catalog is priced in, a Zelle is dollars.
  /// Empty when it takes any (cash, a bank transfer), and then the company
  /// picks. It is the rail's answer and not the app's, like the templates the
  /// backend renders with it (`model:/money/templates.js`).
  final String currency;

  /// Whether a payment through it carries a number the company writes down
  /// (a transfer's, a terminal's authorization code).
  final bool reference;

  /// Whether cash changes hands, which is the only case where change makes
  /// sense to compute.
  final bool change;

  factory MoneyRail.fromJson(Map<String, dynamic> data) => MoneyRail(
    code: (data["code"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    method: (data["method"] ?? "").toString(),
    methodName: (data["methodName"] ?? "").toString(),
    scope: (data["scope"] ?? "").toString(),
    icon: (data["icon"] ?? "").toString(),
    currency: (data["currency"] ?? "").toString().trim().toUpperCase(),
    reference: data["reference"] == true || data["reference"] == 1,
    change: data["change"] == true || data["change"] == 1
  );

  bool get isValid => code.isNotEmpty && name.isNotEmpty;
}

/// One of the ways this company charges, from `GET /money/methods`.
///
/// It is the answer to "como me pueden pagar": a rail the company turned on
/// plus the data only the shop can fill in —whose name the account is under,
/// which bank, which number—. Several rows may be the same rail (a shop with
/// two bank accounts has two transfers), so [label] is what tells them apart on
/// screen and [id] is what a payment or an edit names.
///
/// **The rail cannot be changed once the row exists.** "This Pago Movil is now
/// a Zelle" is not an edit of an account but another account, and the payments
/// already recorded against this row would silently change what they say they
/// came in through. That is why [code] is written on creation only.
///
/// Every text field is optional, the account number included: a company may
/// turn cash on and there is nothing to write down for it.
class MoneyMethod {
  const MoneyMethod({
    required this.id,
    this.code = "",
    this.name = "",
    this.label = "",
    this.method = "",
    this.methodName = "",
    this.holder = "",
    this.document = "",
    this.institution = "",
    this.institutionName = "",
    this.account = "",
    this.instructions = "",
    this.icon = "",
    this.currency = "",
    this.fee = const MoneyFee(),
    this.reference = false,
    this.change = false,
    this.branch,
    this.position = 0
  });

  /// Identifier of the row. It is what an edit, a removal or a payment names.
  final String id;

  /// The rail behind it (`pago_movil`, `zelle`, `transfer`, `cash`).
  final String code;

  /// Name of that rail, as the catalog writes it.
  final String name;

  /// What the company calls this account —"Transferencia Banesco"—. It is what
  /// tells two rows of the same rail apart, and it is empty when the company
  /// never named it: then the rail's own [name] is what is read.
  final String label;

  /// Settlement kind the money lands as. It comes from the rail and is what the
  /// money screen groups by.
  final String method;

  /// Name of that settlement kind, as the backend writes it.
  final String methodName;

  /// Name the account is under.
  final String holder;

  /// Id number some rails are paid with (cedula, RIF, DNI).
  final String document;

  /// Bank, wallet or network. When the rail picks it from a catalog this holds
  /// the **code** the payment is routed by (`0134`), which is what is stored
  /// and what the form preselects — never the name.
  final String institution;

  /// What that code is called (`Banesco`). Empty when the field is free text,
  /// and then [institution] is already what there is to read.
  final String institutionName;

  /// The number, phone, email or address money is sent to. It is kept exactly
  /// as it was typed: an account is written differently in every country, and
  /// reformatting a real one means the company cannot be paid.
  final String account;

  /// What the customer has to do beyond sending the money.
  final String instructions;

  /// Asset id of the rail's logo. See [MoneyRail.icon].
  final String icon;

  /// The currency money comes into this account in: the company's main one or
  /// one of its exchange currencies (`MoneyCurrencies.codes`). Empty on a row
  /// saved before accounts had one, and then it reads as the main currency,
  /// which is what the backend assumes too.
  final String currency;

  /// What it charges on top of the sale. See [MoneyFee].
  final MoneyFee fee;

  /// Whether a payment into this account carries a reference number.
  final bool reference;

  /// Whether it is cash.
  final bool change;

  /// Where it sits in the picker. The company's own order.
  /// The branch the account belongs to, or null when every branch charges into it. A till
  /// offers only its branch's and the company's (`servesBranch`): a payment into another
  /// branch's account is refused (`payment_account_other_branch`).
  final String? branch;

  final int position;

  factory MoneyMethod.fromJson(Map<String, dynamic> data) => MoneyMethod(
    id: (data["id"] ?? "").toString(),
    code: (data["code"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    label: (data["label"] ?? "").toString(),
    method: (data["method"] ?? "").toString(),
    methodName: (data["methodName"] ?? "").toString(),
    holder: (data["holder"] ?? "").toString(),
    document: (data["document"] ?? "").toString(),
    institution: (data["institution"] ?? "").toString(),
    institutionName: (data["institutionName"] ?? "").toString(),
    account: (data["account"] ?? "").toString(),
    instructions: (data["instructions"] ?? "").toString(),
    icon: (data["icon"] ?? "").toString(),
    currency: (data["currency"] ?? "").toString().trim().toUpperCase(),
    fee: MoneyFee.fromJson(data["fee"]),
    reference: data["reference"] == true || data["reference"] == 1,
    change: data["change"] == true || data["change"] == 1,
    branch: switch ((data["branch"] ?? "").toString().trim()) {
      "" => null,
      final id => id
    },
    position: _int(data["position"])
  );

  bool get isValid => id.isNotEmpty;

  /// Whether a payment worked in [branch] may land in it: the account is the company's, or
  /// that branch's. No branch worked in (a master) takes every one.
  bool servesBranch(String? branch) => this.branch == null || branch == null || this.branch == branch;

  /// What this account is called on screen: the company's own name for it, and
  /// the rail's when it never gave it one.
  String get title => label.isNotEmpty ? label : name;

  /// The institution as it is read: its name when it came out of a catalog,
  /// and what the company typed when it did not.
  String get institutionLabel =>
    institutionName.isNotEmpty ? institutionName : institution;

  /// The line under the title: the institution and the account, whichever of
  /// the two the company filled in. Empty for a rail with nothing to write
  /// down, such as cash.
  String get subtitle => [institutionLabel, account]
    .where((value) => value.isNotEmpty)
    .join(" · ");

  /// What this account holds in one of the four generic columns, by the name
  /// its rail's sheet gives it ([MoneyMethodField.field]).
  ///
  /// It is read by name and not by getter because which columns exist on a row
  /// is the rail's answer and not this class's: a screen drawing an account
  /// walks the sheet, and asking for a field the rail does not have reads
  /// empty, which is exactly what it is.
  String field(String name) => switch (name) {
    "holder" => holder,
    "document" => document,
    "institution" => institutionLabel,
    "account" => account,
    _ => ""
  };

  static int _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };
}
