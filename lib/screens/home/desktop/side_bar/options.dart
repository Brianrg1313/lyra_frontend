import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/badges/badges_service.dart';

import 'package:app/screens/home/sections/_sections.dart';

import './option.dart';

/// [active] is the open section, already resolved in `Home` from
/// [Navis.currentKey] (a sub-page is reflected in the section that contains
/// it). Each option marks itself by comparing against it.
///
/// The app's search field no longer lives here but in the header, which is
/// fixed and keeps it in sight whether or not the side bar is expanded.
///
/// With no active business, the options that depend on one stay locked:
/// everything they show belongs to a business, so opening any of them before
/// creating the first would lead nowhere (see [HomeSection.needsBusiness]).
/// The dashboard and the businesses option stay enabled; with none yet, the
/// latter is how the first gets created —the same path the header selector
/// offers—.
///
/// With one, a section the person is not granted (`<section>.view` in
/// [PermissionsService], see [HomeSection.area]) is locked the same way,
/// so the side bar keeps its shape across companies, but it still opens: the
/// section is drawn as `NoPermissionSection`, which is where access is asked.
/// The businesses and employees options are always granted to a member, and the
/// dashboard is not a company's.
///
/// A section the network or the master can't serve now ([CapabilityService],
/// `needsInternet`) is locked before any of that, and opens on the message that
/// says so: nothing disappears with the internet (plan §9.6). Only one that can't
/// exist in the mode at all is left out.
///
/// Only the active business **id** is watched, not the whole service: the
/// grants are per company, so a switch relocks the list, but the rest of its
/// notifications (a creation, loading the detail) change nothing here.
List<Widget> options(BuildContext context, HomeSection active, bool isExpanded) {
  final businessId = context.select<BusinessService, String?>(
    (service) => service.activeId
  );
  // The grants are read through [HomeSection.granted]; watched so a reread relocks the list.
  context.watch<PermissionsService>();
  final capabilities = context.watch<CapabilityService>();

  String? lock(HomeSection section) {
    switch (capabilities.of(section.area)) {
      case Capability.needsInternet: return S.of(context).section_needs_internet_title;
      case Capability.needsLink: return S.of(context).section_needs_link_title;
      default:
    }

    if (businessId == null) {
      return section.needsBusiness ? S.of(context).section_no_business_subtitle : null;
    }

    return section.granted(businessId)
      ? null
      : S.of(context).section_no_permission;
  }

  Widget option(HomeSection section) => _option(
    context,
    section,
    active,
    isExpanded,
    lock(section),
    businessId != null || capabilities.locked(section.area)
  );

  /// A group whose sections are all left out loses its title too.
  List<Widget> group(Iterable<HomeSection> sections, [String? title]) {
    final shown = sections.where((section) => capabilities.exists(section.area));
    if (shown.isEmpty) return const [];

    return [
      if (title != null) Sp(isExpanded, title: title),
      ...shown.map(option)
    ];
  }

  return [
    ...group(HomeSection.home),
    ...group(HomeSection.operations, S.of(context).section_operations),
    ...group(HomeSection.resources, S.of(context).section_resources),
    ...group(HomeSection.management, S.of(context).section_management),
    ...group(HomeSection.integrations, S.of(context).section_integrations)
  ];
}

Widget _option(
  BuildContext context,
  HomeSection section,
  HomeSection active,
  bool isExpanded,
  String? lockedMessage,
  bool opensLocked
) => Option(
  key: ValueKey(section.key),
  icon: section.icon,
  title: section.title(context),
  isExpanded: isExpanded,
  isActive: section == active,
  lockedMessage: lockedMessage,
  opensLocked: opensLocked,
  badge: BadgePlace.section(section.key),
  action: () {
    context.read<HomeService>().goTo(context, section);

    // A section marked new has been found.
    final place = BadgePlace.section(section.key);
    if (place != null) BadgesService().discover(place);
  }
);

class Sp extends StatelessWidget {
  const Sp(this.isExpanded, {super.key, required this.title});

  final bool isExpanded;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return Padding(
        padding: EdgeInsets.only(
          top: AppSize.spaceXS,
          left: AppSize.spaceXS * 2,
          bottom: AppSize.gap
        ),
        child: TextSmall(title),
      );
    } else {
      return Separator.horizontal(
        margin: EdgeInsets.all(AppSize.padding)
      );
    }
  }
}
