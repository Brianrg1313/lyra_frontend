import 'dart:io';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_profile_model.dart';

/// The company, its site and branches (`docs/offline/specs/business.md`).
///
/// Every method answers for the active company and throws the normalised error
/// (`{message, action}`), or `UnreadableAnswer` for an answer its model can't read.
/// Write bodies are the `*_request.dart` maps the services already build.
abstract interface class BusinessSource {
  /// Creates a company; answers its id.
  Future<String> create(Map<String, dynamic> data);

  Future<BusinessProfileModel> profile();

  /// Writes one profile field.
  Future<void> editProfile(String key, String value);

  /// Replaces the logo with [file], already cropped.
  Future<void> setLogo(File file);

  /// Cloud only, like every business e-mail call.
  Future<void> addEmail(Map<String, dynamic> data);

  Future<void> editEmail(String id, Map<String, dynamic> data);

  Future<void> removeEmail(String id);

  /// Answers the address the code went to, when it says.
  Future<String?> sendEmailCode(String id);

  Future<void> verifyEmail(String id, String code);

  Future<BusinessLocationModel> location();

  Future<void> editLocation(Map<String, dynamic> request);

  Future<List<BusinessBranchModel>> branches();

  Future<void> createBranch(Map<String, dynamic> request);

  Future<void> editBranch(Map<String, dynamic> request);
}
