import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/delivery_areas_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

import '../deliveries_map.dart';
import './state/area_editor.dart';
import './widgets/area_editor_panel.dart';
import './widgets/area_layers.dart';
import './widgets/area_list.dart';

/// Body of the delivery area: a panel on the left (one third) and the map on
/// the right (two thirds), like the deliveries desk.
///
/// While looking, the panel lists the areas and a tap on the map says which of
/// them reach that point. While an area is shaped, the panel holds its tools
/// and its name and figures, and the map is where the shape is made.
class DeliveryAreaBody extends StatefulWidget {
  const DeliveryAreaBody({
    super.key,
    required this.editor,
    required this.map,
    required this.origin
  });

  final AreaEditor editor;
  final MapController map;

  /// Where an area opened with no center of its own starts.
  final LatLng Function() origin;

  @override
  State<DeliveryAreaBody> createState() => _DeliveryAreaBodyState();
}

class _DeliveryAreaBodyState extends State<DeliveryAreaBody> {
  AreaEditor get _editor => widget.editor;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeliveryAreasService>();
    final areas = service.areas;

    return switch (service.status) {
      DeliveryAreasStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).deliveries_area_error_title,
        subtitle: S.of(context).deliveries_area_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).deliveries_map_retry
      ),
      DeliveryAreasStatus.ready when areas != null => ListenableBuilder(
        listenable: _editor,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _editor.isOpen
              ? AreaEditorPanel(
                  key: ValueKey(_editor.session),
                  editor: _editor,
                  currency: areas.currency,
                  count: areas.areas.length
                )
              : AreaList(
                  areas: areas,
                  probe: _editor.probe,
                  onClearProbe: _editor.clearProbe,
                  onFocus: (area) => _editor.fit(area.bounds),
                  onEdit: (area) => _editor.edit(area, widget.origin()),
                  onToggle: (area) => _toggle(service, area),
                  onRemove: (area) => _remove(service, area)
                )),
            SizedBox(width: AppSize.gap),
            Expanded(flex: 2, child: DeliveriesMap(
              controller: widget.map,
              layers: areaLayers(context, areas.areas, _editor),
              overlays: areaOverlays(context, _editor),
              onTap: _editor.tap
            ))
          ]
        )
      ),
      _ => const Center(child: Loading())
    };
  }

  Future<void> _toggle(DeliveryAreasService service, DeliveryArea area) =>
    service.update(context, deliveryAreaActiveRequest(area, !area.active));

  Future<void> _remove(DeliveryAreasService service, DeliveryArea area) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).deliveries_area_remove_title,
      message: S.of(context).deliveries_area_remove_message(area.name),
      confirmText: S.of(context).deliveries_area_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    await service.remove(context, area.id);
  }
}
