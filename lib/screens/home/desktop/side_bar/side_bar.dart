import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';

import 'package:app/screens/home/sections/_sections.dart';

// WIDGETS
import 'package:app/screens/home/desktop/side_bar/business_selector.dart';

import './profile.dart';
import './options.dart';
import './sign_out.dart';

class SideBar extends StatelessWidget {
  const SideBar({required this.section, super.key});

  /// Seccion abierta, usada para marcar su opcion en la lista.
  final HomeSection section;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeService>();
    final isExpanded = home.isSideBarExpanded;

    return AnimatedContainer(
      curve: Curves.easeInOut,
      width: home.sideBarWidth,
      duration: const Duration(milliseconds: 200),
      child: Surface(
        child: Column(children: [
          ProfileCard(isExpanded: isExpanded),
          Separator.horizontal(
            margin: EdgeInsets.symmetric(horizontal: AppSize.padding),
          ),
          Expanded(child: ScrollableWidget(
            showBar: false,
            padding: EdgeInsets.symmetric(vertical: AppSize.padding),
            children: options(context, section, isExpanded)
          )),
          Separator.horizontal(
            margin: EdgeInsets.symmetric(horizontal: AppSize.padding),
          ),
          BusinessSelector(isExpanded: isExpanded),
          SignOut(
            isExpanded: isExpanded,
            toggle: () => context.read<HomeService>().toggleSideBar()
          )
        ])
      )
    );
  }
}
