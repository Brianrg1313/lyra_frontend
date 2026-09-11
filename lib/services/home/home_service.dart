import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:core/core.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

// MODELS
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/pos/_pos.dart';

/// State and behavior of the main screen.
///
/// It is registered in the app's highest scope (`initialBuilder`) because its
/// state must survive navigation between the home sections.
class HomeService extends ChangeNotifier {
  HomeService() {
    // Synchronous read: the box was already left open in [preload], which runs inside
    // `preCall`. Thus the side bar paints directly in its last state and there
    // is no flicker from expanded to collapsed on reload.
    _isSideBarExpanded = _database.get<bool>(_box, _sideBarKey) ?? true;
  }

  static const String _box = "home";
  static const String _sideBarKey = "side_bar_expanded";

  /// Width of the side bar when expanded.
  static const double expandedWidth = 240;

  final DatabaseService _database = DatabaseService();

  late bool _isSideBarExpanded;
  bool get isSideBarExpanded => _isSideBarExpanded;

  /// What was written in the header search, already normalized (no spaces
  /// on the edges and lowercase), which is how the sections compare it.
  ///
  /// The search is a single one for the whole home and lives in the header, which is
  /// outside the open section; the text has to arrive the same to the section
  /// being looked at, so it is stored here, which is what both share.
  ///
  /// It is a separate [ValueNotifier] and not one more field of the service because the
  /// search writes to it on every keystroke: if it notified like the rest, typing
  /// would also rebuild the side bar —which listens to the whole service
  /// with `context.watch`— instead of only the list being filtered.
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>("");
  ValueListenable<String> get searchQuery => _searchQuery;

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  /// Stores what was written in the search. The header calls it; the sections
  /// only read [searchQuery].
  void search(String value) {
    _searchQuery.value = value.trim().toLowerCase();
  }

  /// Empties the search. It is called when changing screens: each section searches
  /// over its own, so entering one with the previous one's text would hide
  /// rows for no reason.
  void clearSearch() => _searchQuery.value = "";

  /// Opens the home box. It must be called in `preCall`, before bringing up the
  /// app, because `DatabaseService.get` only reads from already-open boxes.
  static Future<void> preload() => DatabaseService().openBox(_box);

  /// Width the side bar should occupy according to the current state.
  double get sideBarWidth => _isSideBarExpanded
    ? expandedWidth
    : AppSize.action + (AppSize.padding * 2);

  Future<void> toggleSideBar() async {
    _isSideBarExpanded = !_isSideBarExpanded;
    notifyListeners();

    await _database.put(_box, _sideBarKey, _isSideBarExpanded);
  }

  /// Navigates to [section]. Each section is its own route, so the change
  /// is reflected in the URL and one can go back with the back button.
  void goTo(BuildContext context, HomeSection section) {
    Navis.push(context, section.path);
  }

  /// Opens POS mode. It is not a section but a standalone page (see [Pos]), so
  /// it is navigated apart from [goTo]: when coming back, the home stays where it was.
  ///
  /// It lives here just like [goTo] because the two places that offer it —the side
  /// bar and the header— already read this service, so neither of the two has to
  /// know the URL.
  void goToPos(BuildContext context) {
    Navis.push(context, Pos.path);
  }
}
