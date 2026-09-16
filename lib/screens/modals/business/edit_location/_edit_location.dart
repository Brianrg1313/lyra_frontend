import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_location_request.dart';
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/business/business_places_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/country_flag.dart';

import 'place_search.dart';

/// Opens the panel that edits where the company is.
///
/// Returns the body of `PUT /business/location/` with only what changed —empty
/// when nothing did— or `null` when it was closed without saving.
Future<Map<String, dynamic>?> showLocationForm(
  BuildContext context, {
  required BusinessLocationModel location
}) => showSideModal(
  context: context,
  title: S.of(context).business_location_edit,
  builder: (context) => EditLocationModal(location: location)
).then((value) => value is Map<String, dynamic> ? value : null);

/// Edits where the company is, whole.
///
/// It **returns the request body and writes nothing**, like every panel here:
/// the location service is provided by the business page, which lives under
/// the navigator this panel is opened on.
///
/// ## The search fills the form, it does not replace it
///
/// On top there is an address search ([PlaceSearch], Google Places through the
/// backend): the company writes where it is, picks the place and the fields
/// below are filled in — street line, city, region, postal code, country and
/// the map point, which is the whole reason it exists, since that point is
/// otherwise copied out of a map by hand.
///
/// The fields stay, and stay editable. A geocoder reads worst exactly where
/// this platform sells —"Av. Principal con calle 3, edificio Sol" is an address
/// Places does not find— so a company that the search cannot place writes its
/// address as it always did, and so does one on a server with no Places key,
/// where the box is not even drawn. That is also why nothing is saved from the
/// search itself: what was picked is a draft in the fields until the company
/// reads it and saves.
///
/// Each field's ceiling is its backend column (`companies`): a shorter one here
/// would refuse an address the server accepts, a longer one would be refused
/// after it was typed.
///
/// **The point is one field and not two.** What a map hands out is the pair
/// —Google Maps copies `10.496112, -66.848503` when its numbers are clicked—
/// or a link that carries it, and both are read ([parseLocationPoint]). It is
/// kept next to the address even now that a pick fills it: it is how a point is
/// corrected, erased, or stated by a company whose address no search finds.
///
/// ## The country is one of these fields
///
/// It is part of an address —a city and a street mean nothing without it— so it
/// is stated here, with the rest, and a pick fills it like everything else: a
/// company that moved says so once, in one form, instead of correcting its
/// address in one tab and its country in another.
///
/// It is chosen from the platform's catalog ([CountryCatalogService]) and not
/// typed, because the enabled regions are a list the backend owns; without a
/// catalog it falls back to the two-letter code, which is the only honest way
/// out — an empty dropdown would be a datum that cannot be loaded at all.
///
/// Writing it is not free: the company's clock, its payment rails and the
/// carriers it may deliver with all hang from it. The backend is what handles
/// that (it hands this one key to the company's own write), and the note under
/// the field is what says so before it is saved.
class EditLocationModal extends StatefulWidget {
  const EditLocationModal({super.key, required this.location});

  /// The location the panel opens with, and what the body is compared to.
  final BusinessLocationModel location;

  @override
  State<EditLocationModal> createState() => _EditLocationModalState();
}

class _EditLocationModalState extends State<EditLocationModal> {
  final _form = FormController();

  /// The search box's own form. The address form must not see this field: it
  /// is not part of the location, and a validation over it would block a save
  /// over text nobody is sending anywhere.
  final _searchForm = FormController();

  /// Owned here and not provided: a modal opens above the section's providers,
  /// and this holds one editing session — what is typed, what was answered and
  /// the token Places bills it all under.
  final _places = BusinessPlacesService();

  late final _search = InputController.search(form: _searchForm);

  /// Whether the country can be chosen from the platform's catalog. Read once
  /// and not watched: it arrives with `/init`, before the first screen is
  /// painted, and a form that swapped its field halfway through would throw
  /// away what was already chosen.
  late final bool _listed = CountryCatalogService().isReady;

  /// The countries offered, built **once**: a [SelectInput] re-reads its value
  /// whenever the list it was given is a different one, and a list rebuilt on
  /// every keystroke of the form would do that over and over.
  late final List<SelectOption> _countries = _options();

  /// Changes to remount the country dropdown, which is the only thing that
  /// makes it read its controller again — the same trick the profile's rows use
  /// ([ProfileSelectField]). A pick writes the value; this is what shows it.
  int _revision = 0;

  /// The country a pick just moved the company to. Empty when no pick changed
  /// it, which is the usual case: a shop looks up the street it is already on.
  String _moved = "";

