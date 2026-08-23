import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';

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
/// Only whether an active business **exists** is watched, not the whole
/// service: switching businesses changes nothing in this list, and neither do
/// the rest of its notifications (a creation, loading the detail).
List<Widget> options(BuildContext context, HomeSection active, bool isExpanded) {
  final hasBusiness = context.select<BusinessService, bool>(
    (service) => service.activeId != null
  );

  Widget option(HomeSection section) =>
    _option(context, section, active, isExpanded, hasBusiness);

  return [
    ...HomeSection.home.map(option),
    Sp(isExpanded, title: S.of(context).section_products),
    ...HomeSection.productos.map(option),
    Sp(isExpanded, title: S.of(context).section_reports),
    ...HomeSection.reportes.map(option),
    Sp(isExpanded, title: S.of(context).section_connections),
    ...HomeSection.conexiones.map(option)
  ];
}

Widget _option(
  BuildContext context,
  HomeSection section,
  HomeSection active,
  bool isExpanded,
  bool hasBusiness
) => Option(
  key: ValueKey(section.key),
  icon: section.icon,
  title: section.title(context),
  isExpanded: isExpanded,
  isActive: section == active,
  isLocked: !hasBusiness && section.needsBusiness,
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
