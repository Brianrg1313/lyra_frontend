import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/files/file_model.dart';

/// Full business, exactly as returned by `GET /business/profile/`.
///
/// It's the business's ID card: what it's called (commercially and
/// legally), its public handle and logo, what it does, what legal status
/// it's in, where it operates, what currency it bills in, and how it's
/// contacted.
///
/// What the business **is**, and nothing more: its people, its branches, its
/// clients and its numbers are each their own section and their own read
/// (`/business/employees/`, `/branches/`, `/clients/`, `/statistics/`),
/// because they change on their own and aren't what this card edits.
///
/// Unlike `BusinessModel`, which arrives compressed in `/init` with just
/// enough to render the selector, this is the full detail of **a single**
/// business: the active one. The endpoint doesn't take an id, it resolves
/// the business from the `business_id` header, so requesting another
/// business's profile means selecting it first (see
/// `BusinessService.loadProfile`).
class BusinessProfileModel {
  /// Public identifier (uuid). It's the one that travels in `business_id`.
  final String id;

  /// Commercial name: the one shown throughout the app.
  final String name;

  /// Legal name. Can differ from the commercial one and may not be set.
  final String legalName;

  /// Public handle, without the at-sign, for links and search.
  final String nickname;

  /// Tagline or short description.
  final String caption;

  /// The business's logo, or `null` if none was uploaded. It's a backend
  /// file: it brings its id and the sizes it exists in, and the address is
  /// built with the base that `/init` provided (see [FileModel]).
  final FileModel? logo;

  final BusinessActivity activity;

  /// The business's legal status. Not editable from the app: it's granted
  /// by the verification process.
  final BusinessVerification verification;
  final DateTime? verifiedDate;

  /// Tax identifier (RIF/NIF/EIN...).
  final String taxId;

  /// ISO 3166-1 alpha-2 code of the country of operation.
  final String country;

  /// Address of the main office, on a single line.
  final String address;

  /// Language tag the business operates in (`es`, `en`, `es-VE`).
  final String language;

  /// Currency code (ISO 4217) the business writes its prices in.
  ///
  /// Like every code in the profile, it's stored raw: whoever needs to
  /// **write** it asks the `/init` catalog how to do it
  /// ([CurrencyCatalogService]), which is the one that knows the symbol,
  /// the side, and the decimals for each one.
  final String currency;

  /// Secondary currencies the business also quotes in, as ISO 4217 codes.
  final List<String> currencies;

  final String phone;

  /// The business's main address: the one from [emails] marked as such. It
  /// arrives loose in addition to being in the list for whoever wants just
  /// one and doesn't need to know how to pick it.
  final String email;

  /// All of the business's addresses, main one first.
  final List<BusinessEmailModel> emails;

  final String website;

  /// The business's legal incorporation date.
  final DateTime? incorporationDate;

  /// `true` if the business was created by whoever is asking. Its creator's
  /// id doesn't come through: this is the only thing the client needs to
  /// know about them.
  final bool owner;

  /// When the business was registered on the platform.
  final DateTime? date;

  const BusinessProfileModel({
    required this.id,
    required this.name,
    this.legalName = "",
    this.nickname = "",
    this.caption = "",
    this.logo,
    this.activity = BusinessActivity.unknown,
    this.verification = BusinessVerification.untrusted,
    this.verifiedDate,
    this.taxId = "",
    this.country = "",
    this.address = "",
    this.language = "",
    this.currency = "",
    this.currencies = const [],
    this.phone = "",
    this.email = "",
    this.emails = const [],
    this.website = "",
    this.incorporationDate,
    this.owner = false,
    this.date
  });

  factory BusinessProfileModel.fromJson(Map json) => BusinessProfileModel(
    id: _text(json["id"]),
    name: _text(json["name"]),
    legalName: _text(json["legal_name"]),
    nickname: _text(json["nickname"]),
    caption: _text(json["caption"]),
    logo: FileModel.from(json["logo"]),
    activity: BusinessActivity.from(json["activity_type"]),
    verification: BusinessVerification.from(json["verification"]),
    verifiedDate: _date(json["verified_date"]),
    taxId: _text(json["tax_id"]),
    country: _text(json["country"]).toUpperCase(),
    address: _text(json["address"]),
    language: _text(json["language"]),
    currency: _text(json["currency"]).toUpperCase(),
    currencies: _codes(json["currencies"]),
    phone: _text(json["phone"]),
    email: _text(json["email"]),
    emails: BusinessEmailModel.fromList(json["emails"]),
    website: _text(json["website"]),
    incorporationDate: _date(json["incorporation_date"]),
    owner: json["owner"] == true,
    date: _date(json["date"])
  );

  /// Whatever is optional in the profile arrives as `null` from the backend
  /// and ends up here as empty text: the profile asks a single question
  /// —whether there's something to show— and with a single way to say
  /// "there's nothing", the other one can't be forgotten.
  static String _text(dynamic value) => value?.toString().trim() ?? "";

  /// Dates travel as ISO text. One that can't be read is worth the same as
  /// one that didn't come: the row isn't shown.
  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _codes(dynamic value) {
    if (value is! List) return const [];

    return [
      for (final code in value)
        if (_text(code).isNotEmpty) _text(code).toUpperCase()
    ];
  }
}

