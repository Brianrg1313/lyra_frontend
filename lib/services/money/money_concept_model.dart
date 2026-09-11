/// Which way the money went.
///
/// It is never sent when recording a payment: the concept already says it
/// (`supplier` is money out, `settlement` is money in), and a request that
/// could name both would be able to contradict itself. It travels only as a
/// **filter** of the history and as the direction the backend answers on each
/// row.
///
/// `in` is a reserved word in Dart, so the values are spelled out and [value]
/// is what the backend reads.
enum MoneyDirection {
  incoming("in"),
  outgoing("out");

  const MoneyDirection(this.value);

  /// The code the backend uses (`in` / `out`).
  final String value;

  static MoneyDirection? from(dynamic raw) => switch (
    raw?.toString().trim().toLowerCase()
  ) {
    "in" => incoming,
    "out" => outgoing,
    _ => null
  };

  bool get isIncoming => this == incoming;
}

/// What a payment was for, from `GET /money/catalog`.
///
/// **It is a closed vocabulary the backend owns** and hands over, exactly like
/// the settlement kinds beside it: the client neither writes the list nor
/// translates it —[name] arrives already written— so the day a concept is
/// added, the form offers it without a new version of the app.
///
/// The catalog arrives **split by direction** because the form is: the two
/// halves of the payment screen (received / paid) are those two lists, and the
/// concept is what decides which way the money went.
class MoneyConcept {
  const MoneyConcept({
    required this.concept,
    required this.name,
    required this.direction,
    this.ticket = false,
    this.settles = false
  });

  /// The code stored on the payment. It is what `CONCEPT` takes.
  final String concept;

  /// What it is called, as the backend writes it. It is **not** translated
  /// here: it is backend-provided text, like a provider's name.
  final String name;

  final MoneyDirection direction;

  /// Whether the payment may name a sale. Only a couple of concepts can
  /// (`settlement`, `customer_refund`), and it is what decides whether the form
  /// asks for a ticket code at all.
  final bool ticket;

  /// Whether it pays a credit ticket's balance down. It is the one concept that
  /// touches a sale, so a payment recorded with it turns into money the
  /// receivables list stops counting.
  final bool settles;

  factory MoneyConcept.fromJson(Map<String, dynamic> data) => MoneyConcept(
    concept: (data["concept"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    direction: MoneyDirection.from(data["direction"]) ?? MoneyDirection.outgoing,
    ticket: data["ticket"] == true,
    settles: data["settles"] == true
  );

  bool get isValid => concept.isNotEmpty && name.isNotEmpty;
}
