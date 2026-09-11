import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// How the backend reads the file uploaded to build a table.
///
/// It is not the file format but **which parser the backend opens it with**, and
/// that is why there are two and not one per extension: `POST /inventory/products/import/.../excel/` and
/// `POST /inventory/products/import/.../csv/`. The Excel branch opens any spreadsheet
/// (xlsx, xls, ods, ...); the CSV one is text separated by commas or semicolons.
enum ImportFormat {
  excel("excel"),
  csv("csv");

  const ImportFormat(this.segment);

  /// The segment of the endpoint path that corresponds to this format.
  final String segment;
}

/// Extensions offered to the user in the system dialog, and the only
/// ones [importFormatOf] recognizes.
///
/// They are the ones the backend knows how to read: the Excel branch uses a library that opens
/// the whole spreadsheet family —not only `.xlsx`—, so they are all listed instead
/// of forcing an export to a particular format. Without the dot: it is how
/// the system dialog asks for them.
const List<String> kImportExtensions = [
  "xlsx",
  "xlsm",
  "xlsb",
  "xls",
  "ods",
  "csv"
];

/// Which parser [path] has to be opened with, or `null` if its extension is not
/// a spreadsheet nor a CSV.
///
/// It is decided by the extension and not by the content because that is what decides the
/// path it is uploaded to, and it is also the only thing known before reading the
/// file. It should never return `null` coming from the dialog (which already filters), but
/// it is checked anyway: on Linux and macOS the user can type the name by
/// hand and skip the filter.
ImportFormat? importFormatOf(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf(".");

  if (dot <= 0 || dot == name.length - 1) return null;

  final extension = name.substring(dot + 1).toLowerCase();

  if (!kImportExtensions.contains(extension)) return null;

  return extension == "csv" ? ImportFormat.csv : ImportFormat.excel;
}

/// The name the imported table is born with: the file's, without extension.
///
/// It is sent from here and the backend is not left to deduce it because on the other
/// side the file name arrives as the multipart built it, and a whole Windows
/// path would end up as the title. Returns empty if nothing usable remains, and
/// in that case the backend puts its own default.
String importTableName(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf(".");

  // A name that starts with a dot (`.csv`) is all extension: nothing remains
  // for the title, and that is why it cuts at `dot >= 0` and not at `dot > 0`.
  return (dot < 0 ? name : name.substring(0, dot)).trim();
}

/// The last segment of a path, with either of the two separators: the
/// dialog returns system paths and on Windows they come with "\\".
String _fileName(String path) {
  final slash = path.lastIndexOf("/");
  final backslash = path.lastIndexOf("\\");
  final cut = slash > backslash ? slash : backslash;

  return cut < 0 ? path : path.substring(cut + 1);
}

/// Opens the system dialog to choose the spreadsheet to import, filtered to
/// [kImportExtensions]: the other files cannot even be selected.
///
/// [label] is what that group of types is called in the dialog's dropdown
/// ("Spreadsheets and CSV"), and it arrives translated from the screen because this file
/// has no context to translate it with.
///
/// Returns `null` if the dialog was closed without choosing anything.
Future<File?> pickImportFile({required String label}) async {
  final picked = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: label,
        extensions: kImportExtensions,
        // Windows filters by extension, but macOS and iOS do it by UTI and
        // Android by MIME: without these two the dialog on those platforms would not
        // filter anything and would let any file be chosen.
        uniformTypeIdentifiers: const [
          "org.openxmlformats.spreadsheetml.sheet",
          "com.microsoft.excel.xls",
          "org.oasis-open.opendocument.spreadsheet",
          "public.comma-separated-values-text"
        ],
        mimeTypes: const [
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "application/vnd.ms-excel",
          "application/vnd.oasis.opendocument.spreadsheet",
          "text/csv"
        ]
      )
    ]
  );

  return picked == null ? null : File(picked.path);
}
