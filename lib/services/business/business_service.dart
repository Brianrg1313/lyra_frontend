import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';

import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/toolkit/api.dart';

/// Status of loading the active business's profile (`/business/profile/`).
enum BusinessProfileStatus { idle, loading, ready, error }

/// Name of the form field the logo travels under. The backend decides it:
/// it's the one its multipart reads, and with any other name the request
/// arrives without a file.
const String _kLogoField = "FILE";

/// State and behavior of the client's businesses.
///
/// Concentrates all the business logic that used to live in [ClientService]:
/// the basic collection that arrives in `/init` (for the header's
/// selector), the active business, business creation, and the profile of
/// whichever one is active, which is what the businesses section shows.
///
/// Registered at the app's highest scope (`initialBuilder`) with
/// `ChangeNotifierProvider.value` because its state must survive
/// navigation between sections.
class BusinessService extends ChangeNotifier {
  // ─── Basic collection (comes from /init) ────────────────────────────────────

  List<BusinessModel> _businesses = const [];

  /// Active business. Every time it changes it has to be passed through
  /// [useBusiness]: it travels as a header on every request, so this is the
  /// only place that knows which business the app is talking to.
  BusinessModel? _active;

  List<BusinessModel> get businesses => List.unmodifiable(_businesses);

  /// Active business: the one the client chose or, by default, the first
  /// one the session returned.
  BusinessModel get active {
    assert(_active != null, "BusinessService read without a created business");
    return _active!;
  }

  /// Identifier of the active business, or `null` if there is none (client
  /// with no businesses, or closed session).
  ///
  /// This is what's watched by whoever wants to know about a **business
  /// change** and not about the rest of the service's notifications (see
  /// `BusinessListener` and the home shell): unlike [active], it doesn't
  /// assume there's a business, so it can be read at any time.
  String? get activeId => _active?.id;

  /// Currency the active business bills in, already resolved against the
  /// platform catalog: with symbol, side, and decimals, which is what's
  /// needed to write a price.
  ///
  /// It comes from here and not from each screen because there's only one
  /// for the whole app: it's the one prices in the catalog are written
  /// with, and changing business changes the currency of all of them at
  /// once. Unlike [active], it doesn't assume there's a business: it's read
  /// while rendering, and without a business —or without a declared
  /// currency— it answers with the app's (see
  /// [CurrencyCatalogService.resolve]).
  ///
  /// It's resolved on every read and not stored resolved: the catalog can
  /// be reread while the app is running, and a currency stored here would
  /// keep writing with the old symbol.
  CurrencyModel get currency =>
    CurrencyCatalogService().resolve(currencyCode);

  /// That currency's code, exactly as the backend stores it (`""` if the
  /// business didn't declare one).
  ///
  /// This is what whoever subscribes to the business's currency and
  /// resolves it against the catalog on their own watches (see
  /// `PriceCell`): this way they learn of both a business change and a
  /// catalog reread, which are two notices from two different services.
  String get currencyCode => _active?.currency ?? "";

  int get total => _businesses.length;
  bool get hasBusiness => _businesses.isNotEmpty;

  /// The business with that identifier, or `null` if the client has none.
  ///
  /// The `/init` collection is **all** the businesses the client has
  /// access to, so this also answers the other thing it gets asked:
  /// whether an id that arrived via URL belongs to one of their businesses.
  BusinessModel? byId(String id) {
    for (final business in _businesses) {
      if (business.id == id) return business;
    }
    return null;
  }

  /// Populates the basic collection from `/init`'s columnar table. Called
  /// by [ClientService.resolve] when bringing up the session, before
  /// mounting the tree, which is why it doesn't notify: there's no one
  /// listening yet.
  void seed(dynamic table) {
    _businesses = BusinessModel.fromTable(table);

    // The one this account last worked in, while it still has access to it.
    final last = PreferencesService().lastBusiness;
    _active = (last != null ? byId(last) : null)
      ?? (_businesses.isEmpty ? null : _businesses.first);

    useBusiness(_active?.id);
    PreferencesService().useBusiness(_active?.id);
  }

  /// Changes the active business. Ignores unknown identifiers.
  void selectBusiness(String id) {
    final index = _businesses.indexWhere((business) => business.id == id);
    if (index == -1 || _active?.id == id) return;

    _active = _businesses[index];
    useBusiness(_active!.id);
    PreferencesService().useBusiness(_active!.id);

    // The socket's rooms were joined in its handshake, for the business that
    // was active then; the new one only travels in a new handshake.
    unawaited(ConnectionService().rebind());

    // What's loaded belongs to the business that was just left: the
    // endpoints answer for the active one, so it no longer describes
    // anyone.
    _forgetLoaded();

    notifyListeners();
  }

