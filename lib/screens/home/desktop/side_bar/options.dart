import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

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
/// [PermissionsService], section keys being area keys) is locked the same way,
/// so the side bar keeps its shape across companies, but it still opens: the
/// section is drawn as `NoPermissionSection`, which is where access is asked.
/// The businesses option is always granted to a member, and the dashboard is
/// not a company's.
///
/// A section the deployment mode doesn't have ([CapabilityService]) is left out
/// instead: it is not part of the product there, so there is nothing to ask for.
///
/// Only the active business **id** is watched, not the whole service: the
/// grants are per company, so a switch relocks the list, but the rest of its
/// notifications (a creation, loading the detail) change nothing here.
List<Widget> options(BuildContext context, HomeSection active, bool isExpanded) {
  final businessId = context.select<BusinessService, String?>(
    (service) => service.activeId
  );
  final permissions = context.watch<PermissionsService>();
  final capabilities = context.watch<CapabilityService>();

  String? lock(HomeSection section) {
    if (businessId == null) {
      return section.needsBusiness ? S.of(context).section_no_business_subtitle : null;
    }

    return permissions.canOpen(section.key, business: businessId)
      ? null
      : S.of(context).section_no_permission;
  }

  Widget option(HomeSection section) =>
    _option(context, section, active, isExpanded, lock(section), businessId != null);

  /// A group whose sections are all left out loses its title too.
  List<Widget> group(Iterable<HomeSection> sections, [String? title]) {
    final shown = sections.where((section) => capabilities.shows(section.key));
    if (shown.isEmpty) return const [];

    return [
      if (title != null) Sp(isExpanded, title: title),
      ...shown.map(option)
    ];
  }

  return [
    ...group(HomeSection.home),
    ...group(HomeSection.products, S.of(context).section_products),
    ...group(HomeSection.reports, S.of(context).section_reports),
    ...group(HomeSection.connectionGroups, S.of(context).section_connections)
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
  action: () => context.read<HomeService>().goTo(context, section)
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
