import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_service.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';

import './state/rates_draft.dart';
import './widgets/rates_field.dart';
import './widgets/reach_field.dart';
import './widgets/vehicle_picker.dart';

/// One way the company delivers: who carries the order, what it costs and how
/// long it takes.
///
/// **Who carries it is a closed answer and the carrier is the catalog's.** The
/// mode is picked first —own riders, a delivery app, a parcel carrier— and it
/// narrows the carriers to the ones of that kind available in the company's
/// country. One the catalog lacks is "another one", named by hand; the backend
/// refuses an app or a carrier nobody named.
///
/// **Where it reaches is not asked: every method is local.** A business
/// delivers inside the areas it draws on the desk's map, whoever carries the
/// order, so the form saves `COVERAGE` local and no radius or zones — on an edit
/// it erases the ones an older option kept, which would otherwise reach past
/// the drawn areas (the backend answers a radius before giving up on a point
/// outside them).
///
/// **The company's own delivery says what its couriers ride, how far they go
/// and what each run of days costs.** It is named after the branch it is
/// added from, or the company ([ownName]). How far they go is shaped on the
/// desk's map ([editor], a reach session around [reachFrom]: a circle, a
/// travel time, a road distance or a drawing) and saved with the method, so
/// it has no areas step. Its prices are runs of days beside the hours of the
/// branch picked ([hoursOf]) — one price for every day does not hold "free on
/// weekdays, 5 on weekends" — so its single fee is not asked and is sent
/// empty. **Its time is not asked either**: the backend measures it per order
/// (preparation, the road trip in what they ride, the deliveries already
/// going), since a time promised here held on a quiet day and not on a busy
/// one; an older one is erased.
///
/// It checks here what the backend would refuse, in the same terms (amounts
/// with at most two decimals and no thousands separator, a time up to thirty
/// days), so a mistake is said beside the field and not as an error code
/// after the panel moved on.
///
/// It **hands the request body to [onSubmit] and writes nothing**: the
/// method flow it is a step of owns the writes that go with it (see
/// `MethodFlowPanel`).
class DeliveryOptionForm extends StatefulWidget {
  const DeliveryOptionForm({
    super.key,
    required this.catalog,
    required this.currency,
    required this.onSubmit,
    this.option,
    this.mode,
    this.saving = false,
    this.ownName,
    this.hoursOf,
    this.branchName,
    this.editor,
    this.reachFrom,
    this.reachBranch
  });

  /// What the form picks from. `null` when the catalog could not be read: the
  /// modes are then every one this app knows, and a carrier is named by hand.
  final DeliveryCatalog? catalog;

  /// The company's currency, which every amount is in.
  final String currency;

  /// The option being edited, or `null` when one is being added.
  final DeliveryOption? option;

  /// Who carries a new option, already picked on the step before: the mode
  /// picker is then not drawn. `null` on an edit, which can still change it.
  final DeliveryMode? mode;

  /// The body of the write — `createDeliveryOptionRequest` without an
  /// [option], `updateDeliveryOptionRequest` with one.
  final void Function(Map<String, dynamic> request) onSubmit;

  /// A write is under way: the save button spins and does not answer.
  final bool saving;

  /// The name a new own delivery opens with: the branch it is added from,
  /// else the company.
  final String? ownName;

  /// The branch whose hours stand beside an own delivery's prices, named
  /// [branchName]; `null` shows the days alone.
  final String? hoursOf;
  final String? branchName;

  /// The desk's map, where an own delivery's reach is shaped; `null` asks
  /// none (the reach is then left as it was).
  final AreaEditor? editor;

  /// Where the reach is measured from — the branch [reachBranch], whose
  /// point it is — and the branch saved with it.
  final LatLng? reachFrom;
  final String? reachBranch;

  @override
  State<DeliveryOptionForm> createState() => _DeliveryOptionFormState();
}

class _DeliveryOptionFormState extends State<DeliveryOptionForm> {
  /// The fields that are always drawn.
  ///
  /// What depends on an earlier answer —the carrier— is held apart
  /// ([_providers]): a controller registers in
  /// its form when its input mounts and never leaves it, so a field that was
  /// drawn and then hidden would still be validated with what it was left
  /// holding.
  final _form = FormController();

  /// The carrier that is not in the catalog, named by hand.
  static const String _other = "__other__";

  /// The backend's ceilings (`model:/business/delivery.js`).
  static const double _maxAmount = 9999999999.99;
  static const int _maxEta = 43200;

