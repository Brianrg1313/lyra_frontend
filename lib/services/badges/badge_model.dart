import 'package:app/services/catalog/catalog_table.dart';

/// What a badge is about (`model:/badges/catalog.js`): a number of things waiting (`count`), a
/// decision nobody has made yet (`alert`) or a section new to whoever is looking (`news`).
enum BadgeKind {
  count,
  alert,
  news;

  /// An unknown kind reads as an alert: it still draws, it just never counts as a number.
  static BadgeKind of(Object? value) => switch (value) {
    "count" => count,
    "news" => news,
    _ => alert
  };
}

/// How loud a badge is: its colour, and the only thing that ranks two of them. [none] is what an
/// empty place or an empty state answers.
enum BadgeLevel {
  none,
  info,
  warning,
  critical;

  static BadgeLevel of(Object? value) => switch (value) {
    "info" => info,
    "warning" => warning,
    "critical" => critical,
    _ => none
  };

  /// The louder of the two: a place holding a warning and an info is a warning.
  BadgeLevel max(BadgeLevel other) => other.index > index ? other : this;
}

/// One badge standing for this person, as `GET /lyra/v1/badges` lists it.
class BadgeModel {
  const BadgeModel({
    required this.key,
    required this.kind,
    required this.count,
    required this.level,
    this.scope = "",
    this.anchors = const [],
    this.action,
    this.dismissible = false,
    this.title,
    this.data
  });

  /// Stable id (`setup.payments`): what the app keys its own handling by.
  final String key;

  final BadgeKind kind;

  /// What the bubble shows; an `alert` is 1 while it stands.
  final int count;

  final BadgeLevel level;

  /// `business`, `user` or `device`. Read only to explain a badge, never to place it.
  final String scope;

  /// Every place it appears in (`sidebar.business`, `field.payment_method`). The app reads them
  /// through `BadgePlace`, never by hand at a call site.
  final List<String> anchors;

  /// Where the backend thinks clicking it goes. Not the app's routing: the app navigates by
  /// anchor (`badgeRoute`), this is kept for a badge it has no place for yet.
  final String? action;

  /// Whether a person may silence it without doing the work (the bell, the terms, a new
  /// section). The others are cleared by doing it.
  final bool dismissible;

  /// l10n key of its line (`badge_setup_payments`), resolved by the app's `S`.
  final String? title;

  /// Whatever this badge needs to be drawn (the terms version, until when a section is new).
  final Object? data;

  /// A row of the compressed table (or a plain object). A row without a key is not a badge.
  static BadgeModel? fromJson(Map<String, dynamic> json) {
    final key = json["key"];
    if (key is! String || key.isEmpty) return null;

    final count = json["count"];

    return BadgeModel(
      key: key,
      kind: BadgeKind.of(json["kind"]),
      count: count is num ? count.toInt() : int.tryParse("$count") ?? 0,
      level: BadgeLevel.of(json["level"]),
      scope: json["scope"]?.toString() ?? "",
      anchors: [
        if (json["anchors"] is List)
          for (final anchor in json["anchors"] as List) anchor.toString()
      ],
      action: json["action"] is String ? json["action"] as String : null,
      dismissible: json["dismissible"] == true,
      title: json["title"] is String ? json["title"] as String : null,
      data: json["data"]
    );
  }
}

/// What one place in the app draws: how many things, how loud, and which badges they are.
class BadgeAnchor {
  const BadgeAnchor({this.count = 0, this.level = BadgeLevel.none, this.badges = const []});

  static const empty = BadgeAnchor();

  final int count;
  final BadgeLevel level;

  /// The badge keys behind it.
  final List<String> badges;

  bool get isEmpty => badges.isEmpty;
  bool get isNotEmpty => badges.isNotEmpty;

  /// Whether it shows a number (some badge in it counts things) or only a dot (every one is an
  /// alert or news, whose count of 1 says nothing).
  bool counts(BadgeState state) => badges.any((key) => state.byKey(key)?.kind == BadgeKind.count);

  static BadgeAnchor _fromJson(Object? json) {
    if (json is! Map) return empty;

    final count = json["count"];

    return BadgeAnchor(
      count: count is num ? count.toInt() : 0,
      level: BadgeLevel.of(json["level"]),
      badges: [
        if (json["badges"] is List)
          for (final key in json["badges"] as List) key.toString()
      ]
    );
  }
}

/// The whole state of one person's badges in the active company: `GET /lyra/v1/badges`, `/init`'s
/// `badges` and `badges/seen`'s answer, which all share this shape.
class BadgeState {
  const BadgeState({
    this.badges = const [],
    this.anchors = const {},
    this.total = 0,
    this.level = BadgeLevel.none,
    this.date
  });

  static const empty = BadgeState();

  final List<BadgeModel> badges;

  /// The backend's rollup by anchor. A place with nothing pending is absent.
  final Map<String, BadgeAnchor> anchors;

  /// Everything the badges add up to.
  final int total;

  /// The loudest level standing.
  final BadgeLevel level;

  /// When it was measured.
  final DateTime? date;

  bool get isEmpty => badges.isEmpty;

  BadgeModel? byKey(String key) {
    for (final badge in badges) {
      if (badge.key == key) return badge;
    }
    return null;
  }

  /// One anchor as the backend rolled it up.
  BadgeAnchor anchor(String name) => anchors[name] ?? BadgeAnchor.empty;

  /// Several anchors read as one place, each badge counted **once**: a badge anchored to two of
  /// them (`setup.payments` on `sidebar.business` and `business.payments`) is one fact, and adding
  /// the two rollups would draw 2 for it.
  ///
  /// [keys] adds badges by their own key, for a place finer than any anchor the backend names (the
  /// country field is one row of `business.profile`).
  BadgeAnchor union(Iterable<String> names, {Iterable<String> keys = const []}) {
    final wanted = names.toSet();
    final named = keys.toSet();
    var count = 0;
    var level = BadgeLevel.none;
    final found = <String>[];

    for (final badge in badges) {
      if (!named.contains(badge.key) && !badge.anchors.any(wanted.contains)) continue;

      count += badge.count;
      level = level.max(badge.level);
      found.add(badge.key);
    }

    return BadgeAnchor(count: count, level: level, badges: found);
  }

  /// Reads the answer. Badges travel as the compressed table (`Response.parse`) or as plain
  /// objects; what cannot be read is left out rather than failing the whole state, which would
  /// take every dot down with one bad row.
  factory BadgeState.fromJson(Map json) {
    final anchors = json["anchors"];
    final total = json["total"];

    return BadgeState(
      badges: [
        for (final row in catalogRows(json["badges"]))
          ?BadgeModel.fromJson(row)
      ],
      anchors: {
        if (anchors is Map)
          for (final entry in anchors.entries) entry.key.toString(): BadgeAnchor._fromJson(entry.value)
      },
      total: total is num ? total.toInt() : 0,
      level: BadgeLevel.of(json["level"]),
      date: DateTime.tryParse("${json["date"]}")
    );
  }
}
