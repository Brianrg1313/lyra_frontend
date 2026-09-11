import 'dart:io';
import 'dart:typed_data';

// PACKAGES
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

/// Choose an image from disk and leave it ready to upload.
///
/// It is two steps and not one because in the middle happens what really matters: the
/// image is cropped before traveling (see `CropImageModal`). What is chosen
/// are the original bytes, what is uploaded are the ones of the crop, and neither of
/// the two is the file the client has stored.

/// Extensions offered to the client in the system dialog.
///
/// They are the ones the backend knows how to read: it recognizes the format by the bytes and
/// rejects everything not in its list —SVG included, which is not an image
/// but a document that can carry script—. Offering here one that is
/// rejected there is letting a file be chosen that later cannot get in.
const List<String> kImageExtensions = ["jpg", "jpeg", "png", "gif", "webp"];

/// How much what is sent weighs at most, in bytes. It is the limit of the
/// backend's multipart (10 MB): exceeding it is a rejection on the other side, so
/// it is warned before uploading anything.
///
/// The crop almost always weighs much less than the original, but the
/// original is measured anyway: a 40 MB photo has to be decoded entirely in memory
/// to crop it, and that is what is better not to attempt.
const int kImageMaxBytes = 10 * 1024 * 1024;

/// Opens the system dialog filtered to images and returns their bytes, or
/// `null` if it was closed without choosing anything.
///
/// [label] is what that group of types is called in the dialog's dropdown, and
/// it arrives translated from the screen: this file has no context to
/// translate it with.
Future<Uint8List?> pickImageBytes({required String label}) async {
  final picked = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: label,
        extensions: kImageExtensions,
        // Windows filters by extension, but macOS and iOS do it by UTI and
        // Android by MIME: without these two the dialog on those platforms
        // would let any file be chosen.
        uniformTypeIdentifiers: const ["public.image"],
        mimeTypes: const [
          "image/jpeg",
          "image/png",
          "image/gif",
          "image/webp"
        ]
      )
    ]
  );

  return picked?.readAsBytes();
}

/// Writes [bytes] to a temporary file and returns it.
///
/// It exists because the upload travels as multipart and the multipart client asks for
/// a file, not a memory block: what is uploaded was born from a crop
/// made on screen and was never a client file. Whoever calls it
/// deletes it when done ([discardTempImage]): the temporary folder is cleaned by the
/// system, but not today.
Future<File> writeTempImage(Uint8List bytes, {String name = "image"}) async {
  final directory = await getTemporaryDirectory();
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final file = File("${directory.path}${Platform.pathSeparator}${name}_$stamp.png");

  await file.writeAsBytes(bytes, flush: true);

  return file;
}

/// Deletes the temporary file of an upload. It does not fail if it is no longer there: it is
/// cleanup, and not being able to clean is not an error worth telling anyone about.
Future<void> discardTempImage(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
