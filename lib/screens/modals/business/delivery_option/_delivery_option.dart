import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

import 'zone_rows.dart';

/// Opens the panel that adds a way of delivering, or edits [option].
///
/// Returns the body of the write —`createDeliveryOptionRequest` without an
/// [option], `updateDeliveryOptionRequest` with one— or `null` when it was
/// closed without saving.
Future<Map<String, dynamic>?> showDeliveryOptionForm(
  BuildContext context, {
  required DeliveryCatalog? catalog,
  required String currency,
  DeliveryOption? option
}) => showSideModal(
  context: context,
  title: option == null
    ? S.of(context).business_delivery_create_title
    : S.of(context).business_delivery_edit_title,
  builder: (context) => DeliveryOptionFormModal(
    catalog: catalog,
    currency: currency,
    option: option
  )
).then((value) => value is Map<String, dynamic> ? value : null);

/// One way the company delivers: who carries the order, how far it reaches,
/// what it costs and how long it takes.
///
/// **Who carries it is a closed answer and the carrier is the catalog's.** The
/// mode is picked first —own riders, a delivery app, a parcel carrier— and it
/// narrows the carriers to the ones of that kind available in the company's
/// country. One the catalog lacks is "another one", named by hand; the backend
/// refuses an app or a carrier nobody named.
///
/// **Where it reaches decides what else is asked.** A local option narrows
/// itself with a radius and with zones —in the company's own words, each with
/// a price of its own if it differs—; a national or international one keeps
/// neither, and the form stops asking for them.
///
/// It checks here what the backend would refuse, in the same terms (amounts
/// with at most two decimals and no thousands separator, kilometres up to a
/// thousand, a time up to thirty days), so a mistake is said beside the field
/// and not as an error code after the panel closed.
///
/// It **returns the request body and writes nothing**: the delivery service is
/// provided by the business page, under the navigator this panel is opened on.
class DeliveryOptionFormModal extends StatefulWidget {
  const DeliveryOptionFormModal({
    super.key,
    required this.catalog,
    required this.currency,
    this.option
  });

  /// What the form picks from. `null` when the catalog could not be read: the
  /// modes and reaches are then every one this app knows, and a carrier is
  /// named by hand.
  final DeliveryCatalog? catalog;

  /// The company's currency, which every amount is in.
  final String currency;

  /// The option being edited, or `null` when one is being added.
  final DeliveryOption? option;

  @override
  State<DeliveryOptionFormModal> createState() => _DeliveryOptionFormModalState();
}

class _DeliveryOptionFormModalState extends State<DeliveryOptionFormModal> {
  /// The fields that are always drawn.
  ///
  /// What depends on an earlier answer —the carrier, the radius, the zones— is
  /// held apart ([_providers], [_radius], [_zones]): a controller registers in
  /// its form when its input mounts and never leaves it, so a field that was
  /// drawn and then hidden would still be validated with what it was left
  /// holding.
  final _form = FormController();

  /// The carrier that is not in the catalog, named by hand.
  static const String _other = "__other__";

  /// The backend's ceilings (`model:/business/delivery.js`).
  static const double _maxAmount = 9999999999.99;
  static const double _maxRadius = 1000;
  static const int _maxEta = 43200;
  static const int _maxZoneName = 80;

  DeliveryCatalog get _catalog => widget.catalog ?? const DeliveryCatalog();
  DeliveryOption? get _option => widget.option;
  bool get _isEdit => _option != null;

  /// The picked mode: it decides which carriers are offered and whether one
  /// has to be named.
  late DeliveryMode? _mode = _option?.mode;

  /// The picked reach, or `null` on a creation that did not pick one — which
  /// is the mode's own ([DeliveryMode.reach]), as the backend defaults it.
  late DeliveryCoverage? _coverage = _option?.coverage;

  DeliveryCoverage? get _reach => _coverage ?? _mode?.reach;

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

  late final List<ZoneDraft> _zones = [
    for (final zone in _option?.zones ?? const <DeliveryZone>[])
      ZoneDraft(initialName: zone.name, initialFee: _plain(zone.fee))
  ];

