import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';

import 'package:app/screens/home/sections/_sections.dart';

// WIDGETS
import './business_selector.dart';
import './options.dart';
import './sign_out.dart';

class SideBar extends StatelessWidget {
  const SideBar({required this.section, super.key});

  /// Open section, used to mark its option in the list.
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
        padding: EdgeInsets.all(AppSize.gap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ThemeColor.of(context).navBar,
            border: Border.all(color: ThemeColor.of(context).line),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap)),
            boxShadow: [BoxShadow(
              color: ThemeColor.of(context).background.withAlpha(50),
              blurRadius: AppSize.gap,
              spreadRadius: 1
            )]
          ),
          child: Column(children: [
            const BusinessSelector(),
            Separator.horizontal(
              margin: EdgeInsets.symmetric(horizontal: AppSize.padding),
            ),
            Expanded(child: ScrollableWidget(
              showBar: false,
              padding: EdgeInsets.symmetric(vertical: AppSize.padding),
              children: options(context, section, isExpanded)
            )),
            // The bottom margin comes from the line, not from [SignOut]: the
            // gap used to be filled by the business selector, which now lives
            // in the header.
            Separator.horizontal(
              margin: EdgeInsets.fromLTRB(
                AppSize.padding, 0,
                AppSize.padding, AppSize.padding
              )
            ),
            SignOut(
              isExpanded: isExpanded,
              toggle: () => context.read<HomeService>().toggleSideBar()
            )
          ])
        )
      )
    );
  }
}
