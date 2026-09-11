/// Where a sale came in through: the counter, or one of the services a bot can
/// sell over.
///
/// It is the same closed vocabulary the checkout's own picker is drawn from
/// (`GET /pos/methods`, which answers it beside the payment methods), and that
/// is deliberate on the backend: a sale over a channel and the channel that
/// produced it must never be two spellings of one thing. So this list is read
/// from there rather than written here, and a channel the platform learns to
/// sell through shows up without a new version of the app.
class SaleChannel {
  const SaleChannel({
    required this.channel,
    this.name = "",
    this.isDefault = false
  });

  /// The code, which is what travels as `CHANNEL` and what a row carries.
  final String channel;

  /// What it is called, as the backend wrote it.
  final String name;

  /// The one a sale is filed under when nothing says otherwise: the counter.
  final bool isDefault;

  factory SaleChannel.fromJson(Map<String, dynamic> data) => SaleChannel(
    channel: (data["channel"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    isDefault: data["default"] == true
  );
}
