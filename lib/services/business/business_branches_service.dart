import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

enum BusinessBranchesStatus { idle, loading, ready, error }

/// The places the active company works from (`/business/branches/`).
///
/// Provided by the business page (`BusinessDetailSection`), not app-wide:
/// every endpoint answers for the business in the `business_id` header, and a
/// business switch remounts the page, which drops what was read.
///
/// A write rereads the whole list instead of patching it: the backend orders
/// it (the main branch first, then by `position`).
class BusinessBranchesService extends ChangeNotifier {
  BusinessBranchesService({BusinessSource? source}) : _injected = source;

  final BusinessSource? _injected;

  BusinessSource get _source => _injected ?? Sources.business;

  BusinessBranchesStatus _status = BusinessBranchesStatus.idle;
  List<BusinessBranchModel> _branches = const [];

  /// `true` while a write is in flight, so two cannot overlap.
  bool _writing = false;

  bool _disposed = false;

  BusinessBranchesStatus get status => _status;

  List<BusinessBranchModel> get branches => _branches;

  bool get isWriting => _writing;

  /// Reads the branches. Without [force] they are read once per page.
  Future<void> load({bool force = false}) async {
    if (_status == BusinessBranchesStatus.loading) return;
    if (!force && _status == BusinessBranchesStatus.ready) return;

    _status = BusinessBranchesStatus.loading;
    notifyListeners();

    final branches = await _fetch();

    _branches = branches ?? _branches;
    _status = branches == null
      ? BusinessBranchesStatus.error
      : BusinessBranchesStatus.ready;

    notifyListeners();
  }

  /// Opens a branch, from `createBranchRequest`. A refusal (the backend's
  /// ceiling of branches, a name it does not take) is shown in the floating
  /// flag and answers `false`.
  Future<bool> create(BuildContext context, Map<String, dynamic> request) =>
    _write(context, "createBranch", () =>
      _source.createBranch(request));

  /// Edits a branch, from `editBranchRequest` (it carries the `ID`). An empty
  /// body went through: there was nothing to write.
  Future<bool> edit(BuildContext context, Map<String, dynamic> request) async {
    if (request.length <= 1) return true;

    return _write(context, "editBranch", () =>
      _source.editBranch(request));
  }

  Future<bool> _write(
    BuildContext context,
    String name,
    Future<dynamic> Function() send
  ) async {
    if (_writing) return false;

    _writing = true;
    notifyListeners();

    try {
      await send();
    } catch (error) {
      if (kDebugMode) print("$name failed: $error");

      _writing = false;
      notifyListeners();

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty ? error : {"message": error.toString()}
        );
      }

      return false;
    }

    final branches = await _fetch();

    // The header's selector lists the same branches.
    unawaited(BranchService().load(force: true));

    _writing = false;
    _branches = branches ?? _branches;
    if (branches != null) _status = BusinessBranchesStatus.ready;
    notifyListeners();

    return true;
  }

  Future<List<BusinessBranchModel>?> _fetch() async {
    try {
      return await _source.branches();
    } catch (error) {
      if (kDebugMode) print("loadBranches failed: $error");

      return null;
    }
  }

  /// A read can answer after the page that asked for it is gone (a business
  /// switch remounts it), and notifying a disposed notifier throws.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