  /// Whether the fields below were written by a pick, which is what the line
  /// asking the company to read them over is for.
  bool _filled = false;

  BusinessLocationModel get _from => widget.location;

  late final _address = _text(
    "ADDRESS",
    _from.address,
    S.of(context).business_location_address,
    min: 3,
    max: 255
  );

  late final _landmark = _text(
    "LANDMARK",
    _from.landmark,
    S.of(context).business_location_landmark,
    min: 3,
    max: 255
  );

  late final _city = _text(
    "CITY",
    _from.city,
    S.of(context).business_location_city,
    min: 2,
    max: 80
  );

  late final _region = _text(
    "REGION",
    _from.region,
    S.of(context).business_location_region,
    min: 2,
    max: 80
  );

  late final _postalCode = _text(
    "POSTAL_CODE",
    _from.postalCode,
    S.of(context).business_location_postal_code,
    min: 3,
    max: 12,
    pattern: "[A-Za-z0-9 -]"
  );

  /// The country. A dropdown over the catalog, or the bare code when there is
  /// none — two ways of stating the same two letters.
  late final _country = _listed
    ? InputController.select(
        key: "COUNTRY",
        form: _form,
        initial: _from.country
      )
    : _text(
        "COUNTRY",
        _from.country,
        S.of(context).business_location_country,
        min: 2,
        max: 2,
        pattern: "[A-Za-z]"
      );

  /// Long enough for a map link, which is what is pasted as often as the
  /// numbers.
  late final _point = InputController(
    key: "POINT",
    form: _form,
    initial: _from.point,
    max: 2048
  );

  /// A text field of the address. Its errors name it as the sheet does.
  InputController _text(
    String key,
    String initial,
    String label, {
    required int min,
    required int max,
    String pattern = "IGNORE"
  }) => InputController(
    key: key,
    form: _form,
    initial: initial,
    min: min,
    max: max,
    pattern: pattern,
    customErrors: {
      InputError.invalid: S.of(context).form_invalid_ma(label),
      InputError.long: S.of(context).form_long_ma(label),
      InputError.incomplete: S.of(context).form_incomplete_ma(label)
    }
  );

  @override
  void dispose() {
    _form.dispose();
    _searchForm.dispose();
    _places.dispose();
    super.dispose();
  }

