import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:app/services/database/database_service.dart';
import 'package:app/services/home/home_service.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('lyra_home_test');
    Hive.init(temp.path);
  });

  tearDown(() async {
    await DatabaseService().dispose();
    await temp.delete(recursive: true);
  });

  test('el side bar arranca expandido cuando no hay nada guardado', () async {
    await HomeService.preload();

    expect(HomeService().isSideBarExpanded, isTrue);
  });

  test('el estado del side bar sobrevive a un reinicio de la app', () async {
    await HomeService.preload();

    final first = HomeService();
    await first.toggleSideBar();
    expect(first.isSideBarExpanded, isFalse);

    // Simula recargar la app: se cierra todo y se vuelve a abrir el box.
    await DatabaseService().dispose();
    Hive.init(temp.path);
    await HomeService.preload();

    expect(HomeService().isSideBarExpanded, isFalse);
  });
}
