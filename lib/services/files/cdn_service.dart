import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/files/file_model.dart';
import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/lan/image.dart' show LanFileImage;

/// Where images are downloaded from.
///
/// No response of this api carries an image address: it carries **ids** (see
/// [FileModel]). The addresses are built with the two bases `/init` delivers
/// a single time, in `cdn`: [media] for what a company uploaded and [assets] for
/// what belongs to the platform. An address is `<base>/<id>`, and a thumbnail
/// `<base>/<id>@<width>`.
///
/// That the address is configuration and not a stored value is what allows
/// moving the files —to a CDN, to another domain, to another provider— without touching the
/// app or the rows that reference them: a backend variable changes and the
/// next `/init` already hands out the new base. That is why this is a service and not
/// a constant of this app.
///
/// It is a singleton and it is registered in `initialBuilder` with
/// `ChangeNotifierProvider.value`, like the catalogs: it is populated by
/// [ClientService.resolve] before raising the tree, so by the time the
/// first logo is drawn the base is already there.
///
/// ```dart
/// // From the file, which is the normal case.
/// Image.network(business.logo!.thumbnail);
///
/// // With a loose id (a flag from the countries catalog).
/// CdnService().url(FileScope.assets, country.flag);
/// ```
class CdnService extends ChangeNotifier {
  //SINGLETON
  static final CdnService _singleton = CdnService._internal();

  factory CdnService() => _singleton;

  CdnService._internal();

  String _media = "";
  String _assets = "";

  /// Base of the files of a company (`.../rigel/media`).
  String get media => _media;

  /// Base of the platform files (`.../rigel/assets`).
  String get assets => _assets;

  /// Whether there is already something to build addresses with. Without this no image can
  /// be downloaded, but it is not an error either: what is drawn is what is drawn when a
  /// company did not upload a logo.
  bool get isReady => _media.isNotEmpty && _assets.isNotEmpty;

  /// The base of a scope, or `""` if it has not arrived yet.
  String base(FileScope scope) => scope == FileScope.assets ? _assets : _media;

  /// The address of a file, or `""` if there is no base or no id.
  ///
  /// [width] asks for a thumbnail. A width that file does not have does not fail —the
  /// backend returns the full one—, but the one that exists is asked: the file says
  /// which ones it has ([FileModel.variants]).
  String url(FileScope scope, String? id, {int? width}) {
    final file = id?.trim() ?? "";

    // A master serves its own files, over its channel (`LanFileImage`).
    if (Deployment.mode != DeploymentMode.cloud) return file.isEmpty ? "" : LanFileImage.address(file, width: width);

    final root = base(scope);

    if (file.isEmpty || root.isEmpty) return "";

    return width == null ? "$root/$file" : "$root/$file@$width";
  }

  /// Stores the bases `/init` brought.
  ///
  /// The backend can send them relative (`/rigel/media`), which is correct
  /// for a frontend served from its own host and what it returns when there is
  /// no CDN configured. Here that is not enough —this does not run in a page, there
  /// is nothing to resolve them against—, so they are completed with the api origin,
  /// which is where they came from.
  void seed(dynamic data) {
    if (data is! Map) return;

    _media = _absolute(data["media"]);
    _assets = _absolute(data["assets"]);

    notifyListeners();
  }

  /// A base as it can be used: absolute and without a trailing slash.
  static String _absolute(dynamic value) {
    final base = (value?.toString().trim() ?? "").replaceAll(RegExp(r"/+$"), "");

    if (base.isEmpty) return "";
    if (base.contains("://")) return base;

    return "$apiOrigin${base.startsWith("/") ? "" : "/"}$base";
  }

  /// Forgets the bases. For session logout, along with the rest of the
  /// services: the next session brings them again, and it may bring them
  /// different.
  void clear() {
    _media = "";
    _assets = "";

    notifyListeners();
  }
}
