import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:uuid/uuid.dart';

// SERVICES
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/toolkit/api.dart';

/// Where the search box stands. [unavailable] is not a failure: it is what an
/// installation with no Places key answers, and the form hides the box and
/// keeps its fields.
enum BusinessPlacesStatus { idle, searching, ready, empty, error, unavailable }

/// The address search of the location form: `/business/location/search/` and
/// `/business/location/place/`.
///
/// **It is owned by the panel that searches**, not provided by the page: a
/// modal opens above the section's providers, and this holds one editing
/// session — the text being typed, what was answered, and the token Google
/// bills the whole thing under.
///
/// It fills the form and decides nothing: what comes back is written into
/// fields the company can still correct, and every one of them works untouched
/// when the search finds nothing, when the key is missing and when Google is
/// down. That is the same reason the backend keeps the written address and the
/// point as two facts neither derived from the other: a geocoder reads "Av.
/// Principal con calle 3, edificio Sol" worst exactly where this platform
/// sells.
class BusinessPlacesService extends ChangeNotifier {
  BusinessPlacesStatus _status = BusinessPlacesStatus.idle;
  List<PlaceSuggestion> _suggestions = const [];

  /// ISO country of the company, as the backend read it. Empty until the first
  /// search answers, and while the company has not said where it operates.
  String _country = "";

  /// The text the shown list answers, so the same search is not asked twice —
  /// deleting a letter and writing it again is one keystroke and no request.
  String _query = "";

  /// `true` while a pick is being read, so the list cannot be picked twice.
  bool _picking = false;

  /// Answers are dropped when they are not the last one asked for: typing is
  /// faster than a round trip, and an old list arriving late would replace the
  /// one that matches what is on screen.
  int _asked = 0;

  /// Google bills the keystrokes and the pick as **one session** when they
  /// carry the same token. A new one starts after every pick, which is what
  /// closes the previous session.
  String _session = const Uuid().v4();

  bool _disposed = false;

  BusinessPlacesStatus get status => _status;

  List<PlaceSuggestion> get suggestions => _suggestions;

  String get country => _country;

  bool get isPicking => _picking;

  /// Whether there is a search to offer at all. Unknown until the first one is
  /// asked for, which is why it is not a question the form asks first: the box
  /// is drawn, and it takes itself away if the server has no key.
  bool get isAvailable => _status != BusinessPlacesStatus.unavailable;

  /// Asks for the places matching [query].
  ///
  /// Shorter than three characters empties the list without asking: two
  /// letters match half a country, and every keystroke that reaches Places is
  /// billed. The debounce is the search field's own ([SearchInput] waits for
  /// typing to stop), so what arrives here is a finished search.
  Future<void> search(String query) async {
    if (_status == BusinessPlacesStatus.unavailable) return;

    final text = query.replaceAll(RegExp(r"\s+"), " ").trim();

    if (text == _query && _status != BusinessPlacesStatus.error) return;

    _query = text;

    if (text.length < 3) {
      _asked++;
      _suggestions = const [];
      _status = BusinessPlacesStatus.idle;
      notifyListeners();

      return;
    }

    final ticket = ++_asked;

    _status = BusinessPlacesStatus.searching;
    notifyListeners();

    dynamic data;

    try {
      data = await api.get(
        path: "/business/location/search/",
        version: "v1",
        query: {"Q": text, "SESSION": _session}
      );
    } catch (error) {
      if (kDebugMode) print("searchPlaces failed: $error");

      if (ticket != _asked) return;

      _suggestions = const [];
      _status = BusinessPlacesStatus.error;
      notifyListeners();

      return;
    }

    if (ticket != _asked) return;

    // The server saying it has no key is an answer about the endpoint, not an
    // error: the box goes away and the fields below it stay.
    if (data is Map && data["available"] == false) {
      _suggestions = const [];
      _status = BusinessPlacesStatus.unavailable;
      notifyListeners();

      return;
    }

    if (data is Map) {
      _country = (data["country"]?.toString().trim() ?? "").toUpperCase();
    }

    _suggestions = [
      for (final row in catalogRows(data is Map ? data["suggestions"] : null))
        ?PlaceSuggestion.from(row)
    ];

    _status = _suggestions.isEmpty
      ? BusinessPlacesStatus.empty
      : BusinessPlacesStatus.ready;

    notifyListeners();
  }

  /// Reads a picked place, or `null` when it could not be read.
  ///
  /// The error is not shown from here: the panel knows whether it is still on
  /// screen, and a flag raised over a closed form belongs to nothing.
  Future<PlaceModel?> select(PlaceSuggestion suggestion) async {
    if (_picking) return null;

    _picking = true;
    notifyListeners();

    dynamic data;

    try {
      data = await api.get(
        path: "/business/location/place/",
        version: "v1",
        query: {"ID": suggestion.id, "SESSION": _session}
      );
    } catch (error) {
      if (kDebugMode) print("readPlace failed: $error");

      _picking = false;
      notifyListeners();

      rethrow;
    }

    // The pick is what closes the Places session, so whatever is searched for
    // next is a new one — carrying this token on would be billed as the same
    // session forever.
    _session = const Uuid().v4();

    _picking = false;
    notifyListeners();

    return data is Map ? PlaceModel.fromJson(data) : null;
  }

  /// Empties the list without asking anything: what was picked is now in the
  /// fields, and leaving the suggestions under the box reads as if nothing had
  /// happened.
  void clear() {
    _asked++;
    _query = "";
    _suggestions = const [];

    if (_status != BusinessPlacesStatus.unavailable) {
      _status = BusinessPlacesStatus.idle;
    }

    notifyListeners();
  }

  /// A read can answer after the panel that asked for it was closed.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
