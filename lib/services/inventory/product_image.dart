// SERVICES
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';
import 'package:app/services/inventory/picture_key.dart';

/// Width of the thumbnail the backend renders for a product photo.
///
/// It is the only one that exists (see `Gallery`: it uploads with the `product` purpose, which
/// crops to 1400px and renders this one), so asking for another does not fail but downloads the
/// full one. The spreadsheet cell draws 40 pixels and this one weighs 8 KB: it is the
/// difference between opening a table and downloading the whole catalog.
const int kProductImageWidth = 320;

/// A product photo, as it ended up stored in its cell.
///
/// The image column of a table stores **a list of file ids** and
/// the first one is the cover (see the backend's `Gallery`). It does not store addresses:
/// an address ages the day the domain or CDN changes, and the id never
/// ages —the address is built with the base that `/init` hands out a single
/// time ([CdnService])—.
///
/// The exception is what arrived in an import: there the column brings the
/// company's address, which is its own datum and not one of our files. It is
/// distinguished by [isStored] and it has to be distinguished, because the two things
/// are deleted differently: ours is removed from the backend, hers is deleted like
/// any cell value is deleted.
///
/// An import can also name a picture by its file (`airforceone-white.png`): that entry
/// waits for the file ([ProductImage.missing]) until the company hands it over, and the
/// backend then swaps it for the stored id in place (`Ingest`). Addresses are swapped the
/// same way once downloaded; until then they draw as they are.
class ProductImage {
  const ProductImage._(this.id, this.address, [this.name = ""]);

  /// A photo the company uploaded through the api: it is one of our files and the only
  /// thing stored about it is its id.
  const ProductImage.stored(String id) : this._(id, "");

  /// An address brought by an import. It is not a platform
  /// file: it cannot be requested by id nor deleted from the backend.
  const ProductImage.external(String address) : this._("", address);

  /// A file name an import wrote, whose file has not been handed over yet: nothing to
  /// draw, but kept, since it is what the backend swaps for the photo when it arrives.
  const ProductImage.missing(String name) : this._("", "", name);

  /// The file name waited for, or empty if the photo is not [isPending].
  final String name;

  /// Public id of the file, or empty if the photo is external.
  final String id;

  /// Address as the company stored it, or empty if the photo is ours.
  final String address;

  /// Whether the bytes are stored by this platform. It is what decides if deleting it is
  /// a deletion against the backend or emptying the cell.
  bool get isStored => id.isNotEmpty;

  /// Whether this is a name still waiting for its file: there is nothing to draw yet.
  bool get isPending => name.isNotEmpty;

  /// The whole photo, to see it large. Empty if there is still no base to
  /// build it with, which reads the same as "no image".
  String get url =>
    isStored ? CdnService().url(FileScope.media, id) : address;

  /// The thumbnail, which is what a cell is drawn with. An external photo does not
  /// have one: it is downloaded as is, which is the only thing there is of it.
  String get thumbnail => isStored
    ? CdnService().url(FileScope.media, id, width: kProductImageWidth)
    : address;

  /// What is stored in the cell for this photo: its id, or the address if it is
  /// the company's.
  String get stored => isStored ? id : isPending ? name : address;

  /// Reads the gallery of a cell.
  ///
  /// The stored value can be any of these four things, and all four
  /// are read the same because all four really exist in the tables: the list
  /// of ids the api writes, a loose id from before galleries existed,
  /// an address brought by an import, or nothing.
  static List<ProductImage> from(dynamic raw) {
    if (raw is List) {
      return [for (final entry in raw) ?_one(entry)];
    }

    final image = _one(raw);

    return image == null ? const [] : [image];
  }

  /// Reads the gallery the backend returns after adding or removing a photo
  /// (`{ images: [...] }`).
  ///
  /// It is the list that remains, already resolved: each of our photos comes as a file
  /// ([FileModel]) and those from an import, as `{ id: null, url }` or, for a name still
  /// waiting for its file, `{ id: null, scope: "missing", name }`. Only what the cell
  /// needs is stored from it —the id, or the address— because it is the only
  /// thing the column stores.
  static List<ProductImage> fromResponse(dynamic data) {
    final images = data is Map ? data["images"] : data;

    if (images is! List) return const [];

    return [
      for (final entry in images)
        if (entry is Map) ?_one(entry["id"] ?? entry["url"] ?? entry["name"])
    ];
  }

  /// What has to be left in the cell for these photos: the list of ids, in
  /// order, which is how the backend stores it.
  static List<String> valuesOf(List<ProductImage> images) =>
    [for (final image in images) image.stored];

  /// An entry of the column, whatever it stored.
  ///
  /// A uuid is one of our files, anything else with an address shape is the
  /// company's, and a picture's file name is one waiting for its file. What is
  /// none of those —"sin foto", an empty— is not a photo and is left out: the
  /// cell shows what can be drawn.
  static ProductImage? _one(dynamic raw) {
    final value = raw?.toString().trim() ?? "";

    if (value.isEmpty) return null;
    if (_uuid.hasMatch(value)) return ProductImage.stored(value);
    if (value.contains("://")) return ProductImage.external(value);

    return isPictureName(value) ? ProductImage.missing(value) : null;
  }

  static final RegExp _uuid = RegExp(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    caseSensitive: false
  );

  @override
  bool operator ==(Object other) =>
    other is ProductImage && other.id == id && other.address == address && other.name == name;

  @override
  int get hashCode => Object.hash(id, address, name);
}
