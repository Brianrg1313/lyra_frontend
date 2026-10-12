import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branch_request.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/business/business_places_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'package:core/images.dart';
import 'package:app/screens/home/sections/business/settings/country_flag.dart';
import 'package:app/screens/home/sections/deliveries/deliveries_map.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import 'phone_field.dart';
import 'place_search.dart';

/// Opens the branch form: a new branch without [branch], that one edited with
/// it. Answers `true` when something was written; the service has already
/// reread the list by then.
///
/// [country] is the company's (ISO code): every branch is in it. It fixes the
/// phone's code and limits the address search. Only the main branch's form
/// asks for it, since there it is the company's own (see [BranchFormModal]).
Future<bool> showBranchForm(
  BuildContext context, {
  required BusinessBranchesService branches,
  required String country,
  BusinessBranchModel? branch
}) async {
  final saved = await showModal(
    context: context,
    title: branch == null
      ? S.of(context).business_branch_create_title
      : S.of(context).business_branch_edit_title,
    size: ModalSize.large,
    builder: (_) => BranchFormModal(
      branches: branches,
      country: country,
      branch: branch
    )
  );

  return saved == true;
}

/// A whole branch in one form: what it is (store or warehouse, whether the
/// bot may fulfil orders from it, whether it is the main one), how it is
/// reached, who it invoices as, and where it is — written and on the map.
///
/// The service comes by constructor and not from the tree: it is provided by
/// the business page, and a modal is a route above it that cannot read it.
///
/// The map is the deliveries one (`DeliveriesMap`), with its own tiles and
/// company location services: it opens on the branch being edited, else on
/// the company's point, where a new branch is most likely near. The address
/// search floats over it ([PlaceSearch]): a pick fills the address, places
/// the point and moves the map. The fields stay editable, and the pin can
/// still be moved by hand — a geocoder is a first draft, not the answer.
///
/// On edit only what changed travels (`editBranchRequest`).
///
/// **The main branch is where the company is.** Its form also asks for the
/// company's country, and its phone is the company's public one; both live on
/// the company (`PUT /business/profile/`), apart from the branch, so saving
/// writes them there too and the settings sheet shows the same.
class BranchFormModal extends StatefulWidget {
  const BranchFormModal({
    super.key,
    required this.branches,
    required this.country,
    this.branch
  });

  final BusinessBranchesService branches;
  final String country;
  final BusinessBranchModel? branch;

  @override
  State<BranchFormModal> createState() => _BranchFormModalState();
}

class _BranchFormModalState extends State<BranchFormModal> {
  final _form = FormController();

  final _map = MapController();
  final _location = BusinessLocationService();
  final _tiles = MapTilesService();

  /// The search box's own form: the branch form must not validate it.
  final _searchForm = FormController();

  /// Owned here: each holds one editing session (the Places token). One per
  /// field that searches — the map's box and the address — since a service's
  /// answers open the dropdown of every search listening to it.
  late BusinessPlacesService _places = _placesIn(_country);
  late BusinessPlacesService _addressPlaces = _placesIn(_country);

  /// The company's country is searched by default (the backend's); another
  /// one chosen in this form is asked for by name.
  BusinessPlacesService _placesIn(String country) => BusinessPlacesService(
    restrictTo: country == widget.country ? "" : country
  );

  late final _search = InputController.search(form: _searchForm);

  late final BusinessBranchModel? _from = widget.branch;

  /// Where the branch is on the map, or `null` while none was placed.
  late LatLng? _point = switch (widget.branch) {
    BusinessBranchModel(:final double latitude, :final double longitude) =>
      LatLng(latitude, longitude),
    _ => null
  };

  /// Where the map opens; fixed, since the map only reads it when it mounts.
  late final LatLng? _opening = _point;

  late bool _storefront = _from?.storefront ?? true;
  late bool _online = _from?.online ?? true;
  late bool _main = _from?.main ?? false;

