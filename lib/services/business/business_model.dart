// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/files/file_model.dart';

class BusinessModel {
  final String id;
  final String name;
  final String caption;

  /// Business logo, or `null` if none has been uploaded yet. It's the same
  /// file the profile returns ([FileModel]): it carries its id and what sizes
  /// it exists in, and the address is built with the base that `/init` handed
  /// over.
  ///
  /// It comes in `/init` with the name and the caption because that's what a
  /// business is drawn with: the header selector shows it the moment the app
  /// starts, and without the logo here you'd have to fetch each business's
  /// profile to paint a list of five.
  final FileModel? logo;

  /// Only arrive when the business is created from the app; `/init` doesn't
  /// return them and they stay empty for businesses coming from the session.
  final String activity;
  final String profile;

  /// Code of the currency the business invoices in (ISO 4217), as the backend
  /// saves it. It's what its catalog prices are written with.
  ///
  /// The raw code is saved and not the already-resolved currency on purpose:
  /// how an amount is written is decided by the `/init` catalog
  /// ([CurrencyCatalogService]), which can be re-read while the app runs.
  /// Saving the resolved currency here would leave the business writing its
  /// prices with an old symbol until the next launch. Empty if the business
  /// hasn't declared one yet: [BusinessService.currency] resolves it.
  final String currency;

  /// The cloud company a master's company is one with (`business.md` B-30), null while it
  /// isn't linked. A cloud company has none: its [id] is the cloud's.
  final String? cloudId;

  /// What the cloud knows this company by: the `business_id` its requests carry. On a master's
  /// devices signed in online (`hybrid`), the cloud-only areas reach the linked cloud company.
  String get cloudKey => cloudId ?? id;

  const BusinessModel({
    required this.id,
    required this.name,
    this.caption = "",
    this.logo,
    this.activity = "",
    this.profile = "",
    this.currency = "",
    this.cloudId,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json["id"]?.toString() ?? "",
      name: json["name"] ?? "",
      caption: json["caption"] ?? "",
      logo: FileModel.from(json["logo"]),
      activity: json["activity"] ?? "",
      profile: json["profile"] ?? "",
      currency: json["currency"]?.toString().trim().toUpperCase() ?? "",
      cloudId: json["cloudId"] as String?,
    );
  }

  /// Decodes the `/init` columnar table:
  /// `{"keys": ["id", "name", "caption"], "values": [[...], ...]}`, or the list
  /// of objects a master's bootstrap answers ([catalogRows]).
  ///
  /// Columns are read by name and not by position, so the backend can reorder
  /// them or add fields without breaking the parse.
  static List<BusinessModel> fromTable(dynamic table) => [
    for (final row in catalogRows(table)) BusinessModel.fromJson(row)
  ];

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "caption": caption,
      "activity": activity,
      "profile": profile,
      "currency": currency,
    };
  }

  /// Sentinel for [copyWith] for the logo. The rest of the fields are text and
  /// "don't touch it" is said with `null`, but the logo can **be** `null`: a
  /// business that deletes its own logo would keep the old one in the selector
  /// if both things were said the same way.
  static const Object _keep = Object();

  BusinessModel copyWith({
    String? id,
    String? name,
    String? caption,
    Object? logo = _keep,
    String? activity,
    String? profile,
    String? currency,
    String? cloudId,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      caption: caption ?? this.caption,
      logo: identical(logo, _keep) ? this.logo : logo as FileModel?,
      activity: activity ?? this.activity,
      profile: profile ?? this.profile,
      currency: currency ?? this.currency,
      cloudId: cloudId ?? this.cloudId,
    );
  }
}
