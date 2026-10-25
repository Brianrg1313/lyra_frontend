/// Bodies of the writes for a connection: creation (`POST /v1/connections/`),
/// editing (`PUT /v1/connections/`), deletion (`DELETE /v1/connections/`) and
/// reordering (`PUT /v1/connections/order/`).
///
/// They live apart from the screen because they are the contract with the
/// backend, just like those of the product tables.
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request (see `useBusiness` in
/// `toolkit/backend/api.dart`).
///
/// A connection is **the account and nothing more**: which service it is for,
/// what the business named it, and which credentials it logs in with. What the
/// account answers —direct messages, a post's comments, an ad's comments— is a
/// bot working on top of this same connection, and none of those need
/// credentials of their own. That is why there is no role, no table, and no
/// tools here.
///
/// The configuration is split into two objects and **that split is not the
/// form's, it is the backend's**:
///
/// - `SETTINGS` — what is not secret: account ids, hosts, names. It is read
///   back.
/// - `CREDENTIALS` — tokens and secrets. They only travel one way in: no read
///   ever returns them.
///
/// Which field goes in which is decided by the provider's catalog
/// (`secret: true`), not by this app.
///
/// Shape of the creation body:
///
/// ```json
/// {
///   "PROVIDER": "whatsapp",
///   "NAME": "Main account",
///   "DESCRIPTION": "The number that handles sales",
///   "SETTINGS": { "phone_number_id": "123", "waba_id": "456" },
///   "CREDENTIALS": { "access_token": "EAAG..." }
/// }
/// ```
library;

/// Builds the creation body.
///
/// Only the provider and the name are truly needed: **a connection is
/// deliberately registered before it has its credentials**. The business
/// creates "Instagram — Sales" today and pastes the tokens once Meta issues
/// them, so sending `SETTINGS` and `CREDENTIALS` half filled is the normal case
/// and not an error; the account stays "not ready" until they are completed.
///
/// Empty values are stripped instead of being sent blank: on creation a key
/// with a null value is a key that was never configured, and leaving it would
/// make what isn't configured look like it is.
Map<String, dynamic> createConnectionRequest({
  required String provider,
  required String name,
  required String description,
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> credentials = const {}
}) {
  final trimmed = description.trim();

  return {
    "PROVIDER": provider,
    "NAME": name.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "SETTINGS": _clean(settings),
    "CREDENTIALS": _clean(credentials)
  };
}

/// Builds the edit body.
///
/// The description **always travels**, even empty: in a connection that
/// already exists, emptying it means deleting the one it had, and the backend
/// reads the empty value as "leave none". It's the same rule as editing a
/// table.
///
/// `SETTINGS` is sent whole because it is patched key by key on the other
/// side: what goes empty erases that setting, and what isn't mentioned stays
/// as it was. That's why empty settings **do** travel here and not on
/// creation: it's what lets a mistyped account id be corrected.
///
/// `CREDENTIALS` is the opposite: only the secrets that were actually typed
/// are sent. An empty secret field means "the one already saved", not "delete
/// it" — the form can never show the stored token, so leaving it blank is what
/// anyone who only came to change the name does. Sending it empty would erase
/// the token of an account that was working.
///
/// `PROVIDER` is not sent: it can't be changed. The saved secrets were
/// gathered for one service, and pointing them at another would leave values
/// that mean nothing there; a different service is a new connection.
Map<String, dynamic> editConnectionRequest({
  required String id,
  required String name,
  required String description,
  Map<String, dynamic> settings = const {},
  Map<String, dynamic> credentials = const {},
  bool? enabled
}) => {
  "ID": id,
  "NAME": name.trim(),
  "DESCRIPTION": description.trim(),
  "SETTINGS": settings,
  "CREDENTIALS": _clean(credentials),
  "ENABLED": ?enabled
};

/// Builds the deletion body. It's just the id: the connection already knows
/// which business it belongs to.
///
/// The deletion is logical and frees the account the connection occupied, so
/// the same number or page can be connected again later. What does **not**
/// come back are the credentials: they go with it, and reconnecting means
/// configuring it from scratch. The bots that answered through the account go
/// too, since without an account they have no way to do it.
Map<String, dynamic> deleteConnectionRequest({required String id}) =>
  {"ID": id};

/// Builds the reordering body: the ids in the order they should be shown in.
///
/// It travels in a single call rather than one position per connection because
/// moving one changes where the rest land: sending them one at a time would
/// leave the list half-ordered between requests.
Map<String, dynamic> orderConnectionsRequest({required List<String> ids}) =>
  {"CONNECTIONS": ids};

/// Strips the valueless keys out of a configuration object.
///
/// Text values are trimmed along the way: a token pasted from Meta's console
/// often comes with a trailing line break, and that invisible space is the
/// difference between an account that connects and one that returns 401.
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