  /// Whether this form also edits the company: only the main branch's does.
  late final bool _company = _from?.main ?? false;

  /// The company's country, as chosen here (only the main branch's form
  /// changes it).
  late String _country = widget.country;

  late final _countryInput = InputController.select(
    key: "COUNTRY",
    form: _form,
    initial: widget.country
  );

  /// The dial code the form opened with (`58`), or empty when the company's
  /// country has none.
  late final String _openingDial = _dialOf(widget.country);

  /// The code is fixed only when the saved phone is in it (or there is none):
  /// a phone saved with another code is shown whole, never cut wrong.
  late final bool _fixedDial = _openingDial.isNotEmpty &&
    ((_from?.phone ?? "").isEmpty || _from!.phone.startsWith("+$_openingDial"));

  /// The country whose code goes in front of the number: the one chosen,
  /// unless it has none, and then the one the form opened with.
  String get _dialCountry =>
    _dialOf(_country).isEmpty ? widget.country : _country;

  String get _dial => _dialOf(_dialCountry);

  static String _dialOf(String country) =>
    CountryCatalogService().byCode(country)?.phone ?? "";

  @override
  void initState() {
    super.initState();

    _location.load();
    _tiles.load();
  }

  // Built on first use from `build`: their errors read `S.of(context)`, which
  // cannot be read in `initState`.

  /// Any character, up to 64: the backend's `NAME` rule takes every script and
  /// its punctuation, since names are written in any language.
  late final _name = _text(
    "NAME",
    S.of(context).business_branch_name,
    initial: _from?.name ?? "",
    min: 1,
    max: 64,
    obligatory: true
  );

  /// With the code fixed only the number is typed: the backend takes 16
  /// characters counting the `+`, and the code takes up to three. Without it,
  /// the phone is written whole under the backend's own rule.
  late final _phone = _fixedDial
    ? _text(
        "PHONE",
        S.of(context).business_branch_phone,
        initial: (_from?.phone ?? "").isEmpty
          ? ""
          : _from!.phone.substring(_openingDial.length + 1),
        min: 4,
        max: 12,
        pattern: "[0-9]",
        type: InputType.numeric
      )
    : _text(
        "PHONE",
        S.of(context).business_branch_phone,
        initial: _from?.phone ?? "",
        min: 8,
        max: 16,
        pattern: "[0-9+]"
      );

  late final _legalName = _text(
    "LEGAL_NAME",
    S.of(context).business_branch_legal_name,
    initial: _from?.legalName ?? "",
    min: 2,
    max: 160
  );

  late final _taxId = _text(
    "TAX_ID",
    S.of(context).business_branch_tax_id,
    initial: _from?.taxId ?? "",
    min: 3,
    max: 32,
    pattern: "[A-Za-z0-9.-]"
  );

  /// The backend's rule: 1 to 8 letters, digits or `-`, stored uppercase.
  late final _series = _text(
    "SERIES",
    S.of(context).business_branch_series,
    initial: _from?.series ?? "",
    min: 1,
    max: 8,
    pattern: "[A-Za-z0-9-]"
  );

  // Same limits as the backend's location keys (`rules.json`). Any character:
  // addresses are written in every language, and a place picked on the map
  // comes with whatever its source uses.
  late final _address = _text(
    "ADDRESS",
    S.of(context).business_location_address,
    initial: _from?.address ?? "",
    min: 3,
    max: 255
  );
  late final _landmark = _text(
    "LANDMARK",
    S.of(context).business_location_landmark,
    initial: _from?.landmark ?? "",
    min: 3,
    max: 255
  );
  late final _city = _text(
    "CITY",
    S.of(context).business_location_city,
    initial: _from?.city ?? "",
    min: 2,
    max: 80
  );
  late final _region = _text(
    "REGION",
    S.of(context).business_location_region,
    initial: _from?.region ?? "",
    min: 2,
    max: 80
  );
  late final _postalCode = _text(
    "POSTAL_CODE",
    S.of(context).business_location_postal_code,
    initial: _from?.postalCode ?? "",
    min: 3,
    max: 12,
    pattern: "[A-Za-z0-9 -]"
  );