  DeliveryCatalog get _catalog => widget.catalog ?? const DeliveryCatalog();
  DeliveryOption? get _option => widget.option;
  bool get _isEdit => _option != null;

  /// The picked mode: it decides which carriers are offered and whether one
  /// has to be named.
  late DeliveryMode? _mode = _option?.mode ?? widget.mode;

  /// One carrier picker per mode, created the first time the mode is picked.
  ///
  /// Each mode has its own because their lists differ, and a single picker
  /// whose options changed under it would rewrite its label in the middle of
  /// a build. Switching modes and back finds the carrier that was picked there.
  final Map<DeliveryMode, InputController> _providers = {};

  /// The carrier picked under each mode ([_other] for one named by hand). Held
  /// apart from the controller because a pick changes what the name field
  /// asks for.
  final Map<DeliveryMode, String> _picked = {};

  /// The unit the time opens in: the largest one both figures are whole
  /// numbers of, so `1440–4320` opens as `1–3` days.
  late final DeliveryEtaUnit _unit = DeliveryEtaUnit.fit([
    ?_option?.etaMin,
    ?_option?.etaMax
  ]);

  late final _modeInput = InputController.select(
    key: "MODE",
    form: _form,
    obligatory: true,
    initial: (_option?.mode ?? widget.mode)?.value,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(
        S.of(context).business_delivery_mode
      )
    }
  );

  late final _label = InputController(
    key: "LABEL",
    form: _form,
    max: 64,
    initial: _option?.label ?? (widget.mode == DeliveryMode.own ? widget.ownName : null),
    customErrors: {
      InputError.long: S.of(context).form_long_ma(
        S.of(context).business_delivery_label
      )
    }
  );

  late final _fee = InputController(
    key: "FEE",
    form: _form,
    pattern: "[0-9.,]",
    max: 16,
    initial: _plain(_option?.fee)
  );

  late final _freeFrom = InputController(
    key: "FREE_FROM",
    form: _form,
    pattern: "[0-9.,]",
    max: 16,
    initial: _plain(_option?.freeFrom)
  );

  late final _minimum = InputController(
    key: "MINIMUM",
    form: _form,
    pattern: "[0-9.,]",
    max: 16,
    initial: _plain(_option?.minimum)
  );

  late final _etaMin = InputController(
    key: "ETA_MIN",
    form: _form,
    type: InputType.numeric,
    max: 5,
    initial: _eta(_option?.etaMin)
  );

  late final _etaMax = InputController(
    key: "ETA_MAX",
    form: _form,
    type: InputType.numeric,
    max: 5,
    initial: _eta(_option?.etaMax)
  );

  late final _etaUnit = InputController.select(
    key: "ETA_UNIT",
    form: _form,
    initial: _unit.name
  );

  late final _notes = InputController(
    key: "NOTES",
    form: _form,
    max: 255,
    initial: _option?.notes,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(
        S.of(context).business_delivery_option_notes
      )
    }
  );

  /// What the company's couriers ride (own only).
  late DeliveryVehicle? _vehicle = _option?.vehicle;

  /// Each day's price (own only).
  late final RatesDraft _rates = RatesDraft.of(_option);

  /// The week shown beside the prices.
  late final OpeningHoursService? _hours = widget.hoursOf == null
    ? null
    : OpeningHoursService(branch: widget.hoursOf!);

  /// The reach session this form started on the map, to end it and no other.
  int? _reachSession;

  /// Whether the reach is shaped here: an own delivery with a map to shape it on.
  bool get _shapesReach => _mode == DeliveryMode.own && widget.editor != null && widget.reachFrom != null;

  @override
  void initState() {
    super.initState();

    _hours?.load();
    // The map's listeners rebuild the desk: not in the middle of this build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reach();
    });

    final option = _option;

    // The carrier the option names is the one its picker opens on, and one
    // named only by its label opens on "another one".
    if (option != null && option.mode.namesCarrier) {
      _picked[option.mode] = option.provider.isNotEmpty
        ? option.provider
        : option.label.isNotEmpty ? _other : "";
    }
  }

  /// [DeliveryOptionForm.saving], as the save button listens to it.
  late final _saving = ValueNotifier(widget.saving);

  @override
  void didUpdateWidget(DeliveryOptionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _saving.value = widget.saving;
  }

  @override
  void dispose() {
    for (final controller in _providers.values) {
      controller.dispose();
    }

    final editor = widget.editor;
    final session = _reachSession;

    if (editor != null && session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (editor.reach && editor.session == session) editor.close();
      });
    }

    _rates.dispose();
    _hours?.dispose();
    _saving.dispose();
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final mode = _mode;
    final currency = CurrencyCatalogService().resolve(widget.currency);

    // No bar: it would stand the panel's inset off the edge, and no other
    // list in the panel draws one.
    return ScrollableWidget(
      showBar: false,
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Said and not hidden: a picker that silently lost its carriers looks
        // like one where the company's are not supported.
        if (widget.catalog == null)
          _Notice(text: S.of(context).business_delivery_no_catalog)
        else if (_catalog.country.isEmpty)
          _Notice(text: S.of(context).business_delivery_no_country),
        // A new option's mode is the card picked on the step before.
        if (widget.mode == null) SelectInput(
          title: S.of(context).business_delivery_mode,
          placeholder: S.of(context).business_delivery_mode_placeholder,
          controller: _modeInput,
          options: [
            for (final entry in _modes) SelectOption(
              value: entry.value,
              placeholder: entry.label(context),
              subtitle: entry.description(context),
              icon: entry.icon
            )
          ],
          emptyText: S.of(context).business_delivery_select_empty,
          searchable: false,
          leftIcon: Icon(CI.delivery, color: scheme.icon),
          onSelected: _onMode
        ),
        if (mode != null && mode.namesCarrier) _carrier(context, mode),
        Input(
          title: _nameRequired
            ? S.of(context).business_delivery_label_carrier
            : _optional(context, S.of(context).business_delivery_label),
          placeholder: S.of(context).business_delivery_label_hint,
          controller: _label,
          leftIcon: Icon(CI.bookmark, color: scheme.icon)
        ),
        if (mode == DeliveryMode.own) ...[
          SizedBox(height: AppSize.spaceXS),
          DeliveryVehiclePicker(
            selected: _vehicle,
            onChanged: (vehicle) => setState(() => _vehicle = vehicle)
          ),
          if (_shapesReach && widget.editor!.reach) DeliveryReachField(
            editor: widget.editor!,
            vehicle: _vehicle,
            branch: widget.branchName
          ),
          DeliveryRatesField(
            draft: _rates,
            currency: currency.symbol,
            hours: _hours,
            branch: widget.branchName
          )
        ] else Input(
          title: _optional(context, S.of(context).business_delivery_fee),
          placeholder: S.of(context).business_delivery_fee_hint(currency.symbol),
          controller: _fee,
          leftIcon: Icon(CI.wallet, color: scheme.icon)
        ),
        Input(
          title: _optional(context, S.of(context).business_delivery_free_from_title),
          placeholder: S.of(context).business_delivery_free_from_hint,
          controller: _freeFrom,
          leftIcon: Icon(CI.gift, color: scheme.icon)
        ),
        if (mode == DeliveryMode.own) Input(
          title: _optional(context, S.of(context).deliveries_area_minimum),
          placeholder: S.of(context).business_delivery_minimum_hint,
          controller: _minimum,
          leftIcon: Icon(CI.cart_shopping, color: scheme.icon)
        ),
        if (mode == DeliveryMode.own) const _Arrival() else ...[
        InputRow(
          title: _optional(context, S.of(context).business_delivery_eta),
          spacing: AppSize.gap,
          children: [
            Input(
              flex: 2,
              placeholder: S.of(context).business_delivery_eta_min,
              controller: _etaMin
            ),
            Input(
              flex: 2,
              placeholder: S.of(context).business_delivery_eta_max,
              controller: _etaMax
            ),
            SelectInput(
              flex: 3,
              placeholder: S.of(context).business_delivery_eta_unit,
              controller: _etaUnit,
              options: [
                for (final unit in DeliveryEtaUnit.values) SelectOption(
                  value: unit.name,
                  placeholder: unit.label(context)
                )
              ],
              emptyText: S.of(context).business_delivery_select_empty,
              searchable: false
            )
          ]
        ),
        // Said under the figures because "delivery time" alone was read both
        // ways: until the courier leaves, or until the customer has it.
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceXS),
          child: TextSmall(
            S.of(context).business_delivery_eta_note,
            lines: 3,
            color: scheme.text.secondary
          )
        )
        ],
        Input(
          title: _optional(context, S.of(context).business_delivery_option_notes),
          placeholder: S.of(context).business_delivery_option_notes_hint,
          controller: _notes,
          leftIcon: Icon(CI.edit, color: scheme.icon),
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(title: S.of(context).save, action: _submit, loading: _saving)
      ]
    );
  }

  /// The carrier picker of [mode]: the catalog's carriers of that kind, the
  /// one the option already names if the catalog no longer offers it, and
  /// "another one".
  Widget _carrier(BuildContext context, DeliveryMode mode) {
    final option = _option;

    return KeyedSubtree(
      // One element per mode, so each keeps its own list (see [_providers]).
      key: ValueKey(mode),
      child: SelectInput(
        title: S.of(context).business_delivery_provider,
        placeholder: S.of(context).business_delivery_provider_placeholder,
        controller: _provider(mode),
        options: [
          for (final provider in _catalog.of(mode)) SelectOption(
            value: provider.code,
            placeholder: provider.name,
            subtitle: provider.global
              ? S.of(context).business_delivery_provider_global
              : null,
            leading: provider.icon.isEmpty
              ? null
              : _ProviderMark(icon: provider.icon)
          ),
          // The company moved, or the carrier left its country: it is kept as
          // one more option so the form shows what the option has. The backend
          // takes it back because it is only resent when it changes.
          if (option != null &&
              option.mode == mode &&
              option.provider.isNotEmpty &&
              _catalog.byCode(option.provider) == null)
            SelectOption(value: option.provider, placeholder: option.carrier),
          SelectOption(
            value: _other,
            placeholder: S.of(context).business_delivery_provider_other,
            subtitle: S.of(context).business_delivery_provider_other_note
          )
        ],
        emptyText: S.of(context).business_delivery_select_empty,
        leftIcon: Icon(mode.icon, color: ThemeColor.of(context).icon),
        onSelected: (picked) => setState(() => _picked[mode] = picked.value)
      )
    );
  }

  InputController _provider(DeliveryMode mode) => _providers[mode] ??=
    InputController.select(
      key: "PROVIDER_${mode.value}",
      initial: (_picked[mode] ?? "").isEmpty ? null : _picked[mode]
    );

  /// The modes to offer: the catalog's, plus the option's own if the catalog
  /// no longer lists it — a picker that cannot show the saved value would
  /// open empty on an edit.
  List<DeliveryMode> get _modes => [
    ..._catalog.modes,
    if (_option != null && !_catalog.modes.contains(_option!.mode)) _option!.mode
  ];

  /// Whether the name is what says who carries it: an app or a carrier the
  /// catalog does not list —or with no catalog to pick from— is named by hand.
  bool get _nameRequired {
    final mode = _mode;

    if (mode == null || !mode.namesCarrier) return false;

    final picked = _picked[mode] ?? "";

    return picked.isEmpty ? _catalog.of(mode).isEmpty : picked == _other;
  }

  void _onMode(SelectOption option) {
    final mode = DeliveryMode.from(option.value);

    if (mode == null || mode == _mode) return;

    setState(() => _mode = mode);
    _reach();
  }

  /// Starts shaping the reach on the map for an own delivery, or ends the one
  /// this form started for another kind.
  void _reach() {
    final editor = widget.editor;
    final from = widget.reachFrom;

    if (editor == null) return;

    if (_shapesReach && from != null) {
      if (editor.reach && editor.session == _reachSession) return;

      editor.startReach(from, from: _option?.reach, mode: _vehicle?.travel);
      _reachSession = editor.session;
    } else if (editor.reach && editor.session == _reachSession) {
      editor.close();
      _reachSession = null;
    }

    if (mounted) setState(() {});
  }

  /// Reads the form and hands over the body.
  void _submit() {
    if (widget.saving || !_form.validate()) return;

    final mode = _mode;

    if (mode == null) return;

    final picked = mode.namesCarrier ? _picked[mode] ?? "" : "";
    final provider = picked == _other ? "" : picked;
    final label = _label.value.trim();

    if (mode.namesCarrier && provider.isEmpty && label.isEmpty) {
      _fail(S.of(context).business_delivery_carrier_required);
      return;
    }

    final own = mode == DeliveryMode.own;
    // Own: the rates say every day's price, so no single fee goes with them.
    final fee = own ? (valid: true, value: null) : readDeliveryAmount(_fee.value);
    final freeFrom = readDeliveryAmount(_freeFrom.value);
    // Own only: an app or a carrier takes the orders it takes.
    final minimum = own ? readDeliveryAmount(_minimum.value) : (valid: true, value: null);

    if (!fee.valid ||
        !freeFrom.valid ||
        !minimum.valid ||
        (fee.value ?? 0) > _maxAmount ||
        (freeFrom.value ?? 0) > _maxAmount ||
        (minimum.value ?? 0) > _maxAmount) {
      _fail(S.of(context).business_delivery_amount_invalid);
      return;
    }

    final rates = own ? _rates.read(max: _maxAmount) : null;

    if (rates != null && rates.missing != null) {
      final missing = rates.missing!;

      _fail(rates.invalid
        ? S.of(context).business_delivery_amount_invalid
        : S.of(context).business_delivery_rate_missing(DeliveryRatesField.name(context, missing)));
      return;
    }

    final reach = _shapesReach
      ? DeliveryReachField.read(widget.editor!, branch: widget.reachBranch)
      : _option?.reach;

    if (_shapesReach && reach == null) {
      final editor = widget.editor!;

      _fail(editor.method.routed && editor.points.isEmpty
        ? S.of(context).business_delivery_reach_unmeasured
        : S.of(context).business_delivery_reach_missing);
      return;
    }

    final unit = DeliveryEtaUnit.values.firstWhere(
      (entry) => entry.name == _etaUnit.value,
      orElse: () => DeliveryEtaUnit.minutes
    );
    // Own: measured per order, so none is kept (an older one is erased).
    final etaMin = own ? null : _minutes(_etaMin.value, unit);
    final etaMax = own ? null : _minutes(_etaMax.value, unit);

    if (!_inRange(etaMin) ||
        !_inRange(etaMax) ||
        (etaMin != null && etaMax != null && etaMin > etaMax)) {
      _fail(S.of(context).business_delivery_eta_invalid);
      return;
    }

    widget.onSubmit(_isEdit
      ? updateDeliveryOptionRequest(
          from: _option!,
          mode: mode,
          provider: provider,
          label: label,
          coverage: DeliveryCoverage.local,
          fee: fee.value,
          freeFrom: freeFrom.value,
          etaMin: etaMin,
          etaMax: etaMax,
          notes: _notes.value,
          vehicle: own ? _vehicle : null,
          rates: rates?.rates,
          reach: own ? reach : null,
          minimum: minimum.value
        )
      : createDeliveryOptionRequest(
          mode: mode,
          provider: provider,
          label: label,
          coverage: DeliveryCoverage.local,
          fee: fee.value,
          freeFrom: freeFrom.value,
          etaMin: etaMin,
          etaMax: etaMax,
          notes: _notes.value,
          vehicle: own ? _vehicle : null,
          rates: rates?.rates,
          reach: own ? reach : null,
          minimum: minimum.value
        ));
  }

  void _fail(String message) => FloatFlag.of(context).error(message: message);

  /// A typed time in minutes, which is how it is stored.
  int? _minutes(String raw, DeliveryEtaUnit unit) {
    final value = int.tryParse(raw.trim());

    return value == null ? null : value * unit.factor;
  }

  bool _inRange(int? minutes) =>
    minutes == null || (minutes >= 1 && minutes <= _maxEta);

  /// A stored time in the unit the form opens in.
  String _eta(int? minutes) =>
    minutes == null ? "" : "${minutes ~/ _unit.factor}";

  /// A field's title with the word that says it can be left empty. Almost
  /// every field here can, so the ones that cannot are the plain ones.
  String _optional(BuildContext context, String label) =>
    "$label · ${S.of(context).business_delivery_optional}";

  /// A stored number as the form opens it: `5`, `2.5`, never `5.00`.
  static String _plain(double? value) => value == null
    ? ""
    : value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "");
}

/// A carrier's mark, the size of a list row. A platform file: without a base
/// or when it cannot be downloaded the slot stays empty, and the carrier is
/// still read by its name.
class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final size = AppSize.text * 1.4;
    final url = CdnService().url(FileScope.assets, icon, width: (size * 2).round());

    return SizedBox(
      width: size,
      height: size,
      child: url.isEmpty ? null : ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.gap / 2),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const SizedBox.shrink()
        )
      )
    );
  }
}

/// Where an own delivery's time would be asked: that it is calculated per
/// order, and from what.
class _Arrival extends StatelessWidget {
  const _Arrival();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.25),
            child: Icon(Icons.schedule_rounded, size: AppSize.text * 1.1, color: scheme.icon)
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextSmall(S.of(context).business_delivery_arrival, bold: true),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(S.of(context).business_delivery_arrival_note, lines: 4, color: scheme.text.secondary)
            ]
          ))
        ]
      )
    );
  }
}

/// A notice at the top of the form about what it could not offer.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Row(children: [
          Icon(CI.info, size: AppSize.text, color: scheme.snackBar.error),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            text,
            lines: 3,
            color: scheme.text.secondary
          ))
        ])
      )
    );
  }
}
