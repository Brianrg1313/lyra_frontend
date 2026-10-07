import 'package:flutter/material.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_tabs.dart';

import './business_tab.dart';

/// Tab bar of a business's page.
///
/// It carries no title. Which business it is is told by the tab that opens
/// —with its name big— and the home bar selector, which is always in view:
/// repeating it here was writing the same name twice on the same screen and
/// stealing width from the tabs.
///
/// It also carries no back button: there is nowhere to go. The business
/// section is this page, the one of the business being worked with; to move to
/// another there is the header selector.
///
/// The bar itself is [SectionTabs], which is the same one the money page draws:
/// what belongs to a business is which tabs there are and what each is called,
/// and that is exactly what this widget hands over.
class BusinessDetailHeader extends StatelessWidget {
  const BusinessDetailHeader({
    super.key,
    required this.tab,
    required this.onTab
  });

  /// Open tab, the one drawn marked.
  final BusinessTab tab;

  /// Another tab was asked to open. It is a navigation: each tab is a URL (see
  /// `BusinessDetailSection`).
  final void Function(BusinessTab tab) onTab;

  @override
  Widget build(BuildContext context) => SectionTabs<BusinessTab>(
    tabs: BusinessTab.values,
    active: tab,
    icon: (value) => value.icon,
    title: (context, value) => value.title(context),
    onTab: onTab,
    isLocked: (value) => !value.granted,
    badge: (value) => value.badge
  );
}