  InputController _text(
    String key,
    String label, {
    required String initial,
    required int min,
    required int max,
    String pattern = "IGNORE",
    bool obligatory = false,
    InputType type = InputType.text
  }) => InputController(
    key: key,
    form: _form,
    initial: initial,
    min: min,
    max: max,
    pattern: pattern,
    type: type,
    obligatory: obligatory,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(label),
      InputError.invalid: S.of(context).form_invalid_ma(label),
      InputError.long: S.of(context).form_long_ma(label),
      InputError.incomplete: S.of(context).form_incomplete_ma(label)
    }
  );

  @override
  void dispose() {
    _form.dispose();
    _map.dispose();
    _location.dispose();
    _tiles.dispose();
    _searchForm.dispose();
    _places.dispose();
    _addressPlaces.dispose();
    super.dispose();
  }

  static const double _width = 420;

  /// The map's column beside the form: wider than the form, since placing a
  /// pin wants more streets in view than a field wants room.
  static const double _mapWidth = 560;

  /// Tallest the form gets; the fields scroll inside it. A shorter window
  /// caps it further: the modal hands down only the room under its header.
  static const double _height = 640;

  @override
  Widget build(BuildContext context) {
    // Side by side only when both columns fit in what the modal may take;
    // otherwise the map goes into the form, before the address.
    final room = ModalSize.large.maxWidth(context) - AppSize.padding * 2;
    final wide = room >= _width + AppSize.spaceL + _mapWidth;

    final map = MultiProvider(
      providers: [
        ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
        ChangeNotifierProvider<MapTilesService>.value(value: _tiles)
      ],
      child: _PointPicker(
        search: PlaceSearch(
          controller: _search,
          places: _places,
          onPicked: _pick
        ),
        controller: _map,
        opening: _opening,
        point: _point,
        onPoint: (point) => setState(() => _point = point)
      )
    );

    final scroll = EdgeInsets.only(bottom: AppSize.padding);

    if (!wide) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _width,
          maxWidth: _width,
          maxHeight: _height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Its bar goes in the modal's right padding.
            Flexible(child: ScrollableWidget(
              padding: scroll,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_fields(context, map: map)]
            )),
            SizedBox(height: AppSize.spaceS),
            _button(context)
          ]
        )
      );
    }

    return SizedBox(
      width: _width + AppSize.spaceL + _mapWidth,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _height),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The map is at the modal's right edge, not this column: the
                  // bar stays here, with a gutter so it does not sit on the
                  // fields.
                  Expanded(child: ScrollableWidget(
                    modalBar: false,
                    padding: scroll.copyWith(right: AppSize.spaceS),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_fields(context)]
                  )),
                  SizedBox(height: AppSize.spaceS),
                  _button(context)
                ]
              )
            ),
            SizedBox(width: AppSize.spaceL),
            SizedBox(width: _mapWidth, child: map)
          ]
        )
      )
    );
  }

  Widget _button(BuildContext context) => Button(
    title: _from == null
      ? S.of(context).business_branches_add
      : S.of(context).business_branch_save,
    loading: _form.loading,
    action: _submit
  );

  /// The form's fields. With [map] (one column, no room beside them) the map
  /// goes just before the address: its search fills those fields, so it is
  /// met first and they are read after it.
  Widget _fields(BuildContext context, {Widget? map}) {
    final scheme = ThemeColor.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextSmall(
          S.of(context).business_branch_create_subtitle,
          lines: 2,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        Input(
          title: S.of(context).business_branch_name,
          placeholder: S.of(context).business_branch_name_hint,
          controller: _name,
          leftIcon: Icon(CI.shop, color: scheme.icon),
          autofocus: _from == null
        ),
        _KindPicker(
          storefront: _storefront,
          onChanged: (value) => setState(() => _storefront = value)
        ),
        SettingsToggle(
          value: _online,
          label: _online
            ? S.of(context).business_branch_online_on
            : S.of(context).business_branch_online_off,
          message: S.of(context).business_branch_online_note,
          toggle: () => setState(() => _online = !_online)
        ),
        // The main flag is moved to a branch, never taken off one: on the
        // main branch there is nothing to toggle.
        if (!(_from?.main ?? false)) ...[
          SizedBox(height: AppSize.gap),
          SettingsToggle(
            value: _main,
            label: S.of(context).business_branch_main_toggle,
            message: S.of(context).business_branch_main_note,
            toggle: () => setState(() => _main = !_main)
          )
        ],
        _Heading(title: S.of(context).business_branch_section_contact),
        BranchPhoneField(
          controller: _phone,
          country: _fixedDial ? CountryCatalogService().byCode(_dialCountry) : null
        ),
        _Heading(
          title: S.of(context).business_branch_section_invoicing,
          note: S.of(context).business_branch_invoicing_note
        ),
        Input(
          title: S.of(context).business_branch_legal_name,
          placeholder: S.of(context).business_branch_legal_name_hint,
          controller: _legalName
        ),
        Input(
          title: S.of(context).business_branch_tax_id,
          placeholder: S.of(context).business_branch_tax_id_hint,
          controller: _taxId
        ),
        Input(
          title: S.of(context).business_branch_series,
          placeholder: S.of(context).business_branch_series_hint,
          controller: _series
        ),
        if (map != null) Padding(
          padding: EdgeInsets.only(top: AppSize.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Separator.horizontal(color: scheme.line),
              SizedBox(height: AppSize.spaceS),
              SizedBox(height: 420, child: map)
            ]
          )
        ),
        _Heading(title: S.of(context).business_branch_section_address),
        if (_company) _CountryField(
          controller: _countryInput,
          onSelected: _countryChanged
        ),
        // Typed anyway; the places the search knows drop under it as a
        // shortcut, like under the map's own box.
        PlaceSearch(
          controller: _address,
          places: _addressPlaces,
          onPicked: _pick,
          child: Input(
            title: S.of(context).business_location_address,
            placeholder: S.of(context).business_location_address_hint,
            controller: _address,
            leftIcon: Icon(CI.store, color: scheme.icon)
          )
        ),
        Input(
          title: S.of(context).business_location_landmark,
          placeholder: S.of(context).business_location_landmark_hint,
          controller: _landmark
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Input(
              title: S.of(context).business_location_city,
              placeholder: S.of(context).business_location_city_hint,
              controller: _city
            )),
            SizedBox(width: AppSize.spaceS),
            Expanded(child: Input(
              title: S.of(context).business_location_region,
              placeholder: S.of(context).business_location_region_hint,
              controller: _region
            ))
          ]
        ),
        Input(
          title: S.of(context).business_location_postal_code,
          placeholder: S.of(context).business_location_postal_code_hint,
          controller: _postalCode,
          onSubmit: _submit
        )
      ]
    );
  }

  /// Another country searches there: both searches start over in it. The
  /// services left behind are freed after the frame, once the dropdowns
  /// listen to the new ones.
  void _countryChanged(SelectOption option) {
    if (option.value == _country) return;

    final left = [_places, _addressPlaces];

    setState(() {
      _country = option.value;
      _places = _placesIn(_country);
      _addressPlaces = _placesIn(_country);
    });

    _search.textController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final places in left) {
        places.dispose();
      }
    });
  }

  /// Writes the picked place into the address fields and the map. The
  /// country is not read: every branch has the company's, and the search only
  /// answers in it. The landmark is not part of a place and is left alone.
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

    // The list goes away with the pick: leaving it open reads as if nothing
    // had happened.
    _search.textController.clear();
    _places.clear();
    _addressPlaces.clear();

    final point = picked.point;

    if (point == null) return;

    final spot = LatLng(point.latitude, point.longitude);

    setState(() => _point = spot);

    // The map may still be loading or showing an error, and a controller with
    // no map under it throws on `move`. The pin is placed anyway.
    try {
      _map.move(spot, DeliveriesMap.businessZoom);
    } catch (_) {}
  }

  /// The phone as it travels: `+`, code and number, or empty.
  String get _phoneValue {
    final number = _phone.value.trim();

    if (number.isEmpty || !_fixedDial) return number;

    return "+$_dial$number";
  }

  Future<void> _submit() async {
    if (!_form.validate()) return;

    final draft = BranchDraft(
      name: _name.value,
      main: _main,
      storefront: _storefront,
      online: _online,
      legalName: _legalName.value,
      taxId: _taxId.value,
      series: _series.value,
      phone: _phoneValue,
      address: _address.value,
      landmark: _landmark.value,
      city: _city.value,
      region: _region.value,
      postalCode: _postalCode.value,
      point: _point
    );

    final from = _from;

    _form.loading.value = true;

    final saved = from == null
      ? await widget.branches.create(context, createBranchRequest(draft))
      : await widget.branches.edit(context, editBranchRequest(from: from, draft: draft));

    if (!mounted) return;

    final done = saved && await _writeCompany();

    if (!mounted) return;

    _form.loading.value = false;

    // A refusal was already shown by the service: the modal stays open with
    // what was written, to correct it. Sent again, the branch's edit is the
    // same one, and only what the company still lacks is written.
    if (done) Navigator.pop(context, true);
  }

  /// The main branch's country and phone, written on the company too (see
  /// [BranchFormModal]), one field at a time and only what differs.
  ///
  /// The phone goes when it was changed here, or when the branch has one the
  /// company lacks: the two were stored apart, and saving a main branch with
  /// no phone must not wipe the company's.
  Future<bool> _writeCompany() async {
    if (!_company) return true;

    final business = context.read<BusinessService>();

    if (_country.isNotEmpty && _country != (business.profile?.country ?? widget.country)) {
      if (!await business.editProfile(context, "COUNTRY", _country)) return false;
      if (!mounted) return false;
    }

    final phone = _phoneValue;

    final write = phone != business.profile?.phone &&
      (phone != (_from?.phone ?? "") || phone.isNotEmpty);

    if (!write) return true;

    return business.editProfile(context, "PHONE", phone);
  }
}