  /// Creates the business and leaves it as the client's active one.
  ///
  /// The endpoint only returns the identifier, so the rest of the model is
  /// built from what was sent in [data] and from the current session's
  /// profile.
  Future<void> createBusiness(BuildContext context, Map<String, dynamic> data) async {
    final profile = context.read<ClientService>().username;

    final id = await api.post(path: "/business/create/", version: "v1", data: data)
      .catchError((E) {
        if (E is Map) {
          if (!context.mounted) return;

          if (E["action"] != null) throw E["action"];

          FloatFlag.of(context).fromError(E);
        }
      });

    if (id == null) throw "";

    _active = BusinessModel(
      id: id.toString(),
      name: data["LEGAL_NAME"] ?? "",
      activity: data["ACTIVITY_TYPE"] ?? "",
      profile: profile,
      currency: data["CURRENCY"]?.toString().toUpperCase() ?? ""
    );

    _businesses = [..._businesses, _active!];
    // Its creator owns it; `/init` would say so, but it is not reread here.
    PermissionsService().own(_active!.id);
    useBusiness(_active!.id);
    PreferencesService().useBusiness(_active!.id);

    // Same as a switch — and for a first business the socket may not be up at
    // all: a handshake with no business is refused, and never retried.
    unawaited(ConnectionService().rebind());

    // The active business is a different one now, so the loaded profile
    // isn't valid either.
    _forgetLoaded();

    notifyListeners();
  }

  // ─── Profile (comes from /business/profile/) ────────────────────────────────

  BusinessProfileStatus _profileStatus = BusinessProfileStatus.idle;
  BusinessProfileModel? _profile;

  /// Business that what's loaded in [_profile] belongs to. The endpoint
  /// answers for the active one, so a profile that doesn't know whose it
  /// is can't be validated against the one currently being viewed.
  String? _profileOwner;

  BusinessProfileStatus get profileStatus => _profileStatus;

  /// Profile of the active business, or `null` if it hasn't been loaded
  /// yet.
  BusinessProfileModel? get profile => _profile;

  /// Loads the full profile of the active business.
  ///
  /// The endpoint doesn't take an id: it answers for the business in the
  /// `business_id` header, which is the active one. Viewing another
  /// business's profile means **selecting it** ([selectBusiness]) and
  /// requesting it again; that's why what's loaded is discarded every time
  /// the active business changes and one business's data isn't cached in
  /// place of another's.
  ///
  /// It's cached the same way as the detail view: as long as the active
  /// business doesn't change, subsequent visits to the profile don't hit
  /// the backend again unless [force] is requested.
  Future<void> loadProfile({bool force = false}) async {
    final id = activeId;

    // With no active business there's no profile to request: the backend
    // would be answering for none. The screen that shows it already knows
    // what to do without a business.
    if (id == null) return;

    if (_profileStatus == BusinessProfileStatus.loading) return;
    if (!force && _profileStatus == BusinessProfileStatus.ready) return;

    _profileOwner = id;
    _profileStatus = BusinessProfileStatus.loading;
    notifyListeners();

    final data = await api.get(path: "/business/profile/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      return null;
    });

    // The active business may have changed while this was being requested:
    // what arrived describes the previous one, and storing it would show
    // one in place of the other. Loading the new one is already underway
    // or about to be requested, so there's nothing left to do here.
    if (_profileOwner != id) return;

    if (data is! Map) {
      _profileStatus = BusinessProfileStatus.error;
      notifyListeners();
      return;
    }

    _profile = BusinessProfileModel.fromJson(data);
    _profileStatus = BusinessProfileStatus.ready;

