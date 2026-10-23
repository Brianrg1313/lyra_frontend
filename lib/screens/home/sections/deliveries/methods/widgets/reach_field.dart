import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_areas_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_tool_chip.dart';
import 'package:app/screens/home/sections/deliveries/delivery_format.dart';

import './form_section.dart';

/// **How far the company's own couriers go**, said one of four ways and
/// shaped on the map beside the panel: a circle around the branch, how far
/// they get in some minutes, how far some kilometres of road take them —
/// 15 km of roads is not 15 km around — or a shape drawn by hand.
///
/// The shape lives in the desk's [AreaEditor], in a reach session
/// (`AreaEditor.startReach`, started by the form): the map draws and edits it
/// as it does an area. Travel time and road distance are asked of the routing
/// engine in what the couriers ride ([vehicle]), and the outline it answers is
/// what is saved, then edited by hand like a drawing.
class DeliveryReachField extends StatefulWidget {
  const DeliveryReachField({super.key, required this.editor, this.vehicle, this.branch});

  final AreaEditor editor;

  /// What the couriers ride, which a time or a road distance is measured in;
  /// a motorcycle when it was not said.
  final DeliveryVehicle? vehicle;

  /// The branch it is measured from, named in the notes.
  final String? branch;

  /// The reach as the map holds it, measured from [branch]; `null` when it
  /// is not a shape yet (a time or a distance not measured, a drawing short
  /// of three points).
  static DeliveryReach? read(AreaEditor editor, {String? branch}) {
    if (!editor.reach || !editor.hasShape) return null;

    final method = editor.method;

    return DeliveryReach(
      kind: method.reach,
      value: switch (method) {
        AreaMethod.radius => editor.radius,
        AreaMethod.travel => editor.minutes.toDouble(),
        AreaMethod.road => editor.km,
        AreaMethod.draw => null
      },
      branch: branch,
      points: method == AreaMethod.radius ? const [] : editor.points
    );
  }

  @override
  State<DeliveryReachField> createState() => _DeliveryReachFieldState();
}

class _DeliveryReachFieldState extends State<DeliveryReachField> {
  AreaEditor get _editor => widget.editor;

  DeliveryTravelMode get _mode => widget.vehicle?.travel ?? DeliveryTravelMode.motorcycle;

  /// The map's figures, read as they are typed and never validated as a
  /// form. They still need one of their own: a controller with none is
  /// disposed by its `Input` on unmount, and each figure's field comes and
  /// goes with the way picked.
  final _figures = FormController();

  late final _radius = InputController(
    key: "REACH_RADIUS",
    form: _figures,
    pattern: "[0-9.,]",
    max: 6,
    initial: deliveryNumber(_editor.radius)
  );

  late final _minutes = InputController(
    key: "REACH_MINUTES",
    form: _figures,
    type: InputType.numeric,
    max: 3,
    initial: "${_editor.minutes}"
  );

  late final _km = InputController(
    key: "REACH_KM",
    form: _figures,
    pattern: "[0-9.,]",
    max: 5,
    initial: deliveryNumber(_editor.km)
  );

  /// While the routing engine is asked for the outline.
  final _measuring = ValueNotifier<bool>(false);

  static const _radii = [1.0, 2.0, 3.0, 5.0, 10.0, 20.0];
  static const _times = [10, 15, 20, 30, 45, 60];
  static const _roads = [3.0, 5.0, 10.0, 15.0, 25.0, 40.0];

  @override
  void initState() {
    super.initState();

    _radius.textController.addListener(_onRadius);
  }