/// The company's country, among the catalog's (watched: it may answer after
/// the form is drawn), with what changing it moves.
class _CountryField extends StatelessWidget {
  const _CountryField({required this.controller, required this.onSelected});

  final InputController controller;
  final void Function(SelectOption option) onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SelectInput(
        title: S.of(context).business_location_country,
        placeholder: S.of(context).business_branch_country_hint,
        controller: controller,
        options: [
          for (final country in context.watch<CountryCatalogService>().countries)
            SelectOption(
              value: country.code,
              placeholder: country.name,
              leading: CountryFlag(country: country)
            )
        ],
        onSelected: onSelected
      ),
      Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS, bottom: AppSize.spaceS),
        child: TextSmall(
          S.of(context).business_branch_country_note,
          lines: 3,
          color: ThemeColor.of(context).text.secondary
        )
      )
    ]
  );
}

/// A group title inside the form, with an optional line under it.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.padding, bottom: AppSize.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Separator.horizontal(color: scheme.line),
          SizedBox(height: AppSize.spaceS),
          TextMedium(title, bold: true),
          if (note != null) ...[
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(note!, lines: 2, color: scheme.text.secondary)
          ]
        ]
      )
    );
  }
}

/// The branch's type as two cards side by side, one per kind, the chosen one
/// outlined. There are only two and each needs its note to be told apart: a
/// dropdown hid both behind a tap.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.storefront, required this.onChanged});

  final bool storefront;
  final void Function(bool storefront) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // The title an `Input` draws, so the cards read as one more field.
      Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap, left: AppSize.spaceXS),
        child: TextMedium(S.of(context).business_branch_kind)
      ),
      // Both cards as tall as the taller note.
      IntrinsicHeight(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _KindCard(
            icon: CI.store,
            title: S.of(context).business_branch_kind_store,
            note: S.of(context).business_branch_kind_store_note,
            selected: storefront,
            onTap: () => onChanged(true)
          )),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: _KindCard(
            icon: CI.shop,
            title: S.of(context).business_branch_kind_warehouse,
            note: S.of(context).business_branch_kind_warehouse_note,
            selected: !storefront,
            onTap: () => onChanged(false)
          ))
        ]
      )),
      SizedBox(height: AppSize.spaceS)
    ]
  );
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.icon,
    required this.title,
    required this.note,
    required this.selected,
    required this.onTap
  });

  final IconData icon;
  final String title;
  final String note;
  final bool selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      // Drawn over the card so the border does not shift its content when
      // the pick changes.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner),
        border: Border.all(
          color: selected ? scheme.primary : scheme.input.border,
          width: selected ? 2 : 1
        )
      ),
      child: FeedbackButton(
        action: onTap,
        padding: EdgeInsets.all(AppSize.spaceS),
        radius: AppSize.corner,
        color: scheme.input.fill,
        feedbackColor: scheme.surfaceFeedback,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(icon, size: AppSize.text * 1.2, color: selected ? scheme.primary : scheme.icon),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextMedium(title, bold: true, ellipsis: true))
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(note, lines: 3, color: scheme.text.secondary)
          ]
        )
      )
    );
  }
}

