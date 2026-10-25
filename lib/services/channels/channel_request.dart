/// Bodies of a channel's write operations: the creation
/// (`POST /v1/channels/`), the edit (`PUT /v1/channels/`), the
/// deletion (`DELETE /v1/channels/`) and the reordering
/// (`PUT /v1/channels/order/`).
///
/// They live apart from the screen because they are the contract with the
/// backend, just like those of the product tables.
///
/// The owning company does not go in the body: it travels in the `business_id`
/// header of every request (see `useBusiness` in `toolkit/backend/api.dart`).
///
/// `NAME` and `DESCRIPTION` are not built here at all: the form no longer asks
/// for either — a channel not yet named already shows something meaningful in
/// a listing (the provider and the scope's label) — so omitting the keys is
/// exactly what leaves them as the backend defaults them (create) or as they
/// already were (edit).
///
/// The configuration is split into two objects and **that split is not the
/// form's, it is the backend's**:
///
/// - `SETTINGS` — what is not a secret (account ids, hosts, and also this
///   app's own data-source category, see [ChannelDataSource]). It is read back.
/// - `CREDENTIALS` — the tokens and secrets. They only travel one way: no read
///   returns them.
///
/// Which field goes in which is decided by the provider catalog
/// (`secret: true`), not this app.
///
/// `SCOPE`, `ROLE`, `TABLES` and `PAYMENT_METHODS` are real backend columns and
/// not settings: see [ChannelProviderScope], [ChannelAgentRole],
/// `channel_tables` and `channel_payment_methods`.
///
/// Shape of the creation:
///
/// ```json
/// {
///   "PROVIDER": "whatsapp",
///   "SCOPE": "messages",
///   "ROLE": "sales",
///   "TABLES": ["a1b2..."],
///   "PAYMENT_METHODS": ["c3d4..."],
///   "SETTINGS": { "phone_number_id": "123", "data_source": "table" },
///   "CREDENTIALS": { "access_token": "EAAG..." }
/// }
/// ```
library;

/// Builds the creation body.
///
/// Only the provider and the scope are really required: **a channel is
/// deliberately registered before it has its credentials**. It is registered
/// today and the tokens are pasted once the service issues them, so sending
/// `SETTINGS` and `CREDENTIALS` half-filled is the normal case and not an
/// error; the channel stays "not ready" until they are completed.
///
/// Empty values are dropped instead of being sent blank: in the creation a key
/// with a null value is a key that was never configured, and leaving it would
/// make it look configured when it is not. `TABLES` and `PAYMENT_METHODS`,
/// though, always travel — an empty list is the legitimate "nothing chosen
/// yet", not a value to drop.
///
/// `PAYMENT_METHODS` is what the channel may tell a customer to pay into, by
/// the ids of the company's own accounts. Offering none is the default and the
/// normal case: not every account a company charges through is public, so a
/// channel hands out the ones it was given and no others.
Map<String, dynamic> createChannelRequest({
  required String provider,
  required String scope,
  required String role,
  List<String> tables = const [],
  List<String> methods = const [],
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> credentials = const {}
}) => {
  "PROVIDER": provider,
  "SCOPE": scope,
  "ROLE": role,
  "TABLES": tables,
  "PAYMENT_METHODS": methods,
  "SETTINGS": _clean(settings),
  "CREDENTIALS": _clean(credentials)
};

/// Builds the edit body.
///
/// `SETTINGS` is sent whole because it is patched key by key on the other side:
/// what goes empty deletes that setting, and what is not mentioned stays as it
/// was. That is why empty settings **do** travel here (as `null`) and not in
/// the creation.
///
/// `CREDENTIALS` is the opposite: only the secrets that were written are sent.
/// An empty secret field means "the one that was already there", not "delete
/// it" — the form can never show the stored token, so leaving it blank is what
/// anyone who only came to change something else does. Sending it empty would
/// erase the token of a channel that was working.
///
/// `TABLES` and `PAYMENT_METHODS` replace their whole selection, the same as
/// `TOOLS`: they are pickers, not patches, so they always travel — an empty
/// `TABLES` clears the sources and an empty `PAYMENT_METHODS` leaves the
/// channel with no way to pay to offer. That is also what lets the picker be
/// saved without this side having to know what was linked before the form
/// opened.
///
/// `PROVIDER` and `SCOPE` are not sent: neither can be changed. The stored
/// secrets and data sources were gathered for one job on one network, and
/// pointing them at another would leave values that mean nothing there; the
/// other job is a new channel.
Map<String, dynamic> editChannelRequest({
  required String id,
  required String role,
  List<String> tables = const [],
  List<String> methods = const [],
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> credentials = const {},
  bool? enabled
}) => {
  "ID": id,
  "ROLE": role,
  "TABLES": tables,
  "PAYMENT_METHODS": methods,
  "SETTINGS": settings,
  "CREDENTIALS": _clean(credentials),
  "ENABLED": ?enabled
};

/// Builds the deletion body. It is just the id: the channel already knows
/// which company it belongs to.
///
/// The deletion is logical and frees the account the channel was using, so the
/// same number or page can be reconnected later. What does **not** come back
/// are the credentials: they go with the channel, and reconnecting means
/// configuring it anew.
Map<String, dynamic> deleteChannelRequest({required String id}) => {"ID": id};

/// Builds the reordering body: the ids in the order they should appear.
///
/// It goes in a single call and not one position per channel because moving one
/// changes where the others end up: sending them one by one would leave the
/// list half-ordered between request and request.
Map<String, dynamic> orderChannelsRequest({required List<String> ids}) =>
  {"CHANNELS": ids};

/// Removes the keys without value from a configuration object.
///
/// The texts are trimmed along the way: a token pasted from the Meta console
/// often comes with a trailing newline, and that invisible space is the
/// difference between a channel that connects and one that returns 401.
Map<String, dynamic> _clean(Map<String, dynamic> config) {
  final cleaned = <String, dynamic>{};

  for (final entry in config.entries) {
    final value = entry.value;

    if (value == null) continue;

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) continue;

      cleaned[entry.key] = text;
      continue;
    }

    cleaned[entry.key] = value;
  }

  return cleaned;
}
