// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// Where the company's imported pictures are: the counters `image/progress` carries and
/// `…/import/images/status` answers (the backend's `Ingest.#counts`).
class PictureProgress {
  const PictureProgress({
    this.server = 0,
    this.client = 0,
    this.files = 0,
    this.failed = 0,
    this.tables = const []
  });

  static const PictureProgress empty = PictureProgress();

  /// The socket event. Coalesced by the backend to one per company per second.
  static const String event = "image/progress";

  /// Addresses the API is downloading.
  final int server;

  /// Addresses the API was refused and waits for one of the company's devices to download
  /// (`claim` → `deliver`). Above zero is the call to this app.
  final int client;

  /// File names waiting for their file (`match`).
  final int files;

  /// What nobody could download (`retry`).
  final int failed;

  /// The tables whose rows changed since the last event: the open sheet re-reads when it is
  /// one of them. Only the event carries it.
  final List<String> tables;

  /// Pictures still on their way, by either side.
  int get downloading => server + client;

  /// Whether nothing is pending nor failed: the indicator hides.
  bool get isIdle => server == 0 && client == 0 && files == 0 && failed == 0;

  factory PictureProgress.fromJson(dynamic data) {
    if (data is! Map) return empty;

    return PictureProgress(
      server: _count(data["server"]),
      client: _count(data["client"]),
      files: _count(data["files"]),
      failed: _count(data["failed"]),
      tables: [
        if (data["tables"] is List)
          for (final table in data["tables"] as List)
            if (table != null && table.toString().isNotEmpty) table.toString()
      ]
    );
  }

  static int _count(dynamic value) => switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };
}

/// A picture nobody could download, as `…/status` lists it.
class PictureFailure {
  const PictureFailure({required this.id, required this.value, this.reason = ""});

  /// The job.
  final String id;

  /// The address or name the cell wrote.
  final String value;

  /// What the API (`Remote`'s words) or the device (`client: …`) saw.
  final String reason;
}

/// `POST …/import/images/status`: the counters plus the two lists a screen acts on.
class PictureImportStatus {
  const PictureImportStatus({
    this.progress = PictureProgress.empty,
    this.names = const [],
    this.failures = const []
  });

  static const PictureImportStatus empty = PictureImportStatus();

  final PictureProgress progress;

  /// Every file name still missing, as the cell wrote it.
  final List<String> names;

  final List<PictureFailure> failures;

  factory PictureImportStatus.fromResponse(dynamic data) {
    if (data is! Map) return empty;

    return PictureImportStatus(
      progress: PictureProgress.fromJson(data),
      names: [
        if (data["names"] is List)
          for (final name in data["names"] as List)
            if (name != null && name.toString().trim().isNotEmpty) name.toString()
      ],
      failures: [
        for (final row in catalogRows(data["failures"]))
          if (row["id"] != null)
            PictureFailure(
              id: row["id"].toString(),
              value: row["value"]?.toString() ?? "",
              reason: row["reason"]?.toString() ?? ""
            )
      ]
    );
  }
}
