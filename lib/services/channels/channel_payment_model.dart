/// One of the company's payment accounts a channel may offer, as the backend
/// attaches it to a channel (`GET /channels/detail/:ID`, and every row of
/// `GET /channels/`).
///
/// A company charges through accounts that are not all public —the owner's
/// personal Zelle, the account a distributor pays into— so a channel tells a
/// customer about the ones it was given and about no others. What is stored on
/// the channel is the [id] alone; the rest travels re-joined against the money
/// database on every read, which is why an account turned off in `/money`
/// simply stops coming back instead of arriving as an account nobody can pay
/// into any more.
class ChannelPaymentModel {
  const ChannelPaymentModel({
    required this.id,
    this.code = "",
    this.label = "",
    this.method = ""
  });

  /// Identifier of the account row. It is what the writes name.
  final String id;

  /// The rail behind it (`pago_movil`, `zelle`, `transfer`, `cash`).
  final String code;

  /// What the company calls this account. Empty when it never named it, and
  /// then there is only the rail to read it by.
  final String label;

  /// Settlement kind the money lands as (`cash`, `transfer`, `mobile`).
  final String method;

  factory ChannelPaymentModel.fromJson(Map json) => ChannelPaymentModel(
    id: json["id"]?.toString() ?? "",
    code: json["code"]?.toString() ?? "",
    label: json["label"]?.toString() ?? "",
    method: json["method"]?.toString() ?? ""
  );

  /// Decodes the list a channel carries. Anything that is not a list —a key
  /// that did not travel, a `null` on a channel that offers no way to pay— is
  /// no accounts, which is the default state and not a failure.
  static List<ChannelPaymentModel> fromResponse(dynamic value) {
    if (value is! List) return const [];

    return [
      for (final item in value)
        if (item is Map) ChannelPaymentModel.fromJson(item)
    ];
  }
}
