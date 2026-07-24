import 'package:flutter/widgets.dart';
import 'package:core/core.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

// MODELS
import 'package:app/screens/home/sections/_sections.dart';

/// Estado y comportamiento de la pantalla principal.
///
/// Se registra en el scope mas alto de la app (`initialBuilder`) porque su
/// estado debe sobrevivir a la navegacion entre las secciones del home.
class HomeService extends ChangeNotifier {
  HomeService() {
    // Lectura sincrona: el box ya quedo abierto en [preload], que corre dentro
    // de `preCall`. Asi el side bar se pinta directo en su ultimo estado y no
    // hay parpadeo de expandido a comprimido al recargar.
    _isSideBarExpanded = _database.get<bool>(_box, _sideBarKey) ?? true;
  }

  static const String _box = "home";
  static const String _sideBarKey = "side_bar_expanded";

  /// Ancho del side bar cuando esta expandido.
  static const double expandedWidth = 240;

  final DatabaseService _database = DatabaseService();

  late bool _isSideBarExpanded;
  bool get isSideBarExpanded => _isSideBarExpanded;

  /// Abre el box del home. Debe llamarse en `preCall`, antes de levantar la
  /// app, porque `DatabaseService.get` solo lee de boxes ya abiertos.
  static Future<void> preload() => DatabaseService().openBox(_box);

  /// Ancho que debe ocupar el side bar segun el estado actual.
  double get sideBarWidth => _isSideBarExpanded
    ? expandedWidth
    : AppSize.action + (AppSize.padding * 2);

  Future<void> toggleSideBar() async {
    _isSideBarExpanded = !_isSideBarExpanded;
    notifyListeners();

    await _database.put(_box, _sideBarKey, _isSideBarExpanded);
  }

  /// Navega a [section]. Cada seccion es una ruta propia, por lo que el cambio
  /// queda reflejado en la URL y se puede volver con el boton de atras.
  void goTo(BuildContext context, HomeSection section) {
    Navis.push(context, section.path);
  }
}
