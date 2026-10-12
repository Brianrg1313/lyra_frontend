import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/inventory/picture_import_model.dart';
import 'package:app/services/inventory/picture_key.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// The capability of the whole flow: the queue lives in the cloud's `Ingest`, a master has none.
const String kPictureImportArea = "inventory.picture_import";

/// What [PictureImportService.lookIn] and [PictureImportService.unzip] did.
class PictureMatchResult {
  const PictureMatchResult({this.sent = 0, this.matched = 0, this.failed = 0});

  /// Files whose name a missing picture had, uploaded.
  final int sent;

  /// Product pictures they filled: one file answers every cell that named it.
  final int matched;

  /// Files the backend refused (too large, not a picture).
  final int failed;
}

/// **The device's half of turning the pictures an import names into files of ours**
/// (`lib/models/tables/MODULE.md` → "Pictures an import names", in the backend).
///
/// The backend downloads what it can on its own. What a host refused it (a 403, a challenge
/// page, an address inside the company's network) waits for one of the company's apps, and
/// this is that app, **with nobody asking**: when `image/progress` says `client` > 0, or a
/// read of `…/status` finds some waiting, it leases a batch (`claim`), downloads each address
/// from this device's connection, hands the bytes over (`deliver`) or says it could not
/// either (`fail`), and claims again until nothing is left. A lease that runs out (the app
/// closed mid-batch) goes back to the next device, so nothing here has to survive a restart.
///
/// The file names an import wrote (`airforceone-white.png`) wait for their file: right after a
/// records import this side looks in the spreadsheet's own folder ([afterImport]), and the
/// panel lets a person point at another folder ([lookIn]) or a `.zip` ([unzip], unpacked here:
/// the API never receives a zip). Only files whose [pictureKey] a missing name has are sent.
///
/// App-wide and a singleton: it keeps listening whatever section is open, which is the point —
/// any device of the company with `inventory.pictures` helps, whoever opens the app next.
/// Cloud only ([kPictureImportArea]); on the web the browser cannot read another host's
/// bytes (no CORS), so a web panel never takes the device's part and those jobs wait for a
/// desktop or mobile app.
class PictureImportService extends ChangeNotifier {
  factory PictureImportService() => _instance;

  PictureImportService._() {
    _unlisten = [
      ConnectionService().on(PictureProgress.event, _onProgress),
      ConnectionService().onRestored(() => unawaited(check()))
    ];

    businessService.addListener(_businessChanged);
  }

  static final PictureImportService _instance = PictureImportService._();

  /// How many jobs one claim leases. The backend caps it at 20; ten keeps a batch well inside
  /// the five-minute lease on a slow connection.
  static const int _batch = 10;

  /// One download's limit. A host that holds the connection open is a failure, not a wait.
  static const Duration _downloadTimeout = Duration(seconds: 30);

  /// The largest picture worth downloading: what `Files` stores is far smaller after
  /// re-encoding, and anything bigger is not a product photo.
  static const int _maxBytes = 25 * 1024 * 1024;

  /// How deep [lookIn] walks under the folder it is given, and how many entries at most: the
  /// pictures of a catalog sit next to it or one or two folders down, and a person pointing
  /// at their whole disk must not freeze the app.
  static const int _maxDepth = 3;
  static const int _maxEntries = 20000;

  /// A zip entry larger than this is skipped unread, and the whole unpacking stops past
  /// [_maxZipTotal]: the archive is the person's, but a zip bomb is still a zip.
  static const int _maxZipEntry = 25 * 1024 * 1024;
  static const int _maxZipTotal = 1024 * 1024 * 1024;

  /// Whether the device downloads at all: never on the web (see the class doc).
  @visibleForTesting
  static bool deviceDownloads = !kIsWeb;

  List<void Function()> _unlisten = const [];

  PictureProgress _progress = PictureProgress.empty;
  String? _business;
  bool _draining = false;
  bool _drainAgain = false;
  bool _matching = false;

  /// The counters as last read or announced.
  PictureProgress get progress => _progress;

  /// Whether this device is downloading a batch now.
  bool get draining => _draining;

  /// Whether a folder or a zip is being looked through now.
  bool get matching => _matching;

  /// Whether this person and this install take part: the cloud, and the pictures permission
  /// (`inventory.pictures`, which every `…/import/images/*` route asks).
  bool get available =>
    CapabilityService().shows(kPictureImportArea) &&
    PermissionsService().can("inventory.pictures");

  /// Reads the counters, and takes the device's part when some wait for it. Called when the
  /// connection comes back, on a company switch and when the inventory opens.
  Future<void> check() async {
    if (!available || businessService.activeId == null) return;

    // The company-wide read applies its counters itself.
    await read();
  }

