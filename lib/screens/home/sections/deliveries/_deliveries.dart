import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';

import './deliveries_header.dart';
import './deliveries_map.dart';
import './pending_list.dart';

/// **The deliveries desk**: the content of the `deliveries` section.
///
/// A header with the title and the actions, and below it two panels side by
/// side, one third and two thirds, like the messages desk: the deliveries
/// still pending on the left, and the map they are followed on on the right.
/// The [MapController] lives here because the header moves the map.
///
/// [BusinessLocationService] lives here and not app-wide, as on the business
/// page: the map opens on the company's own point, and a business switch
/// remounts the section, which is what drops the previous company's point.
/// [MapTilesService] lives here too: only this section draws a map.
class DeliveriesSection extends StatefulWidget {
  const DeliveriesSection({super.key});

  @override
  State<DeliveriesSection> createState() => _DeliveriesSectionState();
}

class _DeliveriesSectionState extends State<DeliveriesSection> {
  final BusinessLocationService _location = BusinessLocationService();
  final MapTilesService _tiles = MapTilesService();
  final MapController _map = MapController();

  @override
  void initState() {
    super.initState();

    // Deferred: the read notifies, and notifying while mounting rebuilds mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _location.load();
      _tiles.load();
    });
  }

  @override
  void dispose() {
    _location.dispose();
    _tiles.dispose();
    _map.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles)
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeliveriesHeader(),
        SizedBox(height: AppSize.gap),
        Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: Surface(child: PendingDeliveriesPanel())),
            SizedBox(width: AppSize.gap),
            Expanded(flex: 2, child: DeliveriesMap(controller: _map))
          ]
        ))
      ]
    )
  );
}
