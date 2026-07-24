import 'package:flutter/material.dart';
import 'package:app/services/database/database_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:core/core.dart';

import 'package:window_manager/window_manager.dart';

Future<void> preCall() async {
  final database = DatabaseService();
  final controller = AppController();

  await database.initialize();

  // Deja el box del home abierto para que HomeService pueda leer el estado
  // persistido del side bar de forma sincrona al construirse.
  await HomeService.preload();

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