  /// `…/status`, optionally for one table's import. Null when it could not be read.
  Future<PictureImportStatus?> read({String? tableId}) async {
    if (!available) return null;

    try {
      final data = await api.post(
        path: "/inventory/products/import/images/status/",
        version: "v1",
        data: {"TABLE_ID": ?tableId}
      );

      final status = PictureImportStatus.fromResponse(data);

      // The company-wide read is the indicator's; a table's only narrows the lists.
      if (tableId == null) _apply(status.progress);

      return status;
    } catch (error) {
      if (kDebugMode) print("pictures status failed: $error");
      return null;
    }
  }

  /// Queues again what nobody could download (`…/retry`): the API first, the devices after.
  /// Answers how many, or null when it failed (already shown).
  Future<int?> retry({String? tableId}) async {
    try {
      final data = await api.post(
        path: "/inventory/products/import/images/retry/",
        version: "v1",
        data: {"TABLE_ID": ?tableId}
      );

      unawaited(check());

      return data is num ? data.toInt() : int.tryParse("$data") ?? 0;
    } catch (error) {
      _report(error);
      return null;
    }
  }

  /// Right after a records import from [spreadsheet]: the names it wrote are most often the
  /// pictures sitting next to it, so that folder is looked through without asking anyone.
  ///
  /// Called once the rows are up, which is when `…/scan` has queued the names (it runs behind
  /// the records import's response; the read is delayed a moment for it).
  Future<void> afterImport(String tableId, File spreadsheet) async {
    if (!available || !deviceDownloads) return;

    await Future.delayed(const Duration(seconds: 3));

    final status = await read(tableId: tableId);
    if (status == null || status.names.isEmpty) return;

    await lookIn(spreadsheet.parent, names: status.names);
  }

  /// Uploads from [folder] (and up to [_maxDepth] folders under it) every picture whose name a
  /// missing one has. [names] when already read; otherwise the company's are read here.
  Future<PictureMatchResult> lookIn(Directory folder, {List<String>? names}) => _matchWith(names, (wanted) async {
    final found = <String, File>{};
    int seen = 0;

    Future<void> walk(Directory directory, int depth) async {
      try {
        await for (final entry in directory.list(followLinks: false)) {
          if (++seen > _maxEntries || found.length == wanted.length) return;

          if (entry is File) {
            final name = entry.uri.pathSegments.last;
            final key = pictureKey(name);

            if (isPictureName(name) && wanted.contains(key)) found.putIfAbsent(key, () => entry);
          } else if (entry is Directory && depth < _maxDepth) {
            await walk(entry, depth + 1);
          }
        }
      } catch (error) {
        // A folder this account may not read: what it holds is not there for this side.
        if (kDebugMode) print("pictures folder skipped: $error");
      }
    }

    await walk(folder, 0);

    return [for (final file in found.values) (file: file, temporary: false)];
  });

  /// Unpacks [zip] here and uploads every picture in it whose name a missing one has.
  Future<PictureMatchResult> unzip(File zip, {List<String>? names}) => _matchWith(names, (wanted) async {
    final files = <({File file, bool temporary})>[];
    final taken = <String>{};
    int total = 0;

    final input = InputFileStream(zip.path);
    final archive = ZipDecoder().decodeStream(input);

    try {
      for (final entry in archive.files) {
        if (!entry.isFile) continue;

        final name = entry.name.split(RegExp(r"[\\/]")).last;
        final key = pictureKey(name);

        if (!isPictureName(name) || !wanted.contains(key) || taken.contains(key)) continue;
        if (entry.size > _maxZipEntry) continue;

        total += entry.size;
        if (total > _maxZipTotal) break;

        final bytes = entry.readBytes();
        if (bytes == null || bytes.length > _maxZipEntry) continue;

        taken.add(key);
        files.add((file: await _temporary(bytes, name), temporary: true));
      }
    } finally {
      await archive.clear();
      await input.close();
    }

    return files;
  });

  /// The shared half of [lookIn] and [unzip]: which keys are missing, then each found file to
  /// `…/match` under its own name (sent as `NAME`: the multipart filename would arrive
  /// re-encoded and stop matching a name with an accent).
  Future<PictureMatchResult> _matchWith(
    List<String>? names,
    Future<List<({File file, bool temporary})>> Function(Set<String> wanted) find
  ) async {
    if (!available || _matching) return const PictureMatchResult();

    _matching = true;
    notifyListeners();

    int sent = 0;
    int matched = 0;
    int failed = 0;

    try {
      final missing = names ?? (await read())?.names ?? const [];
      final wanted = {for (final name in missing) pictureKey(name)}..remove("");

      if (wanted.isEmpty) return const PictureMatchResult();

      for (final found in await find(wanted)) {
        try {
          final data = await api.file(
            path: "/inventory/products/import/images/match/",
            version: "v1",
            file: found.file,
            field: "FILE",
            data: {"NAME": found.file.uri.pathSegments.last}
          );

          sent++;
          matched += data is Map && data["matched"] is num ? (data["matched"] as num).toInt() : 0;
        } catch (error) {
          failed++;
          if (kDebugMode) print("pictures match failed: $error");
        } finally {
          if (found.temporary) await _discard(found.file);
        }
      }
    } finally {
      _matching = false;
      notifyListeners();
      unawaited(check());
    }

    return PictureMatchResult(sent: sent, matched: matched, failed: failed);
  }