/// Sector a business operates in.
///
/// The codes are those of `companies`.`activity_type` and are the same ones
/// chosen when creating it: signup offers [catalog] and the profile
/// translates what the backend returns, so the two screens can't name the
/// same sector differently.
///
/// The list is **the backend's** and not a selection of it: the sector is
/// validated against a closed enum (`ACTIVITY_TYPE` in `lib/extras/
/// rules.json`), so one too many gets rejected on save and one too few
/// leaves the businesses that have it reading as "Other". If a sector is
/// added there, it's added here.
enum BusinessActivity {
  retail,
  wholesale,
  food,
  hospitality,
  services,
  technology,
  health,
  beauty,
  education,
  manufacturing,
  construction,
  agriculture,
  transport,
  automotive,
  entertainment,
  finance,
  realEstate,
  legal,
  nonprofit,
  other,
  unknown;

  static BusinessActivity from(dynamic code) => switch (
    code?.toString().toUpperCase()
  ) {
    "RETAIL" => retail,
    "WHOLESALE" => wholesale,
    "FOOD" => food,
    "HOSPITALITY" => hospitality,
    "SERVICES" => services,
    "TECHNOLOGY" => technology,
    "HEALTH" => health,
    "BEAUTY" => beauty,
    "EDUCATION" => education,
    "MANUFACTURING" => manufacturing,
    "CONSTRUCTION" => construction,
    "AGRICULTURE" => agriculture,
    "TRANSPORT" => transport,
    "AUTOMOTIVE" => automotive,
    "ENTERTAINMENT" => entertainment,
    "FINANCE" => finance,
    "REAL_ESTATE" => realEstate,
    "LEGAL" => legal,
    "NONPROFIT" => nonprofit,
    "OTHER" => other,
    _ => unknown
  };

  /// The sectors that can be chosen. [unknown] isn't among them: it isn't a
  /// sector, it's the fact that the one the backend sent wasn't recognized.
  ///
  /// The order isn't the backend's nor alphabetical: there are twenty of
  /// them and they're chosen by reading, so similar ones go together —what's
  /// sold, what's serviced, what's produced, what's moved— and "Other" at
  /// the end, which is where you look when none of the previous ones fit.
  static const List<BusinessActivity> catalog = [
    retail,
    wholesale,
    food,
    hospitality,
    services,
    technology,
    health,
    beauty,
    education,
    manufacturing,
    construction,
    agriculture,
    transport,
    automotive,
    entertainment,
    finance,
    realEstate,
    legal,
    nonprofit,
    other
  ];

  /// Code that travels to the backend. Not translated.
  String get value => switch (this) {
    retail => "RETAIL",
    wholesale => "WHOLESALE",
    food => "FOOD",
    hospitality => "HOSPITALITY",
    services => "SERVICES",
    technology => "TECHNOLOGY",
    health => "HEALTH",
    beauty => "BEAUTY",
    education => "EDUCATION",
    manufacturing => "MANUFACTURING",
    construction => "CONSTRUCTION",
    agriculture => "AGRICULTURE",
    transport => "TRANSPORT",
    automotive => "AUTOMOTIVE",
    entertainment => "ENTERTAINMENT",
    finance => "FINANCE",
    realEstate => "REAL_ESTATE",
    legal => "LEGAL",
    nonprofit => "NONPROFIT",
    other => "OTHER",
    unknown => ""
  };

  String label(BuildContext context) => switch (this) {
    retail => S.of(context).business_type_retail,
    wholesale => S.of(context).business_type_wholesale,
    food => S.of(context).business_type_food,
    hospitality => S.of(context).business_type_hospitality,
    services => S.of(context).business_type_services,
    technology => S.of(context).business_type_technology,
    health => S.of(context).business_type_health,
    beauty => S.of(context).business_type_beauty,
    education => S.of(context).business_type_education,
    manufacturing => S.of(context).business_type_manufacturing,
    construction => S.of(context).business_type_construction,
    agriculture => S.of(context).business_type_agriculture,
    transport => S.of(context).business_type_transport,
    automotive => S.of(context).business_type_automotive,
    entertainment => S.of(context).business_type_entertainment,
    finance => S.of(context).business_type_finance,
    realEstate => S.of(context).business_type_real_estate,
    legal => S.of(context).business_type_legal,
    nonprofit => S.of(context).business_type_nonprofit,
    other || unknown => S.of(context).business_type_other
  };
}

/// A business's legal status within the platform.
///
/// It's granted by the verification process and never by the client: it's
/// shown, not edited. It governs what the business can do —an unverified
/// one operates with limits—, so the profile places it next to the name
/// and not in one more row.
enum BusinessVerification {
  untrusted,
  trusted,
  pending,
  verified,
  rejected;

  /// Anything not recognized falls into [untrusted], which is where every
  /// business starts: when in doubt, the most conservative status is shown,
  /// not a trust nobody granted.
  static BusinessVerification from(dynamic code) => switch (
    code?.toString().toLowerCase()
  ) {
    "trusted" => trusted,
    "pending" => pending,
    "verified" => verified,
    "rejected" => rejected,
    _ => untrusted
  };

  String label(BuildContext context) => switch (this) {
    untrusted => S.of(context).business_verification_untrusted,
    trusted => S.of(context).business_verification_trusted,
    pending => S.of(context).business_verification_pending,
    verified => S.of(context).business_verification_verified,
    rejected => S.of(context).business_verification_rejected
  };

  /// Color of the label. Semantic and fixed, like the rest of a business's
  /// states: it communicates the same thing in light and dark theme.
  Color get color => switch (this) {
    verified => const Color(0xFF2E9E5B),
    trusted => const Color(0xFF3D7EC4),
    pending => const Color(0xFFCF9A17),
    rejected => const Color(0xFFD5493F),
    untrusted => const Color(0xFF9A9A9A)
  };

  /// Icon for the label. The checkmark is only for verified: in any other
  /// state it would read as approved.
  IconData get icon => this == verified ? CI.check : CI.info;
}
