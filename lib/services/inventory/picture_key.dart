import 'dart:typed_data';

/// File names a picture may end in: what tells a name an import wrote
/// (`airforceone-white.png`) from any other text. The backend's `Ingest.#namePattern`.
final RegExp _pictureName = RegExp(
  r"\.(png|jpe?g|jfif|webp|gif|bmp|avif|heic|heif|tiff?)$",
  caseSensitive: false
);

/// Whether [name] is a file this platform would take as a product picture.
bool isPictureName(String name) => _pictureName.hasMatch(name.trim());

/// The key a picture's file name is matched by, the same as the backend's `Ingest.key`: the last
/// path segment without extension, accents, case or anything that is not a letter or a digit.
///
/// It must stay equal to the backend's, character for character: the app only uploads to
/// `…/import/images/match` the files whose key a missing name has, and a key computed
/// differently is a picture that sits in the folder and is never sent.
String pictureKey(String name) {
  final segments = name.trim().split(RegExp(r"[\\/]"));
  final base = segments.isEmpty ? "" : segments.last;
  final bare = base.replaceFirst(RegExp(r"\.[a-z0-9]{2,5}$", caseSensitive: false), "");
  final folded = StringBuffer();

  for (final rune in bare.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    folded.write(_folds[char] ?? char);
  }

  return folded.toString().replaceAll(RegExp(r"[^a-z0-9]"), "");
}

/// Accented letters and their base: what `normalize("NFD")` plus dropping the combining marks
/// leaves on the backend, for the letters a catalog writes.
const Map<String, String> _folds = {
  "à": "a", "á": "a", "â": "a", "ã": "a", "ä": "a", "å": "a", "ā": "a", "ă": "a", "ą": "a",
  "ç": "c", "ć": "c", "č": "c",
  "ď": "d",
  "è": "e", "é": "e", "ê": "e", "ë": "e", "ē": "e", "ė": "e", "ę": "e", "ě": "e",
  "ì": "i", "í": "i", "î": "i", "ï": "i", "ī": "i", "į": "i",
  "ñ": "n", "ń": "n", "ň": "n",
  "ò": "o", "ó": "o", "ô": "o", "õ": "o", "ö": "o", "ō": "o", "ő": "o",
  "ŕ": "r", "ř": "r",
  "ś": "s", "š": "s", "ş": "s",
  "ť": "t", "ţ": "t",
  "ù": "u", "ú": "u", "û": "u", "ü": "u", "ū": "u", "ů": "u", "ű": "u", "ų": "u",
  "ý": "y", "ÿ": "y",
  "ź": "z", "ż": "z", "ž": "z"
};

/// Whether [bytes] start like a picture: what a device checks before delivering a download,
/// since a host that refuses often answers 200 with a page. The backend sniffs again whatever
/// arrives; this only spares uploading a challenge page.
bool looksLikePicture(Uint8List bytes) {
  bool at(int offset, List<int> signature) {
    if (bytes.length < offset + signature.length) return false;

    for (int i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }

    return true;
  }

  return at(0, const [0xFF, 0xD8, 0xFF]) ||                     // JPEG
    at(0, const [0x89, 0x50, 0x4E, 0x47]) ||                     // PNG
    at(0, const [0x47, 0x49, 0x46, 0x38]) ||                     // GIF
    (at(0, const [0x52, 0x49, 0x46, 0x46]) && at(8, const [0x57, 0x45, 0x42, 0x50])) || // WebP
    at(0, const [0x42, 0x4D]) ||                                 // BMP
    at(4, const [0x66, 0x74, 0x79, 0x70]) ||                     // AVIF, HEIC (ISO box)
    at(0, const [0x49, 0x49, 0x2A, 0x00]) ||                     // TIFF, little endian
    at(0, const [0x4D, 0x4D, 0x00, 0x2A]);                       // TIFF, big endian
}
