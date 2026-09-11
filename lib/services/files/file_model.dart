import 'package:app/services/files/cdn_service.dart';

/// Where a file hangs from: the company that uploaded it or the platform.
///
/// It is not our classification: they are two distinct backend spaces
/// (`/rigel/media` and `/rigel/assets`) with two distinct base addresses, and an
/// id from one requested in the other is a 404. That is why the file arrives saying which
/// is its own and there is no need to deduce it from which part of the response it appeared in.
enum FileScope {
  /// What a company uploaded: its logo, a product photo, a document.
  media,

  /// What belongs to the app and is the same for everyone: flags, icons.
  assets;

  static FileScope from(dynamic raw) =>
    raw?.toString().toLowerCase() == "assets" ? assets : media;
}

/// A backend file, as any response that returns one describes it.
///
/// **It does not carry an address.** A file is an id, and the address is built by putting
/// that id behind the base `/init` delivered ([CdnService]). It is the same
/// decision the backend already makes when storing an id in `companies`.`profile` and
/// not a URL: a stored address ages the day the domain, the
/// CDN or the provider changes, and the copy already on screen ages with it. The
/// id never ages.
///
/// What it does carry is which sizes it exists in ([variants]): the thumbnails were
/// rendered when the file was uploaded and they are the ones there are. Asking for one that was not
/// rendered does not fail —the backend returns the full one—, but asking for the one that exists
/// is the difference between downloading 8 KB and downloading 2 MB to draw 44 pixels.
class FileModel {
  const FileModel({
    required this.id,
    this.scope = FileScope.media,
    this.mime = "",
    this.width,
    this.height,
    this.variants = const []
  });

  /// Public id (uuid). It is the only thing the other tables store, and what is
  /// put behind the base to reach the bytes.
  final String id;

  final FileScope scope;

  /// Real content type, read from the bytes and not from the name. It is what decides
  /// whether this is drawn as an image or offered as a document.
  final String mime;

  /// Dimensions of the original, in pixels. Only in images.
  final int? width;
  final int? height;

  /// Widths of the thumbnails this file **has**, from smallest to largest.
  ///
  /// It is per file and not per file type: an image smaller than the thumbnail's width
  /// is stored without it, and this list is how that is known.
  final List<int> variants;

  /// Reads the file from a response, or `null` if there is none.
  ///
  /// Without an id there is no file even if the rest comes: there would be nothing to download it from, and
  /// whoever expected it draws what is drawn when there is no image.
  static FileModel? from(dynamic json) {
    if (json is! Map) return null;

    final id = json["id"]?.toString().trim() ?? "";
    if (id.isEmpty) return null;

    return FileModel(
      id: id,
      scope: FileScope.from(json["scope"]),
      mime: json["mime"]?.toString().trim() ?? "",
      width: _size(json["width"]),
      height: _size(json["height"]),
      variants: _variants(json["variants"])
    );
  }

  static int? _size(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse("$raw");
  }

  /// The available widths, sorted from smallest to largest. They are sorted here and not
  /// trusted to how they came because [sized] picks by iterating.
  static List<int> _variants(dynamic raw) {
    if (raw is! List) return const [];

    final widths = <int>[
      for (final value in raw)
        if (_size(value) case final width? when width > 0) width
    ];

    widths.sort();

    return widths;
  }

  /// The address of the whole file, or `""` if there is still no base to
  /// build it with. Empty reads the same as "no image", which is what is needed.
  String get url => CdnService().url(scope, id);

  /// The smallest thumbnail that exists, or the whole file if none was rendered.
  /// It is for where the size is set by the design and not by the datum: a row
  /// of a listing, an avatar.
  String get thumbnail => sized(1);

  /// The address of the smallest version that **covers** [width] pixels, or the
  /// whole file's if none reaches.
  ///
  /// The smallest that reaches is chosen and not the closest one: an image smaller
  /// than the gap looks blurry, which is worse than taking a little longer.
  String sized(int width) {
    for (final variant in variants) {
      if (variant >= width) return CdnService().url(scope, id, width: variant);
    }

    return url;
  }

  /// Equality by value: the logo travels as part of the profile and of the row of a
  /// listing, which are compared to decide whether it needs repainting.
  @override
  bool operator ==(Object other) =>
    other is FileModel && other.id == id && other.scope == scope;

  @override
  int get hashCode => Object.hash(id, scope);

  @override
  String toString() => "FileModel($id)";
}