  @override
  void didUpdateWidget(DeliveryReachField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // An outline measured for a motorcycle is not a van's: measured again.
    if (oldWidget.vehicle?.travel != widget.vehicle?.travel && _editor.method.routed && _editor.points.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _measure();
      });
    }
  }

  @override
  void dispose() {
    _radius.textController.removeListener(_onRadius);
    // A form only holds the fields it has seen built.
    _radius.dispose();
    _minutes.dispose();
    _km.dispose();
    _figures.dispose();
    _measuring.dispose();
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
    final branch = widget.branch;

    return ListenableBuilder(
      listenable: _editor,
      builder: (context, _) => FormSection(
        title: S.of(context).business_delivery_reach,
        note: branch != null && branch.isNotEmpty
          ? S.of(context).business_delivery_reach_note(branch)
          : S.of(context).business_delivery_reach_note_plain,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ways(context),
            SizedBox(height: AppSize.spaceS),
            ..._tools(context),
            SizedBox(height: AppSize.spaceS),
            _ReachReadout(editor: _editor, vehicle: widget.vehicle, branch: branch)
          ]
        )
      )
    );
  }

  /// The four ways, two by two.
  Widget _ways(BuildContext context) {
    Widget tile(AreaMethod method) => Expanded(child: _WayTile(
      icon: _icon(method),
      title: switch (method) {
        AreaMethod.radius => S.of(context).business_delivery_reach_radius,
        AreaMethod.travel => S.of(context).business_delivery_reach_time,
        AreaMethod.road => S.of(context).business_delivery_reach_road,
        AreaMethod.draw => S.of(context).business_delivery_reach_drawn
      },
      note: switch (method) {
        AreaMethod.radius => S.of(context).business_delivery_reach_radius_note,
        AreaMethod.travel => S.of(context).business_delivery_reach_time_note,
        AreaMethod.road => S.of(context).business_delivery_reach_road_note,
        AreaMethod.draw => S.of(context).business_delivery_reach_drawn_note
      },
      on: _editor.method == method,
      onTap: () => _editor.setMethod(method)
    ));

    return Column(children: [
      IntrinsicHeight(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(AreaMethod.radius), SizedBox(width: AppSize.gap), tile(AreaMethod.travel)]
      )),
      SizedBox(height: AppSize.gap),
      IntrinsicHeight(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(AreaMethod.road), SizedBox(width: AppSize.gap), tile(AreaMethod.draw)]
      ))
    ]);
  }

  /// What the way picked is shaped with.
  List<Widget> _tools(BuildContext context) => switch (_editor.method) {
    AreaMethod.radius => [
      Input(
        placeholder: S.of(context).business_delivery_reach_km_hint,
        controller: _radius,
        buttonSpace: false
      ),
      _chips([
        for (final km in _radii) AreaToolChip(
          label: S.of(context).deliveries_area_km(deliveryNumber(km)),
          chosen: _editor.radius == km,
          action: () => _radius.textController.text = deliveryNumber(km)
        )
      ])
    ],
    AreaMethod.travel => _routed(
      context,
      hint: S.of(context).business_delivery_reach_time_hint(_vehicleName(context).toLowerCase()),
      input: _minutes,
      placeholder: S.of(context).business_delivery_reach_minutes_hint,
      chips: [
        for (final minutes in _times) AreaToolChip(
          label: S.of(context).business_delivery_eta_minutes(minutes),
          chosen: _editor.points.isNotEmpty && _editor.minutes == minutes,
          action: () {
            _minutes.textController.text = "$minutes";
            _measure();
          }
        )
      ]
    ),
    AreaMethod.road => _routed(
      context,
      hint: S.of(context).business_delivery_reach_road_hint,
      input: _km,
      placeholder: S.of(context).business_delivery_reach_km_hint,
      chips: [
        for (final km in _roads) AreaToolChip(
          label: S.of(context).deliveries_area_km(deliveryNumber(km)),
          chosen: _editor.points.isNotEmpty && _editor.km == km,
          action: () {
            _km.textController.text = deliveryNumber(km);
            _measure();
          }
        )
      ]
    ),
    AreaMethod.draw => [
      _hint(context, S.of(context).business_delivery_reach_drawn_hint),
      _drawTools(context)
    ]
  };

  /// A time or a road distance: the figure, the usual ones, and once there is
  /// an outline, the tools to adjust it by hand.
  List<Widget> _routed(
    BuildContext context, {
    required String hint,
    required InputController input,
    required String placeholder,
    required List<Widget> chips
  }) => [
    _hint(context, _editor.points.isEmpty ? hint : S.of(context).business_delivery_reach_edit_hint),
    _chips(chips),
    SizedBox(height: AppSize.gap),
    Input(
      placeholder: placeholder,
      controller: input,
      buttonSpace: false,
      onSubmit: _measure
    ),
    Button(
      title: S.of(context).business_delivery_reach_show,
      leftIcon: Icon(CI.globe_shopping, color: ThemeColor.of(context).icon),
      loading: _measuring,
      action: _measure
    ),
    if (_editor.points.isNotEmpty) ...[
      SizedBox(height: AppSize.gap),
      _drawTools(context)
    ]
  ];

  Widget _drawTools(BuildContext context) => _chips([
    AreaToolChip(
      icon: CI.arrow_left,
      label: S.of(context).deliveries_area_undo,
      action: _editor.canUndo ? _editor.undo : null
    ),
    AreaToolChip(
      icon: CI.delete,
      label: S.of(context).deliveries_area_remove_point,
      action: _editor.selected == null ? null : _editor.removeSelected
    ),
    AreaToolChip(
      icon: CI.trash,
      label: S.of(context).deliveries_area_clear,
      action: _editor.points.isEmpty ? null : _editor.clearPoints
    )
  ]);

  Widget _chips(List<Widget> chips) => Padding(
    padding: EdgeInsets.only(top: AppSize.gap),
    child: Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: chips)
  );

  Widget _hint(BuildContext context, String text) => TextSmall(
    text,
    lines: 4,
    color: ThemeColor.of(context).text.secondary
  );

  String _vehicleName(BuildContext context) =>
    (widget.vehicle ?? DeliveryVehicle.motorcycle).label(context);

  /// Asks the routing engine how far the couriers get — in the minutes or
  /// the kilometres of road typed — and takes the outline as the shape.
  Future<void> _measure() async {
    final road = _editor.method == AreaMethod.road;
    final minutes = int.tryParse(_minutes.value.trim());
    final km = readDeliveryAmount(_km.value).value;
    final center = _editor.center;
    final service = context.read<DeliveryAreasService?>();

    if (road ? (km == null || km < 0.1 || km > 200) : (minutes == null || minutes < 1 || minutes > 120)) {
      FloatFlag.of(context).error(message: road
        ? S.of(context).business_delivery_reach_km_invalid
        : S.of(context).deliveries_area_travel_invalid);
      return;
    }

    if (center == null || service == null || _measuring.value) return;

    _measuring.value = true;

    final outline = road
      ? await service.roadShape(center, km!, _mode)
      : await service.travelShape(center, minutes!, _mode);

    if (!mounted) return;

    _measuring.value = false;

    if (outline == null || outline.length < 3) {
      FloatFlag.of(context).error(message: S.of(context).deliveries_area_travel_failed);
      return;
    }

    // The figure the outline answers, kept with it until it is saved.
    road ? _editor.setKm(km!) : _editor.setMinutes(minutes!);
    _editor.useOutline(outline);
  }

  static IconData _icon(AreaMethod method) => switch (method) {
    AreaMethod.radius => CI.circle,
    AreaMethod.travel => Icons.schedule_rounded,
    AreaMethod.road => Icons.route_rounded,
    AreaMethod.draw => CI.pen
  };
}

