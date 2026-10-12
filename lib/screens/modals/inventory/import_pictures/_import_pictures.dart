import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:file_selector/file_selector.dart';

// SERVICES
import 'package:app/services/inventory/picture_import_model.dart';
import 'package:app/services/inventory/picture_import_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Opens the imported pictures' panel over the inventory.
///
/// A side panel: the sheet stays in sight to its left, and its cells swap a pending name
/// for the photo as the files go up.
Future<void> showImportPictures(BuildContext context) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  await showSideModal(
    context: context,
    title: S.of(context).import_pictures_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => const ImportPicturesModal()
  );
}

/// Room for a file name and its reason on one line.
const double _width = 460;

/// How many names or failures are listed: the rest is a count. A catalog can name thousands,
/// and what the person needs is to recognise the folder they belong to.
const int _listed = 30;

/// Where the company's imported pictures are, and the two things a person can do about them:
/// hand over the files the spreadsheets named (a folder, a `.zip`) and queue again what nobody
/// could download. The downloads themselves need nobody: they are only counted here.
///
/// Reads `…/status` on opening and again when the counters move (`image/progress` reaches
/// [PictureImportService]).
class ImportPicturesModal extends StatefulWidget {
  const ImportPicturesModal({super.key});

  @override
  State<ImportPicturesModal> createState() => _ImportPicturesModalState();
}

class _ImportPicturesModalState extends State<ImportPicturesModal> {
  final PictureImportService _service = PictureImportService();

  PictureImportStatus? _status;
  bool _failed = false;
  int _reads = 0;

  /// The counters last read, to tell a move worth a re-read from any other notice.
  PictureProgress? _seen;

  final _retrying = ValueNotifier<bool>(false);

  /// While a folder or a zip is looked through and its files uploaded.
  final _looking = ValueNotifier<bool>(false);

  /// Whether this install can read a folder or a zip: not the web (no files of its own).
  static bool get _hasFiles => !kIsWeb;

  /// Whether a whole folder can be picked: desktops only.
  static bool get _hasFolders => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();

    _service.addListener(_moved);
    unawaited(_read());
  }

  @override
  void dispose() {
    _service.removeListener(_moved);
    _retrying.dispose();
    _looking.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    final read = ++_reads;
    final status = await _service.read();

    if (!mounted || read != _reads) return;

    setState(() {
      _failed = status == null;
      _status = status ?? _status;
      _seen = _service.progress;
    });
  }

  void _moved() {
    final now = _service.progress;
    final seen = _seen;

    if (seen != null && now.files == seen.files && now.failed == seen.failed && now.downloading == seen.downloading) {
      // Only the device's own state moved: the counters drawn are still right.
      if (mounted) setState(() {});
      return;
    }

    unawaited(_read());
  }

  Future<void> _folder() async {
    if (_looking.value) return;

    final path = await getDirectoryPath();
    if (path == null || !mounted) return;

    _looking.value = true;
    final result = await _service.lookIn(Directory(path), names: _status?.names);
    if (mounted) _looking.value = false;

    _matched(result);
  }

  Future<void> _zip() async {
    if (_looking.value) return;

    final picked = await openFile(acceptedTypeGroups: [
      XTypeGroup(
        label: S.of(context).import_pictures_zip_type,
        extensions: const ["zip"],
        uniformTypeIdentifiers: const ["public.zip-archive"],
        mimeTypes: const ["application/zip"]
      )
    ]);

    if (picked == null || !mounted) return;

    _looking.value = true;
    final result = await _service.unzip(File(picked.path), names: _status?.names);
    if (mounted) _looking.value = false;

    _matched(result);
  }

  void _matched(PictureMatchResult result) {
    if (!mounted) return;

    FloatFlag.of(context).message(S.of(context).import_pictures_matched(result.matched));
    unawaited(_read());
  }

  Future<void> _retry() async {
    if (_retrying.value) return;

    _retrying.value = true;

    final queued = await _service.retry();

    if (!mounted) return;

    _retrying.value = false;

    if (queued != null) {
      FloatFlag.of(context).message(S.of(context).import_pictures_retried(queued));
      unawaited(_read());
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final scheme = ThemeColor.of(context);

    if (status == null) {
      return Center(child: _failed
        ? TextMedium(S.of(context).import_pictures_error, color: scheme.text.secondary)
        : const Loading());
    }

    final progress = _service.progress;
    final blocks = [
      if (progress.downloading > 0) _downloading(progress),
      if (status.names.isNotEmpty) _missing(status.names),
      if (status.failures.isNotEmpty) _failures(status.failures)
    ];

    if (blocks.isEmpty) {
      return Center(child: TextMedium(S.of(context).import_pictures_empty, color: scheme.text.secondary));
    }

    return ScrollableWidget(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks
    );
  }

  Widget _downloading(PictureProgress progress) => SettingsBlock(
    title: S.of(context).import_pictures_downloading(progress.downloading),
    subtitle: S.of(context).import_pictures_downloading_hint,
    child: SettingsList(rows: [
      if (progress.server > 0) SettingsValue(
        icon: CI.cloud_network,
        label: S.of(context).import_pictures_server,
        value: "${progress.server}"
      ),
      if (progress.client > 0) SettingsValue(
        icon: CI.wifi,
        label: S.of(context).import_pictures_device,
        value: "${progress.client}"
      )
    ])
  );

  Widget _missing(List<String> names) => SettingsBlock(
    title: S.of(context).import_pictures_missing(names.length),
    subtitle: _hasFiles ? S.of(context).import_pictures_missing_hint : S.of(context).import_pictures_desktop_only,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Lines(lines: names),
        if (_hasFiles) ...[
          SizedBox(height: AppSize.spaceS),
          Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: [
              if (_hasFolders) Button(
                width: null,
                title: S.of(context).import_pictures_folder,
                leftIcon: Icon(CI.documents, color: ThemeColor.of(context).button.text),
                loading: _looking,
                action: _folder
              ),
              Button(
                width: null,
                title: S.of(context).import_pictures_zip,
                leftIcon: Icon(CI.documents_excel, color: ThemeColor.of(context).button.text),
                loading: _looking,
                action: _zip
              )
            ]
          )
        ]
      ]
    )
  );

  Widget _failures(List<PictureFailure> failures) => SettingsBlock(
    title: S.of(context).import_pictures_failed_title,
    subtitle: S.of(context).import_pictures_failed_hint,
    action: Button(
      width: null,
      title: S.of(context).import_pictures_retry,
      loading: _retrying,
      action: _retry
    ),
    child: _Lines(lines: [
      for (final failure in failures)
        failure.reason.isEmpty ? failure.value : "${failure.value} · ${failure.reason}"
    ])
  );
}

/// Up to [_listed] lines, then how many more.
class _Lines extends StatelessWidget {
  const _Lines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final shown = lines.take(_listed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in shown) Padding(
          padding: EdgeInsets.only(bottom: AppSize.gap * 0.5),
          child: TextSmall(line, ellipsis: true)
        ),
        if (lines.length > shown.length)
          TextSmall(
            S.of(context).import_pictures_more(lines.length - shown.length),
            color: scheme.text.secondary
          )
      ]
    );
  }
}
