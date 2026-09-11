/// Decodes a `/init` catalog without tying it to a single format.
///
/// Catalogs travel as the columnar table assembled by `Response.parse` in the
/// backend (`{"keys": [...], "values": [[...], ...]}`), which is the form the
/// session's businesses and the table listing already arrive in. A list of
/// objects is accepted too: it's what the same endpoint returns if it ever
/// stops compressing, and reading both forms costs four lines.
///
/// Columns are read **by name and not by position**, so the backend can reorder
/// them or add one without breaking the parse. What isn't understood returns
/// the empty list and not an exception: a catalog that didn't arrive leaves the
/// app with no options to offer, it doesn't crash it.
List<Map<String, dynamic>> catalogRows(dynamic data) {
  if (data is List) {
    return [
      for (final row in data)
        if (row is Map) row.map((key, value) => MapEntry(key.toString(), value))
    ];
  }

  if (data is! Map) return const [];

  final keys = data["keys"];
  final rows = data["values"];

  if (keys is! List || rows is! List) return const [];

  return [
    for (final row in rows)
      if (row is List)
        {
          for (int i = 0; i < keys.length && i < row.length; i++)
            keys[i].toString(): row[i]
        }
  ];
}