  /// Same width as the rest of the panels of this app.
  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      // The panel is as tall as the window and the form may not fit a short
      // one. The bottom padding is the panel's own, which leaves it out so
      // what scrolls reaches the edge; the button must not sit on it.
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).business_location_subtitle,
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          PlaceSearch(
            controller: _search,
            places: _places,
            onPicked: _pick
          ),
          TextMedium(S.of(context).business_location_search_manual, bold: true),
          if (_filled) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              S.of(context).business_location_search_filled,
              lines: 2,
              color: scheme.text.secondary
            )
          ],
          if (_moved.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              S.of(context).business_location_search_country(_named(_moved)),
              lines: 3,
              color: scheme.accent
            )
          ],
          SizedBox(height: AppSize.spaceXS),
          Input(
            title: S.of(context).business_location_address,
            placeholder: S.of(context).business_location_address_hint,
            controller: _address,
            leftIcon: Icon(CI.shop, color: scheme.icon)
          ),
          Input(
            title: S.of(context).business_location_landmark,
            placeholder: S.of(context).business_location_landmark_hint,
            controller: _landmark,
            leftIcon: Icon(CI.bookmark, color: scheme.icon)
          ),
          Input(
            title: S.of(context).business_location_city,
            placeholder: S.of(context).business_location_city_hint,
            controller: _city,
            leftIcon: Icon(CI.store, color: scheme.icon)
          ),
          Input(
            title: S.of(context).business_location_region,
            placeholder: S.of(context).business_location_region_hint,
            controller: _region,
            leftIcon: Icon(CI.list, color: scheme.icon)
          ),
          Input(
            title: S.of(context).business_location_postal_code,
            placeholder: S.of(context).business_location_postal_code_hint,
            controller: _postalCode,
            leftIcon: Icon(CI.mail, color: scheme.icon)
          ),
          _countryField(context, scheme),
          TextSmall(
            S.of(context).business_location_country_note,
            lines: 3,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceS),
          Input(
            title: S.of(context).business_location_point,
            placeholder: S.of(context).business_location_point_hint,
            controller: _point,
            leftIcon: Icon(CI.globe_shopping, color: scheme.icon),
            onSubmit: _submit
          ),
          TextSmall(
            S.of(context).business_location_point_help,
            lines: 3,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).save, action: _submit)
        ]
      )
    );
  }

  /// The country: the catalog's list, or the bare code when there is none.
  ///
  /// The dropdown carries no `leftIcon` on purpose, unlike every other field
  /// here: that slot is where the chosen country's flag goes, and a fixed icon
  /// would take it. It is how a country is read everywhere else in this app.
  Widget _countryField(BuildContext context, SchemeColor scheme) {
    if (!_listed) {
      return Input(
        title: S.of(context).business_location_country,
        placeholder: S.of(context).business_location_country_hint,
        controller: _country,
        leftIcon: Icon(CI.home, color: scheme.icon)
      );
    }

    return SelectInput(
      key: ValueKey("COUNTRY_$_revision"),
      controller: _country,
      title: S.of(context).business_location_country,
      placeholder: S.of(context).business_location_country_select,
      emptyText: S.of(context).business_location_country_empty,
      options: _countries
    );
  }

  /// The countries the platform operates in, plus the company's own when the
  /// catalog no longer carries it —the region was disabled after it
  /// registered—: a list without what the company has today would erase it on
  /// the next save.
  List<SelectOption> _options() {
    final catalog = CountryCatalogService();

    return [
      for (final country in catalog.countries) SelectOption(
        value: country.code,
        placeholder: country.name,
        leading: CountryFlag(country: country)
      ),
      if (_from.country.isNotEmpty && catalog.byCode(_from.country) == null)
        SelectOption(value: _from.country, placeholder: _from.country)
    ];
  }

  /// The country's name, or its code while the catalog has none for it.
  ///
  /// Read from the catalog itself and not through the tree: it is a singleton
  /// filled by `/init`, and this panel hangs from a navigator whose providers
  /// are not the page's.
  String _named(String code) => CountryCatalogService().nameOf(code);

  /// What the country field holds, as it travels: the code, uppercased.
  String get _code => _country.value.trim().toUpperCase();

  /// Reads the picked place and writes it into the fields.
  ///
  /// **The address is replaced as a unit** —street, city, region, postal code
  /// and country all come from the same place— which is the same reason this
  /// panel edits the location whole instead of row by row: half of one address
  /// and half of another is an address that leads nowhere. The landmark is left
  /// alone: it is how a customer finds the door, not part of the place.
  Future<void> _pick(PlaceSuggestion suggestion) async {
    PlaceModel? place;

    try {
      place = await _places.select(suggestion);
    } catch (error) {
      if (!mounted) return;

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );

      return;
    }

    final picked = place;

    if (!mounted || picked == null || picked.isEmpty) return;

    _address.textController.text = picked.address;
    _city.textController.text = picked.city;
    _region.textController.text = picked.region;
    _postalCode.textController.text = picked.postalCode;

    final point = picked.point;

    if (point != null) {
      _point.textController.text =
        "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
    }

    final moved = _setCountry(picked.country);

    // The list goes away with the pick: leaving it open under the box reads as
    // if nothing had happened.
    _search.textController.clear();
    _places.clear();

    setState(() {
      _filled = true;
      _moved = moved ? picked.country : "";
    });
  }

  /// Writes the picked place's country, and says whether it moved.
  ///
  /// A place in a country the catalog does not list leaves the field alone: the
  /// catalog **is** which countries a company can be in, and a code that is not
  /// in it could not be chosen by hand either — so the address is filled and
  /// the country stays as the company has it, which is also what the dropdown
  /// keeps showing. Without a catalog the field is two letters and takes the
  /// code as it comes.
  bool _setCountry(String code) {
    if (code.isEmpty || code == _code) return false;

    if (!_listed) {
      _country.textController.text = code;

      return true;
    }

    if (CountryCatalogService().byCode(code) == null) return false;

    // Written to the controller and the dropdown rebuilt, which is the only
    // thing that makes it read the value again.
    _country.selectedValue = code;
    _revision++;

    return true;
  }

  /// Reads the form and closes with the body.
  ///
  /// The point is the one field the form's own checks cannot read: it is
  /// either empty (no point), a pair of coordinates or a link that carries
  /// one, and anything else is said here instead of being sent to be refused.
  void _submit() {
    if (!_form.validate()) return;

    final raw = _point.value.trim();
    final point = raw.isEmpty ? null : parseLocationPoint(raw);

    if (raw.isNotEmpty && point == null) {
      FloatFlag.of(context).error(
        message: S.of(context).business_location_point_invalid
      );
      return;
    }

    Navigator.pop(context, updateLocationRequest(
      from: _from,
      address: _address.value,
      landmark: _landmark.value,
      city: _city.value,
      region: _region.value,
      postalCode: _postalCode.value,
      country: _code,
      point: point
    ));
  }
}
