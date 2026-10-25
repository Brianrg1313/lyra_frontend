import 'dart:io';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/backend/deployment.dart';

/// Name of the form field the logo travels under. The backend decides it:
/// it's the one its multipart reads, and with any other name the request
/// arrives without a file.
const String _kLogoField = "FILE";

/// [BusinessSource] over the backend's REST api.
class BusinessCloudSource implements BusinessSource {
  const BusinessCloudSource();

  /// The endpoint only returns the identifier.
  @override
  Future<String> create(Map<String, dynamic> data) async {
    final id = await api.post(path: "/business/create/", version: "v1", data: data);
    if (id == null) throw const UnreadableAnswer("business/create");

    return id.toString();
  }

  @override
  Future<BusinessProfileModel> profile() async {
    final data = await api.get(path: "/business/profile/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("business/profile");

    return BusinessProfileModel.fromJson(data);
  }

  @override
  Future<void> editProfile(String key, String value) => api.put(
    path: "/business/profile/",
    version: "v1",
    data: {key: value}
  );

  @override
  Future<void> setLogo(File file) => api.file(
    path: "/business/logo/",
    version: "v1",
    file: file,
    field: _kLogoField
  );

  @override
  Future<void> addEmail(Map<String, dynamic> data) =>
    api.post(path: "/business/emails/", version: "v1", data: data);

  @override
  Future<void> editEmail(String id, Map<String, dynamic> data) =>
    api.put(path: "/business/emails/", version: "v1", data: {"ID": id, ...data});

  @override
  Future<void> removeEmail(String id) =>
    api.delete(path: "/business/emails/", version: "v1", data: {"ID": id});

  @override
  Future<String?> sendEmailCode(String id) async {
    final sent = await api.post(path: "/business/emails/verify/", version: "v1", data: {"ID": id});

    return sent?.toString();
  }

  @override
  Future<void> verifyEmail(String id, String code) => api.put(
    path: "/business/emails/verify/",
    version: "v1",
    data: {"ID": id, "CODE": code}
  );

  @override
  Future<BusinessLocationModel> location() async {
    final data = await api.get(path: "/business/location/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("business/location");

    return BusinessLocationModel.fromJson(data);
  }

  @override
  Future<void> editLocation(Map<String, dynamic> request) =>
    api.put(path: "/business/location/", version: "v1", data: request);

  @override
  Future<List<BusinessBranchModel>> branches() async {
    final data = await api.get(path: "/business/branches/", version: "v1");
    if (data is! Map && data is! List) throw const UnreadableAnswer("business/branches");

    return BusinessBranchModel.listFrom(data);
  }

  @override
  Future<void> createBranch(Map<String, dynamic> request) =>
    api.post(path: "/business/branches/", version: "v1", data: request);

  @override
  Future<void> editBranch(Map<String, dynamic> request) =>
    api.put(path: "/business/branches/", version: "v1", data: request);
}
