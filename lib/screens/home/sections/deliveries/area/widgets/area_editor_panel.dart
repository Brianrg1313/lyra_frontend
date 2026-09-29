import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/settings/delivery_format.dart';

import '../state/area_editor.dart';

/// Left panel while an area is shaped: how it is being made, the tools of
/// that way, and what the area is called and costs.
///
/// The shape is the map's and lives in the [AreaEditor]; this panel holds the
/// words and figures, and builds the request when it saves. It is keyed by
/// the editor's session, so starting another area starts its inputs again.
class AreaEditorPanel extends StatefulWidget {
  const AreaEditorPanel({
    super.key,
    required this.editor,
    required this.currency,
    required this.count
  });

  final AreaEditor editor;

  /// The company's currency, which every amount is in.
  final String currency;

  /// How many areas there are, to name a new one ("Area 3").
  final int count;

  @override
  State<AreaEditorPanel> createState() => _AreaEditorPanelState();
}

class _AreaEditorPanelState extends State<AreaEditorPanel> {
  final _form = FormController();

  AreaEditor get _editor => widget.editor;
  DeliveryArea? get _area => _editor.editing;

  /// The backend's ceilings.
  static const double _maxAmount = 9999999999.99;
  static const int _maxName = 64;

  late final _name = InputController(
    key: "NAME",
    form: _form,
    obligatory: true,
    max: _maxName,
    initial: _area?.name ?? S.of(context).deliveries_area_default_name(widget.count + 1),
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).deliveries_area_name),
      InputError.long: S.of(context).form_long_ma(S.of(context).deliveries_area_name)
    }
  );

  late final _fee = InputController(
    key: "FEE",
    form: _form,
    pattern: "[0-9.,]",
    max: 16,
    initial: _plain(_area?.fee)
  );

  late final _minimum = InputController(
    key: "MINIMUM",
    form: _form,
    pattern: "[0-9.,]",
    max: 16,
    initial: _plain(_area?.minimum)
  );

  /// Out of [_form]: it is the map's figure, read as it is typed.
  late final _radius = InputController(
    key: "RADIUS",
    pattern: "[0-9.,]",
    max: 6,
    initial: deliveryNumber(_editor.radius)
  );

  late final _minutes = InputController(
    key: "MINUTES",
    type: InputType.numeric,
    max: 3,
    initial: "${_editor.minutes}"
  );

  late final _mode = InputController.select(
    key: "MODE",
    initial: _editor.mode.value
  );

  /// While the routing engine is being asked for the travel-time outline.
  final _computing = ValueNotifier<bool>(false);

  final _saving = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    _radius.textController.addListener(_onRadius);
  }

  @override
  void dispose() {
    _radius.textController.removeListener(_onRadius);
    _radius.dispose();
    _minutes.dispose();
    _mode.dispose();
    _computing.dispose();
    _saving.dispose();
    _form.dispose();
    super.dispose();
  }

  /// The circle follows the figure while it is typed; a figure that is not
  /// one yet (`3.`) leaves it where it was.
  void _onRadius() {
    final read = readDeliveryAmount(_radius.textController.text);
    final value = read.value;

    if (read.valid && value != null && value > 0) _editor.setRadius(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final currency = CurrencyCatalogService().resolve(widget.currency);
    final method = _editor.method;

    return ScrollableWidget(
      showBar: false,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(_methodIcon(method), size: AppSize.text * 1.2, color: scheme.primary),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextMedium(
            _area == null
              ? S.of(context).deliveries_area_new_title
              : S.of(context).deliveries_area_edit_title,
            bold: true,
            ellipsis: true
          ))
        ]),
        SizedBox(height: AppSize.gap),
        TextSmall(_hint(context), lines: 4, color: scheme.text.secondary),
        SizedBox(height: AppSize.spaceS),
        ...switch (method) {
          AreaMethod.radius => _radiusTools(context),
          AreaMethod.draw => _drawTools(context),
          AreaMethod.travel => [
            ..._travelTools(context),
            if (_editor.points.isNotEmpty) ...[
              SizedBox(height: AppSize.spaceS),
              ..._drawTools(context)
            ]
          ]
        },
        SizedBox(height: AppSize.spaceS),
        Input(
          title: S.of(context).deliveries_area_name,
          placeholder: S.of(context).deliveries_area_name_hint,
          controller: _name,
          leftIcon: Icon(CI.bookmark, color: scheme.icon)
        ),
        Input(
          title: "${S.of(context).deliveries_area_fee} · ${S.of(context).business_delivery_optional}",
          placeholder: S.of(context).deliveries_area_fee_hint(currency.symbol),
          controller: _fee,
          leftIcon: Icon(CI.wallet, color: scheme.icon)
        ),
        Input(
          title: "${S.of(context).deliveries_area_minimum} · ${S.of(context).business_delivery_optional}",
          placeholder: S.of(context).deliveries_area_minimum_hint,
          controller: _minimum,
          leftIcon: Icon(CI.cart_shopping, color: scheme.icon),
          onSubmit: _save
        ),
        SizedBox(height: AppSize.spaceM),
        MainButton(
          title: S.of(context).save,
          loading: _saving,
          action: _save
        ),
        SizedBox(height: AppSize.gap),
        Button(title: S.of(context).cancel, action: _editor.close)
      ]
    );
  }

  List<Widget> _radiusTools(BuildContext context) => [
    Input(
      title: S.of(context).business_delivery_radius_title,
      placeholder: S.of(context).business_delivery_radius_hint,
      controller: _radius,
      leftIcon: Icon(CI.globe_shopping, color: ThemeColor.of(context).icon)
    ),
    Wrap(
      spacing: AppSize.gap,
      runSpacing: AppSize.gap,
      children: [
        for (final km in const [1.0, 2.0, 3.0, 5.0, 10.0, 20.0]) _Chip(
          label: S.of(context).deliveries_area_km(deliveryNumber(km)),
          chosen: _editor.radius == km,
          action: () => _radius.textController.text = deliveryNumber(km)
        )
      ]
    )
  ];

  List<Widget> _drawTools(BuildContext context) {
    final points = _editor.points;

    return [
      TextSmall(
        S.of(context).deliveries_area_points(points.length),
        color: points.length < 3
          ? ThemeColor.of(context).snackBar.error
          : ThemeColor.of(context).text.secondary
      ),
      SizedBox(height: AppSize.gap),
      Wrap(
        spacing: AppSize.gap,
        runSpacing: AppSize.gap,
        children: [
          _Chip(
            icon: CI.arrow_left,
            label: S.of(context).deliveries_area_undo,
            action: _editor.canUndo ? _editor.undo : null
          ),
          _Chip(
            icon: CI.delete,
            label: S.of(context).deliveries_area_remove_point,
            action: _editor.selected == null ? null : _editor.removeSelected
          ),
          _Chip(
            icon: CI.trash,
            label: S.of(context).deliveries_area_clear,
            action: points.isEmpty ? null : _editor.clearPoints
          )
        ]
      )
    ];
  }

  List<Widget> _travelTools(BuildContext context) => [
    InputRow(
      title: S.of(context).deliveries_area_travel,
      spacing: AppSize.gap,
      children: [
        SelectInput(
          flex: 3,
          placeholder: S.of(context).deliveries_area_travel_mode,
          controller: _mode,
          options: [
            for (final mode in DeliveryTravelMode.values) SelectOption(
              value: mode.value,
              placeholder: mode.label(context),
              icon: mode.icon
            )
          ],
          emptyText: S.of(context).business_delivery_select_empty,
          searchable: false,
          onSelected: (option) => _editor.setMode(DeliveryTravelMode.values.firstWhere(
            (mode) => mode.value == option.value,
            orElse: () => DeliveryTravelMode.motorcycle
          ))
        ),
        Input(
          flex: 2,
          placeholder: S.of(context).deliveries_area_travel_minutes,
          controller: _minutes,
          onSubmit: _travel
        )
      ]
    ),
    Button(
      title: _editor.points.isEmpty
        ? S.of(context).deliveries_area_travel_compute
        : S.of(context).deliveries_area_travel_again,
      leftIcon: Icon(CI.globe_shopping, color: ThemeColor.of(context).icon),
      loading: _computing,
      action: _travel
    )
  ];

  /// Asks the routing engine how far a courier gets, and takes it as the shape.
  Future<void> _travel() async {
    final minutes = int.tryParse(_minutes.value.trim());
    final center = _editor.center;

    if (minutes == null || minutes < 1 || minutes > 120) {
      _fail(S.of(context).deliveries_area_travel_invalid);
      return;
    }

    if (center == null || _computing.value) return;

    _editor.setMinutes(minutes);
    _computing.value = true;

    final outline = await context.read<DeliveryAreasService>().travelShape(
      center,
      minutes,
      _editor.mode
    );

    if (!mounted) return;

    _computing.value = false;

    if (outline == null || outline.length < 3) {
      _fail(S.of(context).deliveries_area_travel_failed);
      return;
    }

    _editor.useOutline(outline);
  }

  Future<void> _save() async {
    if (_saving.value || !_form.validate()) return;

    if (!_editor.hasShape) {
      _fail(_editor.method == AreaMethod.radius
        ? S.of(context).business_delivery_radius_invalid
        : S.of(context).deliveries_area_shape_missing);
      return;
    }

    final fee = readDeliveryAmount(_fee.value);
    final minimum = readDeliveryAmount(_minimum.value);

    if (!fee.valid ||
        !minimum.valid ||
        (fee.value ?? 0) > _maxAmount ||
        (minimum.value ?? 0) > _maxAmount) {
      _fail(S.of(context).business_delivery_amount_invalid);
      return;
    }

    final kind = _editor.method.kind;
    final name = _name.value.replaceAll(RegExp(r"\s+"), " ").trim();
    final area = _area;
    final request = area == null
      ? createDeliveryAreaRequest(
          name: name,
          kind: kind,
          center: _editor.center,
          radius: _editor.radius,
          points: _editor.points,
          fee: fee.value,
          minimum: minimum.value
        )
      : updateDeliveryAreaRequest(
          from: area,
          name: name,
          kind: kind,
          center: _editor.center,
          radius: _editor.radius,
          points: _editor.points,
          fee: fee.value,
          minimum: minimum.value
        );

    final service = context.read<DeliveryAreasService>();

    _saving.value = true;

    final saved = area == null
      ? await service.create(context, request)
      : await service.update(context, request);

    if (!mounted) return;

    _saving.value = false;

    if (saved) _editor.close();
  }

  String _hint(BuildContext context) => switch (_editor.method) {
    AreaMethod.radius => S.of(context).deliveries_area_radius_note,
    AreaMethod.draw => S.of(context).deliveries_area_draw_note,
    AreaMethod.travel => _editor.points.isEmpty
      ? S.of(context).deliveries_area_travel_note
      : S.of(context).deliveries_area_draw_note
  };

  void _fail(String message) => FloatFlag.of(context).error(message: message);

  /// A stored number as the form opens it: `5`, `2.5`, never `5.00`.
  static String _plain(double? value) => value == null ? "" : deliveryNumber(value);
}

IconData _methodIcon(AreaMethod method) => switch (method) {
  AreaMethod.radius => CI.circle,
  AreaMethod.draw => CI.pen,
  AreaMethod.travel => CI.delivery
};

/// A small action of the tools, faded while there is nothing for it to do.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.action,
    this.icon,
    this.chosen = false
  });

  final String label;
  final void Function()? action;
  final IconData? icon;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = action == null
      ? scheme.text.secondary.withValues(alpha: 0.5)
      : chosen ? scheme.primary : scheme.text.primary;

    return FeedbackButton(
      action: action ?? () {},
      height: AppSize.button * 0.8,
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      color: chosen ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSize.text * 0.9, color: color),
            SizedBox(width: AppSize.gap * 0.5)
          ],
          TextSmall(label, color: color)
        ]
      )
    );
  }
}
