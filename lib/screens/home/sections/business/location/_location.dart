import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/business/edit_location/_edit_location.dart';

import 'location_details.dart';

/// Location tab: where the company is — the written address and the point on
/// the map (`/business/location/`).
///
/// It is the company's **one** location. The backend has no model for several
/// sites yet: its branches endpoint is a placeholder that answers an empty
/// list, and when branches become rows they will have this same shape. Until
/// then this is the address a customer asking "where are you?" is given, and
/// the branches tab says it is coming.
///
/// The sheet is read and one panel edits it whole ([showLocationForm]): an
/// address is corrected as a unit —the street, the city and the postal code
/// move together when a shop moves—, unlike the profile, which is corrected
/// row by row.
///
/// What it reads is provided by the page (see `BusinessDetailSection`), so
/// coming back to this tab does not read it again.
class BusinessLocationTab extends StatefulWidget {
  const BusinessLocationTab({super.key});

  @override
  State<BusinessLocationTab> createState() => _BusinessLocationTabState();
}

class _BusinessLocationTabState extends State<BusinessLocationTab> {
  @override
  void initState() {
    super.initState();

    // Deferred to the first frame because the load notifies the service, and
    // notifying while the tree is mounting is a rebuild in the middle of a
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessLocationService>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessLocationService>();
    final location = service.location;

    return switch (service.status) {
      BusinessLocationStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).business_location_error_title,
        subtitle: S.of(context).business_location_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).business_list_retry
      ),
      BusinessLocationStatus.ready when location != null => ScrollableWidget(
        showBar: false,
        children: [BusinessLocationDetails(location: location, onEdit: _edit)]
      ),
      _ => const Center(child: Loading())
    };
  }

  /// Opens the panel and writes what it hands back.
  Future<void> _edit() async {
    final service = context.read<BusinessLocationService>();
    final location = service.location;

    if (location == null) return;

    final request = await showLocationForm(context, location: location);

    if (request == null || request.isEmpty || !mounted) return;

    final saved = await service.update(context, request);

    if (!saved || !mounted) return;

    // The country is read beyond this tab —the delivery tab offers its carriers
    // against it— so the profile this page holds is reread. The address is not:
    // nothing outside the location reads it since it stopped being a row of the
    // settings sheet.
    if (request.containsKey("COUNTRY")) {
      unawaited(context.read<BusinessService>().refreshProfile());
    }
  }
}