  /// The socket's counters. `client` > 0 is the call to this device.
  void _onProgress(dynamic data) {
    if (!available) return;

    _apply(PictureProgress.fromJson(data));
  }

  void _apply(PictureProgress progress) {
    _progress = progress;
    notifyListeners();

    if (progress.client > 0) unawaited(_drain());
  }

  /// Claims and downloads batches until the backend has none left for a device. One drain at
  /// a time; a call that arrives meanwhile makes it claim once more at the end, since the
  /// backend may have queued more while the last claim was answered.
  Future<void> _drain() async {
    if (!deviceDownloads) return;

    if (_draining) {
      _drainAgain = true;
      return;
    }

    _draining = true;
    notifyListeners();

    final client = http.Client();
    final business = businessService.activeId;

    try {
      do {
        _drainAgain = false;

        while (available && businessService.activeId == business) {
          final data = await api.post(
            path: "/inventory/products/import/images/claim/",
            version: "v1",
            data: {"LIMIT": _batch}
          );

          final jobs = catalogRows(data);
          if (jobs.isEmpty) break;

          for (final job in jobs) {
            if (businessService.activeId != business) break;
            if (job["id"] == null || job["url"] == null) continue;

            await _download(client, "${job["id"]}", "${job["url"]}");
          }
        }
      } while (_drainAgain && businessService.activeId == business);
    } catch (error) {
      if (kDebugMode) print("pictures claim failed: $error");
    } finally {
      client.close();
      _draining = false;
      notifyListeners();
    }
  }

  /// One leased address: downloaded from this device and delivered, or reported as failed with
  /// what this device saw.
  Future<void> _download(http.Client client, String id, String url) async {
    final Uint8List bytes;

    try {
      final response = await client
        .get(Uri.parse(url), headers: const {"Accept": "image/avif,image/webp,image/*,*/*;q=0.8"})
        .timeout(_downloadTimeout);

      if (response.statusCode != 200) {
        await _fail(id, "http ${response.statusCode}");
        return;
      }

      bytes = response.bodyBytes;
    } catch (error) {
      await _fail(id, error is TimeoutException ? "timeout" : "unreachable");
      return;
    }

    if (bytes.length > _maxBytes) {
      await _fail(id, "too large");
      return;
    }

    if (!looksLikePicture(bytes)) {
      await _fail(id, "not a picture");
      return;
    }

    final file = await _temporary(bytes, "delivery");

    try {
      await api.file(
        path: "/inventory/products/import/images/deliver/",
        version: "v1",
        file: file,
        field: "FILE",
        data: {"ID": id}
      );
    } catch (error) {
      // Refused (too large, not a picture once sniffed) or lost on the way: either way the
      // job ends failed, listed for the person with `…/retry`, rather than coming back to every
      // device each time its lease runs out.
      if (kDebugMode) print("pictures deliver failed: $error");
      await _fail(id, "not stored");
    } finally {
      await _discard(file);
    }
  }

  Future<void> _fail(String id, String reason) async {
    try {
      await api.post(
        path: "/inventory/products/import/images/fail/",
        version: "v1",
        data: {"ID": id, "REASON": reason}
      );
    } catch (error) {
      if (kDebugMode) print("pictures fail failed: $error");
    }
  }

  /// [bytes] in a folder of their own under the temporary one, under [name]: the multipart
  /// asks for a file, and a folder each keeps two zip entries of the same name apart.
  static Future<File> _temporary(Uint8List bytes, String name) async {
    final folder = await Directory.systemTemp.createTemp("lyra-picture");
    final file = File("${folder.path}${Platform.pathSeparator}$name");

    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  /// Deletes what [_temporary] wrote. Cleanup: failing it is not worth telling anyone.
  static Future<void> _discard(File file) async {
    try {
      await file.parent.delete(recursive: true);
    } catch (_) {}
  }

  /// A company switch: the counters were the other company's, and a drain running for it stops
  /// at its next job (the requests would now travel with this one's `business_id`).
  void _businessChanged() {
    final active = businessService.activeId;
    if (active == _business) return;

    _business = active;
    _progress = PictureProgress.empty;
    notifyListeners();

    unawaited(check());
  }

  void _report(Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of().fromError(error is Map && error.isNotEmpty ? error : {"message": error.toString()});
  }

  @override
  void dispose() {
    for (final unlisten in _unlisten) {
      unlisten();
    }

    _unlisten = const [];
    businessService.removeListener(_businessChanged);
    super.dispose();
  }
}
