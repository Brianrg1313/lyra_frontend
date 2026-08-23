import 'package:flutter/foundation.dart';
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

  /// Lo que se escribio en el buscador del header, ya normalizado (sin espacios
  /// en los bordes y en minusculas), que es como lo comparan las secciones.
  ///
  /// El buscador es uno solo para todo el home y vive en el header, que esta
  /// afuera de la seccion abierta; el texto tiene que llegar igual a la seccion
  /// que se este mirando, asi que se guarda aca, que es lo que ambos comparten.
  ///
  /// Es un [ValueNotifier] aparte y no un campo mas del servicio porque el
  /// buscador escribe en el a cada letra: si notificara como el resto, tipear
  /// volveria a construir tambien el side bar —que escucha al servicio entero
  /// con `context.watch`— en vez de solo la lista que se esta filtrando.
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>("");
  ValueListenable<String> get searchQuery => _searchQuery;

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  /// Guarda lo que se escribio en el buscador. Lo llama el header; las secciones
  /// solo leen [searchQuery].
  void search(String value) {
    _searchQuery.value = value.trim().toLowerCase();
  }

  /// Vacia la busqueda. Se llama al cambiar de pantalla: cada seccion busca
  /// sobre lo suyo, asi que entrar a una con el texto de la anterior esconderia
  /// filas sin motivo.
  void clearSearch() => _searchQuery.value = "";

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