  late final _radius = InputController(
    key: "RADIUS",
    initial: _plain(_option?.radius),
    pattern: "[0-9.,]",
    max: 10
  );

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
    initial: _option?.mode.value,
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
    initial: _option?.label,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(
        S.of(context).business_delivery_label
      )
    }
  );

  late final _coverageInput = InputController.select(
    key: "COVERAGE",
    form: _form,
    initial: _option?.coverage.value
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

  @override
  void initState() {
    super.initState();

    final option = _option;

    // The carrier the option names is the one its picker opens on, and one
    // named only by its label opens on "another one".
    if (option != null && option.mode.namesCarrier) {
      _picked[option.mode] = option.provider.isNotEmpty
        ? option.provider
        : option.label.isNotEmpty ? _other : "";
    }
  }

  @override
  void dispose() {
    for (final controller in _providers.values) {
      controller.dispose();
    }

    for (final zone in _zones) {
      zone.dispose();
    }

    _radius.dispose();
    _form.dispose();
    super.dispose();
  }

  /// Same width as the rest of the panels of this app.
  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final mode = _mode;
    final currency = CurrencyCatalogService().resolve(widget.currency);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).business_delivery_form_subtitle,
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          // Said and not hidden: a picker that silently lost its carriers looks
          // like one where the company's are not supported.
          if (widget.catalog == null)
            _Notice(text: S.of(context).business_delivery_no_catalog)
          else if (_catalog.country.isEmpty)
            _Notice(text: S.of(context).business_delivery_no_country),
          SelectInput(
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
          SelectInput(
            title: S.of(context).business_delivery_coverage,
            // What a creation that picks nothing gets is written where the
            // answer goes, so leaving it empty is a choice and not a gap.
            placeholder: mode == null
              ? S.of(context).business_delivery_coverage_placeholder
              : S.of(context).business_delivery_coverage_default(
                  mode.reach.label(context)
                ),
            controller: _coverageInput,
            options: [
              for (final entry in _coverages) SelectOption(
                value: entry.value,
                placeholder: entry.label(context),
                subtitle: entry.description(context)
              )
            ],
            emptyText: S.of(context).business_delivery_select_empty,
            searchable: false,
            leftIcon: Icon(CI.globe_shopping, color: scheme.icon),
            onSelected: (option) => setState(
              () => _coverage = DeliveryCoverage.from(option.value)
            )
          ),
          if (_reach == DeliveryCoverage.local) ...[
            Input(
              title: _optional(context, S.of(context).business_delivery_radius_title),
              placeholder: S.of(context).business_delivery_radius_hint,
              controller: _radius,
              leftIcon: Icon(CI.globe_shopping, color: scheme.icon)
            ),
            ZoneRows(
              title: _optional(context, S.of(context).business_delivery_zones),
              zones: _zones,
              onAdd: _addZone,
              onRemove: _removeZone
            )
          ],
          Input(
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
          Input(
            title: _optional(context, S.of(context).business_delivery_option_notes),
            placeholder: S.of(context).business_delivery_option_notes_hint,
            controller: _notes,
            leftIcon: Icon(CI.edit, color: scheme.icon),
            onSubmit: _submit
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).save, action: _submit)
        ]
      )
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

  List<DeliveryCoverage> get _coverages => [
    ..._catalog.coverages,
    if (_option != null && !_catalog.coverages.contains(_option!.coverage))
      _option!.coverage
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
  }

  void _addZone() => setState(() => _zones.add(ZoneDraft()));

  /// A zone's inputs are still mounted while this runs, so its controllers
  /// are let go of after the frame that removes them.
  void _removeZone(ZoneDraft zone) {
    setState(() => _zones.remove(zone));

    WidgetsBinding.instance.addPostFrameCallback((_) => zone.dispose());
  }

  /// Reads the form and closes with the body.
  void _submit() {
    if (!_form.validate()) return;

    final mode = DeliveryMode.from(_modeInput.value);

    if (mode == null) return;

    final picked = mode.namesCarrier ? _picked[mode] ?? "" : "";
    final provider = picked == _other ? "" : picked;
    final label = _label.value.trim();

    if (mode.namesCarrier && provider.isEmpty && label.isEmpty) {
      _fail(S.of(context).business_delivery_carrier_required);
      return;
    }

    final coverage = DeliveryCoverage.from(_coverageInput.value);
    final local = (coverage ?? mode.reach) == DeliveryCoverage.local;

    double? radius;
    final zones = <DeliveryZone>[];

    if (local) {
      final read = readDeliveryAmount(_radius.value);
      final value = read.value;

      if (!read.valid || (value != null && (value < 0.01 || value > _maxRadius))) {
        _fail(S.of(context).business_delivery_radius_invalid);
        return;
      }

      radius = value;

      for (final draft in _zones) {
        final name = draft.name.value.replaceAll(RegExp(r"\s+"), " ").trim();
        final fee = readDeliveryAmount(draft.fee.value);

        // A row left blank is not a zone: it is the one somebody added and
        // did not use.
        if (name.isEmpty && draft.fee.value.trim().isEmpty) continue;

        if (name.isEmpty ||
            name.length > _maxZoneName ||
            !fee.valid ||
            (fee.value ?? 0) > _maxAmount) {
          _fail(S.of(context).business_delivery_zone_invalid);
          return;
        }

        zones.add(DeliveryZone(name: name, fee: fee.value));
      }
    }

    final fee = readDeliveryAmount(_fee.value);
    final freeFrom = readDeliveryAmount(_freeFrom.value);

    if (!fee.valid ||
        !freeFrom.valid ||
        (fee.value ?? 0) > _maxAmount ||
        (freeFrom.value ?? 0) > _maxAmount) {
      _fail(S.of(context).business_delivery_amount_invalid);
      return;
    }

    final unit = DeliveryEtaUnit.values.firstWhere(
      (entry) => entry.name == _etaUnit.value,
      orElse: () => DeliveryEtaUnit.minutes
    );
    final etaMin = _minutes(_etaMin.value, unit);
    final etaMax = _minutes(_etaMax.value, unit);

    if (!_inRange(etaMin) ||
        !_inRange(etaMax) ||
        (etaMin != null && etaMax != null && etaMin > etaMax)) {
      _fail(S.of(context).business_delivery_eta_invalid);
      return;
    }

    Navigator.pop(context, _isEdit
      ? updateDeliveryOptionRequest(
          from: _option!,
          mode: mode,
          provider: provider,
          label: label,
          coverage: coverage,
          radius: radius,
          zones: zones,
          fee: fee.value,
          freeFrom: freeFrom.value,
          etaMin: etaMin,
          etaMax: etaMax,
          notes: _notes.value
        )
      : createDeliveryOptionRequest(
          mode: mode,
          provider: provider,
          label: label,
          coverage: coverage,
          radius: radius,
          zones: zones,
          fee: fee.value,
          freeFrom: freeFrom.value,
          etaMin: etaMin,
          etaMax: etaMax,
          notes: _notes.value
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