    notifyListeners();
  }

  /// Changes a field of the active business's profile against
  /// `PUT /business/profile/`.
  ///
  /// It's sent **one field at a time**, and only the one that was touched:
  /// the profile is corrected row by row from its card, and resending it
  /// whole would mean overwriting everything nobody changed with whatever
  /// this screen has loaded —which may be from a while ago.
  ///
  /// The business's id doesn't travel in the body: as with reads, the
  /// endpoint answers for the one in the `business_id` header, i.e. the
  /// active one.
  ///
  /// An empty value **deletes** the field instead of leaving it as it was:
  /// almost the entire profile is optional, so clearing a field is a valid
  /// edit and not an oversight.
  ///
  /// Returns `true` if the change went through. On error it shows the
  /// floating flag and returns `false`, with the profile left as it was.
  Future<bool> editProfile(
    BuildContext context,
    String key,
    String value
  ) async {
    if (activeId == null) return false;

    try {
      await api.put(
        path: "/business/profile/",
        version: "v1",
        data: {key: value.trim()}
      );
    } catch (error) {
      if (kDebugMode) print("editProfile failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await _reloadProfile();

    return true;
  }

  /// Changes the active business's logo against `POST /business/logo/`.
  ///
  /// [file] is the crop that was made on screen, not the photo the client
  /// chose: which part of the image stays inside the square is decided by
  /// whoever uploads it (see `CropImageModal`), because it's the one thing
  /// the backend can't guess. On the other side it gets re-encoded anyway
  /// —to WebP, stripped of metadata and with its small version— so what
  /// ends up served is never the exact bytes that left here.
  ///
  /// There's no need to delete the previous logo: the backend does it once
  /// the new one is already in place. Like the rest of the writes, it
  /// returns `true` if it went through, and on error shows the floating
  /// flag and leaves the logo as it was.
  Future<bool> setLogo(BuildContext context, File file) async {
    if (activeId == null) return false;

    try {
      await api.file(
        path: "/business/logo/",
        version: "v1",
        file: file,
        field: _kLogoField
      );
    } catch (error) {
      if (kDebugMode) print("setLogo failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await _reloadProfile();

    return true;
  }

  /// Adds an email address to the business against
  /// `POST /business/emails/`.
  ///
  /// A business's first address is left as the main one, whether or not
  /// whoever adds it asked for that: a business whose only email isn't the
  /// one it publishes doesn't make sense. The backend decides that.
  ///
  /// Returns `true` if it went through. On error it shows the floating
  /// flag and returns `false`, with the list left as it was.
  Future<bool> addEmail(BuildContext context, Map<String, dynamic> data) =>
    _writeEmail(context, "addEmail", () => api.post(
      path: "/business/emails/",
      version: "v1",
      data: data
    ));

  /// Changes one of the business's addresses against `PUT /business/emails/`.
  ///
  /// It only changes what's sent, so fixing a typo doesn't require
  /// resending the purpose and the name. `MAIN: true` makes it the main one
  /// and demotes whichever one was; demoting the main one without
  /// promoting another is rejected by the backend, because a business with
  /// addresses and no main one isn't a state worth being able to reach.
  Future<bool> editEmail(
    BuildContext context,
    String id,
    Map<String, dynamic> data
  ) => _writeEmail(context, "editEmail", () => api.put(
    path: "/business/emails/",
    version: "v1",
    data: {"ID": id, ...data}
  ));

  /// Deletes one of the business's addresses against `DELETE /business/emails/`.
  ///
  /// Whoever calls it must have already asked for confirmation: the service
  /// doesn't ask. Deleting the main one is allowed and promotes the oldest
  /// of the remaining ones.
  Future<bool> removeEmail(BuildContext context, String id) =>
    _writeEmail(context, "removeEmail", () => api.delete(
      path: "/business/emails/",
      version: "v1",
      data: {"ID": id}
    ));

  /// Requests the code an address is verified with, against
  /// `POST /business/emails/verify/`.
  ///
  /// Returns the address it was sent to —the stored one, not the one typed
  /// on screen— so the screen can say where to look; a `null` means
  /// nothing was sent and the error was already shown.
  ///
  /// The backend rejects requesting another code within a minute: it's the
  /// only write on this card that writes to an address someone typed, so
  /// an unthrottled "resend" would be a button that sends mail as fast as
  /// it's tapped. That rejection arrives like any other error.
  ///
  /// It doesn't reread the profile: requesting a code doesn't change any
  /// of the business's data.
  Future<String?> sendEmailCode(BuildContext context, String id) async {
    if (activeId == null) return null;

    try {
      final sent = await api.post(
        path: "/business/emails/verify/",
        version: "v1",
        data: {"ID": id}
      );

      return sent?.toString();
    } catch (error) {
      if (kDebugMode) print("sendEmailCode failed: $error");

      if (context.mounted) _report(context, error);

      return null;
    }
  }

  /// Finishes verifying an address against `PUT /business/emails/verify/`.
  ///
  /// The code was read by someone at the mailbox, which is precisely the
  /// proof: what ends up verified is that the business reads that address,
  /// not that the business is who it claims to be (that's its legal
  /// status, and it isn't touched from here).
  ///
  /// Rereads the profile like the rest of the email writes: the same code
  /// can verify more than one row —the same mailbox loaded with two
  /// purposes is still one mailbox— so how the list ends up is decided by
  /// the backend.
  Future<bool> verifyEmail(
    BuildContext context,
    String id,
    String code
  ) => _writeEmail(context, "verifyEmail", () => api.put(
    path: "/business/emails/verify/",
    version: "v1",
    data: {"ID": id, "CODE": code}
  ));

  /// The common body of email writes: send it, and if it went through,
  /// reread the profile.
  ///
  /// It's reread in full rather than patching the list in memory because a
  /// single write touches more than one row: promoting an address demotes
  /// the other one, and deleting the main one promotes the next one. Who
  /// decides how the list ends up is the backend, so it's requested again.
  Future<bool> _writeEmail(
    BuildContext context,
    String name,
    Future<dynamic> Function() write
  ) async {
    if (activeId == null) return false;

    try {
      await write();
    } catch (error) {
      if (kDebugMode) print("$name failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await _reloadProfile();

    return true;
  }

  /// Rereads the profile in place, after a write made **elsewhere** that
  /// changes it.
  ///
  /// Another endpoint can write columns this profile shows (`address`,
  /// `country`): without this, the settings tab keeps the old value until the
  /// business is opened again.
  Future<void> refreshProfile() => _reloadProfile();

  /// Rereads the profile without going through `loading`.
  ///
  /// This is what runs after saving: at that point the state is already
  /// `ready` and the card is fully on screen, so sending it to `loading`
  /// —as [loadProfile] does— would swap the whole card for a spinner just
  /// to rewrite one row.
  ///
  /// It's reread instead of patching what's in memory because how it ends
  /// up stored is decided by the backend: it trims, normalizes the
  /// language, uppercases the country. What's shown is what was left, not
  /// what was sent.
  ///
  /// An error here isn't reported: the change already went through and the
  /// flag would say the opposite. The card is left with the old value
  /// until the next read.
  Future<void> _reloadProfile() async {
    final id = activeId;
    if (id == null) return;

    final data = await api.get(path: "/business/profile/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      return null;
    });

    // Same as in [loadProfile]: the active business may have changed while
    // this was being read, and what arrived describes the previous one.
    if (activeId != id || _profileOwner != id) return;
    if (data is! Map) return;

    _profile = BusinessProfileModel.fromJson(data);
    _syncActive(_profile!);

    notifyListeners();
  }

  /// Pushes down to the basic collection whatever from the profile also
  /// lives there.
  ///
  /// The `/init` one feeds the business selector and the currency every
  /// price in the app is written in, and shares three fields with the
  /// profile: the name, the logo, and the currency. Changing them on the
  /// card and not here would leave the same business named two different
  /// ways, with two faces, and billing in two currencies —the freshly
  /// uploaded logo on its card and the old one in the selector, until the
  /// next launch.
  void _syncActive(BusinessProfileModel profile) {
    final index = _businesses.indexWhere(
      (business) => business.id == profile.id
    );

    if (index == -1) return;

    final current = _businesses[index];

    if (current.name == profile.name &&
      current.currency == profile.currency &&
      current.logo == profile.logo) {
      return;
    }

    final updated = current.copyWith(
      name: profile.name,
      currency: profile.currency,
      logo: profile.logo
    );

    _businesses = List<BusinessModel>.from(_businesses)..[index] = updated;

    if (_active?.id == updated.id) _active = updated;
  }

  /// Shows a write's error the way the rest of the app shows them.
  ///
  /// An error with `action` isn't a notice but a redirect (verify the
  /// email, log in again): it's rethrown so whoever knows how to navigate
  /// can handle it.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Discards whatever is loaded for a business: its profile.
  /// Doesn't notify: it's called by whoever is already going to
  /// notify on their own (a business change, a signup, logging out).
  void _forgetLoaded() {
    _profile = null;
    _profileOwner = null;
    _profileStatus = BusinessProfileStatus.idle;
  }

  void clear() {
    _businesses = const [];
    _active = null;
    useBusiness(null);
    PreferencesService().useBusiness(null);
    _forgetLoaded();
    notifyListeners();
  }
}
