import 'package:flutter/material.dart';
import 'package:app/services/database/database_service.dart';
import 'package:core/core.dart';

import 'package:window_manager/window_manager.dart';

Future<void> preCall() async {
  final database = DatabaseService();
  final controller = AppController();

  await database.initialize();

  if (controller.isWindows) {
    const windowOptions = WindowOptions(
      size: Size(430, 800),
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
