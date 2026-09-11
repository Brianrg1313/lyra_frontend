/// One way a sale can be paid, from `GET /pos/methods`.
///
/// **It is a closed vocabulary the backend owns** and hands over, so the counter
/// does not hard-code it and does not drift the day it grows: the code is what
/// travels on the ticket (`cash`, `transfer`) and [name] is what is read on the
/// screen, already written by the backend.
///
/// The two flags are what make this a table and not a list of strings: whether
/// the payment carries a number the company writes down ([reference] — a
/// transfer's, a card terminal's authorization code), and whether money
/// physically changes hands ([change], which only cash does).
class PosPaymentMethod {
  const PosPaymentMethod({
    required this.method,
    required this.name,
    this.reference = false,
    this.change = false,
    this.isDefault = false
  });

  /// The code stored on the sale. It is what `METHOD` takes.
  final String method;

  /// What it is called, as the backend writes it. It is **not** translated
  /// here: it is backend-provided text, like a provider's name.
  final String name;

  /// Whether the checkout has to ask for the payment's reference number. A
  /// payment nobody can find again is one that cannot be reconciled with the
  /// bank.
  final bool reference;

  /// Whether cash changes hands, which is the only case where change makes
  /// sense to compute.
  final bool change;

  /// Whether it is the one the backend assumes when the client says nothing.
  final bool isDefault;

  factory PosPaymentMethod.fromJson(Map<String, dynamic> data) => PosPaymentMethod(
    method: (data["method"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    reference: data["reference"] == true,
    change: data["change"] == true,
    isDefault: data["default"] == true
  );

  bool get isValid => method.isNotEmpty && name.isNotEmpty;
}