/// The map to place the branch on, with the address search floating over its
/// top edge; under it, what was placed and how to take it back.
class _PointPicker extends StatelessWidget {
  const _PointPicker({
    required this.search,
    required this.controller,
    required this.opening,
    required this.point,
    required this.onPoint
  });

  final Widget search;
  final MapController controller;
  final LatLng? opening;
  final LatLng? point;
  final void Function(LatLng? point) onPoint;

  /// A little under a button's height: a pin marks a point, and it should not
  /// cover the streets around it.
  static double get _pinHeight => AppSize.action * 0.8;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final picked = point;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextMedium(S.of(context).business_branch_point, bold: true),
        SizedBox(height: AppSize.gap),
        Expanded(child: Stack(children: [
          // The dark tiles are the modal's own color: without an edge the map
          // has no end. Drawn over the tiles so the clip does not cut it.
          Positioned.fill(child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.corner),
              border: Border.all(color: scheme.isDark ? scheme.surfaceFeedback : scheme.line)
            ),
            child: DeliveriesMap(
            controller: controller,
            center: opening,
            onTap: onPoint,
            // The map sits in the modal's scroll (one column) or beside it:
            // the wheel scrolls the form, the buttons zoom.
            zoomButtons: true,
            businessMark: false,
            overlays: [
              if (picked != null) MarkerLayer(markers: [
                Marker(
                  point: picked,
                  // The asset's own proportions (467×533), its tip at the
                  // bottom center: `topCenter` puts that tip on the point.
                  width: _pinHeight * 467 / 533,
                  height: _pinHeight,
                  alignment: Alignment.topCenter,
                  child: ImageDynamic(
                    "l.png",
                    width: _pinHeight * 467 / 533,
                    height: _pinHeight
                  )
                )
              ])
            ]
          ))),
          Positioned(
            top: AppSize.spaceS,
            left: AppSize.spaceS,
            right: AppSize.spaceS,
            child: search
          )
        ])),
        SizedBox(height: AppSize.gap),
        Row(children: [
          Expanded(child: TextSmall(
            picked == null
              ? S.of(context).business_branch_point_help
              : "${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}",
            lines: 2,
            color: scheme.text.secondary
          )),
          if (picked != null) Button(
            width: null,
            title: S.of(context).business_branch_point_clear,
            action: () => onPoint(null)
          )
        ])
      ]
    );
  }
}
