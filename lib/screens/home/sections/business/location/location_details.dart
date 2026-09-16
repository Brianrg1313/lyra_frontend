import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// SERVICES
import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/settings/profile_block.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';

/// The location, read: the written address in one block and the map point in
/// another.
///
/// Built from the profile's rows ([ProfileBlock], [ProfileField]) because it
/// is the same sheet of the same page, and a datum reads the same way in
/// either tab. Every row is drawn even when empty —"Not set", in grey—: the
/// empty row is what tells a company what it has not said yet, and the panel
/// the block's title opens is where it is said.
///
/// The point is a block of its own and not one more line of the address: it
/// is a different fact, stated apart (see [BusinessLocationModel]).
class BusinessLocationDetails extends StatelessWidget {
  const BusinessLocationDetails({
    super.key,
    required this.location,
    required this.onEdit
  });

  final BusinessLocationModel location;

  /// Opens the panel that edits the whole location.
  final void Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final countries = context.watch<CountryCatalogService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileBlock(
          title: S.of(context).business_location_section_address,
          action: ProfileTextAction(
            label: S.of(context).business_location_edit,
            action: onEdit
          ),
          fields: [
            ProfileField(
              icon: CI.shop,
              label: S.of(context).business_location_address,
              description: S.of(context).business_location_address_note,
              value: location.address,
              selectable: true
            ),
            ProfileField(
              icon: CI.bookmark,
              label: S.of(context).business_location_landmark,
              description: S.of(context).business_location_landmark_note,
              value: location.landmark
            ),
            ProfileField(
              icon: CI.store,
              label: S.of(context).business_location_city,
              value: location.city
            ),
            ProfileField(
              icon: CI.list,
              label: S.of(context).business_location_region,
              value: location.region
            ),
            ProfileField(
              icon: CI.mail,
              label: S.of(context).business_location_postal_code,
              value: location.postalCode
            ),
            // One more line of the address, read by its name and not by its
            // code: the code is what travels, not what anybody recognises their
            // own country by. It is edited with the rest, from the block's
            // panel.
            ProfileField(
              icon: CI.home,
              label: S.of(context).business_location_country,
              description: S.of(context).business_location_country_note,
              value: countries.nameOf(location.country)
            )
          ]
        ),
        SizedBox(height: AppSize.padding),
        ProfileBlock(
          title: S.of(context).business_location_section_map,
          fields: [_Point(location: location)]
        )
      ]
    );
  }
}

/// The map point: its coordinates, which can be copied, and the button that
/// opens them in a map.
class _Point extends StatelessWidget {
  const _Point({required this.location});

  final BusinessLocationModel location;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final open = location.hasPoint && location.maps.isNotEmpty;

    return ProfileFieldFrame(
      icon: CI.globe_shopping,
      label: S.of(context).business_location_point,
      description: S.of(context).business_location_point_note,
      action: open
        ? ProfileAction(
            icon: CI.link,
            message: S.of(context).business_location_open_map,
            action: () => _open(context)
          )
        : null,
      child: location.hasPoint
        ? TextMedium(location.point, selectable: true)
        : TextMedium(
            S.of(context).business_profile_empty,
            color: scheme.text.secondary
          )
    );
  }

  /// Opens the backend's link, which is the cross-platform form of a map URL:
  /// the map app on a phone that has one, the browser everywhere else.
  ///
  /// Opening is the system's business and can fail for reasons that are not
  /// the link; that is said, because a touch that silently does nothing reads
  /// as a broken button.
  Future<void> _open(BuildContext context) async {
    bool opened = false;

    final url = Uri.tryParse(location.maps);

    if (url != null) {
      try {
        opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (error) {
        if (kDebugMode) print("Could not open $url: $error");
      }
    }

    if (opened || !context.mounted) return;

    FloatFlag.of(context).error(
      message: S.of(context).business_location_map_failed
    );
  }
}
