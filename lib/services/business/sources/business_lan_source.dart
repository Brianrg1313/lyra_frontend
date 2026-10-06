import 'dart:io';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/business/sources/business_cloud_source.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/toolkit/deployment.dart';

/// [BusinessSource] over the master (`docs/offline/specs/business.md`): its one company and one
/// site, and its logo.
///
/// The screens send the cloud's request keys (`LEGAL_NAME`, `POSTAL_CODE`); this maps them onto
/// the spec's fields and the answers back onto what the models read, so no model or screen
/// changes (plan principle 8). What doesn't exist on a master (creating a company, e-mails) is
/// closed by `CapabilityService` before a screen can call it; the branches are the cloud's.
class BusinessLanSource implements BusinessSource {
  const BusinessLanSource(this._lan);

  final LanService _lan;

  /// The screens' profile keys → `business.edit`'s (`BusinessFields.editable`).
  static const profileKeys = {
    "NAME": "name",
    "DESCRIPTION": "caption",
    "LEGAL_NAME": "legalName",
    "NICKNAME": "nickname",
    "ACTIVITY_TYPE": "activity",
    "TAX_ID": "taxId",
    "COUNTRY": "country",
    "LANGUAGE": "language",
    "PHONE": "phone",
    "WEBSITE": "website",
    "INCORPORATION_DATE": "incorporationDate",
    "TIMEZONE": "timezone",
  };

  /// The location form's keys → `business.site.edit`'s (`BusinessFields.site`).
  static const siteKeys = {
    "ADDRESS": "address",
    "LANDMARK": "landmark",
    "CITY": "city",
    "REGION": "region",
    "POSTAL_CODE": "postalCode",
    "COUNTRY": "country",
    "LATITUDE": "latitude",
    "LONGITUDE": "longitude",
  };

  @override
  Future<BusinessProfileModel> profile() async {
    final answer = await _lan.call(Ops.businessProfile);
    if (answer is! Map) throw const UnreadableAnswer("business.profile");

    return BusinessProfileModel.fromJson(profileJson(answer));
  }

  /// A master's file id as the `FileModel` json the cloud sends: its one thumbnail is the
  /// variant (`FileSizes.thumbnail`), and `CdnService` turns it into the master's address.
  static Map<String, Object?>? fileJson(Object? id) =>
    id is String && id.isNotEmpty ? {"id": id, "variants": const [FileSizes.thumbnail]} : null;

  /// `business.profile` in the keys [BusinessProfileModel.fromJson] reads. The address is the
  /// site's, which the location page edits.
  static Map<String, dynamic> profileJson(Map answer) => {
    "id": answer["id"],
    "name": answer["name"],
    "legal_name": answer["legalName"],
    "nickname": answer["nickname"],
    "caption": answer["caption"],
    "logo": fileJson(answer["logo"]),
    "activity_type": answer["activity"],
    "verification": answer["verification"],
    "tax_id": answer["taxId"],
    "country": answer["country"],
    "language": answer["language"],
    "currency": answer["currency"],
    "phone": answer["phone"],
    "emails": const <Object?>[],
    "website": answer["website"],
    "incorporation_date": answer["incorporationDate"],
    "owner": answer["owner"],
    "date": answer["created"],
  };

  @override
  Future<void> editProfile(String key, String value) async {
    final field = profileKeys[key];
    // A key the master doesn't keep is a screen this mode should not have shown.
    if (field == null) throw UnsupportedError("No profile key $key on a master");

    await _lan.call(Ops.businessEdit, args: {field: value});
  }

  @override
  Future<BusinessLocationModel> location() async {
    final answer = await _lan.call(Ops.businessSiteGet);
    if (answer is! Map) throw const UnreadableAnswer("business.site.get");

    return BusinessLocationModel.fromJson(locationJson(answer));
  }

  /// `business.site.get` in the keys [BusinessLocationModel.fromJson] reads. The map link is
  /// derived from the point, as the spec says, never stored.
  static Map<String, dynamic> locationJson(Map answer) {
    final latitude = answer["latitude"];
    final longitude = answer["longitude"];

    return {
      "address": answer["address"],
      "landmark": answer["landmark"],
      "city": answer["city"],
      "region": answer["region"],
      "postal_code": answer["postalCode"],
      "country": answer["country"],
      "latitude": latitude,
      "longitude": longitude,
      "maps": latitude is num && longitude is num
        ? "https://www.google.com/maps/search/?api=1&query=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}"
        : "",
    };
  }

  @override
  Future<void> editLocation(Map<String, dynamic> request) async {
    final changes = <String, Object?>{};

    for (final entry in request.entries) {
      final field = siteKeys[entry.key];
      if (field == null) throw UnsupportedError("No site key ${entry.key} on a master");

      changes[field] = entry.value;
    }

    if (changes.isNotEmpty) await _lan.call(Ops.businessSiteEdit, args: changes);
  }

  /// The logo goes up first (`PUT /f`, purpose `logo`), then `business.setLogo` takes it (B-8).
  @override
  Future<void> setLogo(File file) async {
    final fileId = await _lan.upload("logo", await file.readAsBytes());

    await _lan.call(Ops.businessSetLogo, args: {"fileId": fileId});
  }

  /// The welcome's "create company" on a master set up without one (`business.md` B-1): the
  /// form's keys onto the op's fields.
  @override
  Future<String> create(Map<String, dynamic> data) async {
    final answer = await _lan.call(Ops.businessCreate, args: {
      "name": data["LEGAL_NAME"],
      "activity": data["ACTIVITY_TYPE"],
      "country": data["COUNTRY"],
      "currency": data["CURRENCY"],
      "language": data["LANGUAGE"],
    });
    if (answer is! Map || answer["id"] is! String) throw const UnreadableAnswer("business.create");

    return answer["id"] as String;
  }

  // Its site is not a branches list (plan D6): the branches are the cloud's, so in `hybrid` they are
  // read and written there while it answers (`business.branches` is open in `hybrid`). In `local` the
  // capability table hides the tab. E-mails are cloud only and hidden in both.

  @override
  Future<List<BusinessBranchModel>> branches() => _cloud.branches();

  @override
  Future<void> createBranch(Map<String, dynamic> request) => _cloud.createBranch(request);

  @override
  Future<void> editBranch(Map<String, dynamic> request) => _cloud.editBranch(request);

  /// The cloud, for what a master doesn't hold, while the internet is up.
  BusinessCloudSource get _cloud {
    if (!CapabilityService().cloudServices) throw UnsupportedError("A master has one site");

    return const BusinessCloudSource();
  }

  @override
  Future<void> addEmail(Map<String, dynamic> data) => throw UnsupportedError("E-mails are cloud only");

  @override
  Future<void> editEmail(String id, Map<String, dynamic> data) => throw UnsupportedError("E-mails are cloud only");

  @override
  Future<void> removeEmail(String id) => throw UnsupportedError("E-mails are cloud only");

  @override
  Future<String?> sendEmailCode(String id) => throw UnsupportedError("E-mails are cloud only");

  @override
  Future<void> verifyEmail(String id, String code) => throw UnsupportedError("E-mails are cloud only");
}
