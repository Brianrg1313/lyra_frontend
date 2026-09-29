import 'package:flutter/material.dart';
import 'package:app/services/database/database_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:core/core.dart';

import 'package:window_manager/window_manager.dart';

Future<void> preCall() async {
  final database = DatabaseService();
  final controller = AppController();

  await database.initialize();

  // Leaves the home box open so HomeService can read the side bar's persisted
  // state synchronously as it is constructed.
  await HomeService.preload();

  // After `AppController.instance` (run by `starter` before this): it applies
  // the stored theme and language to it, so the first frame already has them.
  await PreferencesService.preload();

  if (controller.isWindows) {
    const windowOptions = WindowOptions(
      size: Size(1024, 720),
      minimumSize: Size(400, 700),
      center: true,
      title: "Lyra",
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