/// One way of saying how far they go: its glyph, its name and what it means.
/// The one picked is ringed in the colour the map draws the shape in.
class _WayTile extends StatelessWidget {
  const _WayTile({
    required this.icon,
    required this.title,
    required this.note,
    required this.on,
    required this.onTap
  });

  final IconData icon;
  final String title;
  final String note;
  final bool on;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = scheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        border: Border.all(color: on ? color : scheme.line, width: on ? 1.5 : 1),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: FeedbackButton(
        action: onTap,
        message: note,
        padding: EdgeInsets.all(AppSize.spaceXS),
        radius: AppSize.corner,
        color: on ? color.withValues(alpha: 0.08) : scheme.surface,
        feedbackColor: scheme.surfaceFeedback,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSize.text * 1.2, color: on ? color : scheme.icon),
            SizedBox(height: AppSize.gap),
            TextSmall(title, bold: true, ellipsis: true, color: on ? color : scheme.text.primary),
            TextSmall(note, lines: 2, color: scheme.text.secondary)
          ]
        )
      )
    );
  }
}

/// The reach as it stands, in the colour the map draws it: how big it is,
/// followed live, and what it was measured in. One line of figures and not a
/// headline: the map is where the shape is looked at.
class _ReachReadout extends StatelessWidget {
  const _ReachReadout({required this.editor, this.vehicle, this.branch});

  final AreaEditor editor;
  final DeliveryVehicle? vehicle;
  final String? branch;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = scheme.primary;
    final shaped = editor.hasShape;
    final circle = editor.method == AreaMethod.radius;
    final points = editor.points;

    final squareKm = !shaped
      ? 0.0
      : circle ? math.pi * editor.radius * editor.radius : ringSquareKm(points);

    final rider = (vehicle ?? DeliveryVehicle.motorcycle).label(context).toLowerCase();
    final branch = this.branch;
    final by = branch != null && branch.isNotEmpty
      ? S.of(context).business_delivery_reach_by(rider, branch)
      : S.of(context).business_delivery_reach_by_plain(rider);

    final detail = switch (editor.method) {
      AreaMethod.radius => deliveryRadiusLabel(context, editor.radius),
      AreaMethod.draw => S.of(context).deliveries_area_points(points.length),
      AreaMethod.travel || AreaMethod.road => points.isEmpty ? S.of(context).business_delivery_reach_unmeasured : by
    };

    return Row(children: [
      // The draft's own swatch: filled and ringed as the map fills and rings it.
      Container(
        width: AppSize.text,
        height: AppSize.text,
        decoration: BoxDecoration(
          color: color.withValues(alpha: shaped ? 0.25 : 0.06),
          border: Border.all(color: color.withValues(alpha: shaped ? 1 : 0.4), width: 2),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(AppSize.gap / 2)
        )
      ),
      SizedBox(width: AppSize.spaceXS),
      TextSmall(
        S.of(context).deliveries_area_size(deliveryNumber(squareKm)),
        bold: true,
        color: shaped ? scheme.text.primary : scheme.text.secondary
      ),
      SizedBox(width: AppSize.gap),
      Expanded(child: TextSmall(
        detail,
        ellipsis: true,
        // Short of a shape, what it still needs is the news.
        color: shaped ? scheme.text.secondary : scheme.chart.warning
      ))
    ]);
  }
}
