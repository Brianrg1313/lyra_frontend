import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './branches/_branches.dart';
import './clients/_clients.dart';
import './employees/_employees.dart';
import './settings/_settings.dart';
import './statistics/_statistics.dart';

/// Las partes de una empresa que se pueden mirar desde su pagina.
///
/// Son cinco vistas de la **misma** empresa —como le va, quien trabaja en ella,
/// donde opera, a quien le vende y como esta configurada—, no cinco pantallas
/// distintas: por eso son pestanas de una pagina y no secciones del side bar.
/// Se cambia de una a otra sin volver a pedir la empresa ni perder donde se
/// estaba.
///
/// Cada pestana **es una URL** (`/home/business/:id/statistics`): se puede
/// copiar el link de lo que se esta mirando, abrirlo directo y volver con el
/// boton de atras del navegador. Por eso cada una declara su [key] y su
/// [routeKey]: de ahi salen tanto su ruta (ver `routes`) como la navegacion
/// entre pestanas, sin que la tabla de rutas repita esta lista.
///
/// Esta escrito como enum y no como una lista de widgets por lo mismo que
/// `HomeSection`: la barra de pestanas, el titulo, la ruta y el cuerpo salen
/// todos de aca, asi que agregar una pestana es agregar un caso y no tocar
/// cuatro lugares.
enum BusinessTab {
  statistics(key: "statistics", icon: CI.chart),
  employees(key: "employees", icon: CI.employee),
  branches(key: "branches", icon: CI.shop),
  clients(key: "clients", icon: CI.user),
  settings(key: "settings", icon: CI.setting);

  const BusinessTab({required this.key, required this.icon});

  /// Ultimo segmento de la URL de la pestana, y con el que se arma la key de su
  /// ruta.
  final String key;

  final IconData icon;

  /// Pestana con la que se abre la pagina: las estadisticas son lo que contesta
  /// "como le va a esta empresa", que es lo que se viene a ver al entrar. Los
  /// ajustes se abren cuando hay algo que corregir, no todas las veces.
  static const BusinessTab initial = statistics;

  /// Key de la [ScreenRoute] de esta pestana.
  ///
  /// Cada pestana tiene la suya —y no comparten una sola ruta con un `:tab`
  /// como argumento— porque `Navis` avisa del cambio de pantalla por
  /// `currentKey`: con una key para todas, pasar de una pestana a otra
  /// cambiaria la URL sin que el shell se entere, y la pagina seguiria
  /// mostrando la pestana anterior.
  String get routeKey => "business_$key";

  /// URL de esta pestana para la empresa [businessId]. Es la unica fuente del
  /// `url` de su ruta y del link que se copia de la barra del navegador.
  String path(String businessId) => "/home/business/$businessId/$key";

  static final Map<String, BusinessTab> _byRouteKey = {
    for (final tab in values) tab.routeKey: tab
  };

  /// Pestana que se muestra en la pantalla [currentKey], o `null` si esa
  /// pantalla no es una pestana de una empresa.
  static BusinessTab? byRouteKey(String currentKey) => _byRouteKey[currentKey];

  String title(BuildContext context) => switch (this) {
    statistics => S.of(context).business_tab_statistics,
    employees => S.of(context).business_tab_employees,
    branches => S.of(context).business_tab_branches,
    clients => S.of(context).business_tab_clients,
    settings => S.of(context).business_tab_settings
  };

  /// Cuerpo de la pestana. Va dentro de la superficie de la pagina, asi que
  /// **ninguna trae la suya**: lo que dibuja cada una es su contenido pelado.
  Widget build() => switch (this) {
    statistics => const BusinessStatisticsTab(),
    employees => const BusinessEmployeesTab(),
    branches => const BusinessBranchesTab(),
    clients => const BusinessClientsTab(),
    settings => const BusinessSettingsTab()
  };
}
