// PACKAGES
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

/// Saves [bytes] as a file the person keeps: natively where they pick (false
/// when they cancel), in a browser as a download named [name]. The dialog
/// offers files of [extension], labelled [label].
Future<bool> saveFile(
  Uint8List bytes, {
  required String name,
  required String mimeType,
  required String extension,
  required String label
}) async {
  final file = XFile.fromData(bytes, mimeType: mimeType, name: name);

  if (kIsWeb) {
    await file.saveTo(name);

    return true;
  }

  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: [XTypeGroup(label: label, extensions: [extension])]
  );
  if (location == null) return false;

  await file.saveTo(location.path);

  return true;
}
