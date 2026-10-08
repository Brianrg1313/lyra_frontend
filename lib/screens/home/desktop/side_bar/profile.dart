import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_detail/_employee_detail.dart';

import 'connection_dot.dart';

/// The signed-in person in the side bar. Pressing it opens their own card in
/// the active company's employees section, which is where a member's profile
/// lives; with no company there is nowhere to open it, so it stays still.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.isExpanded,
    super.key,
  });

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientService>();
    final businessId = context.select<BusinessService, String?>((service) => service.activeId);

    // Signing out empties the client once home is left, but a route leaving
    // with a transition can still be painted then.
    if (!client.isAuthenticated) return const SizedBox.shrink();

    return FeedbackButton(
    action: businessId == null ? null : () => _open(context),
    mouseCursor: businessId == null ? SystemMouseCursors.basic : null,
    message: S.of(context).side_bar_profile,
    color: ThemeColor.of(context).navBar,
    feedbackColor: businessId == null ? Colors.transparent : ThemeColor.of(context).line,
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The connection's state hangs off the picture's bottom-right corner.
        Stack(clipBehavior: Clip.none, children: [ProfilePicture(
          kind: ProfileKind.user,
          url: client.picture,
          size: AppSize.action,
          label: client.fullName
        ),
        Positioned(right: -AppSize.gap / 2, bottom: -AppSize.gap / 2, child: const ConnectionDot())]),
        // The spacing goes inside the Expanded so it can shrink to 0 while
        // the side bar animates its width; as a fixed SizedBox it would cause
        // overflow during the first frames of the expansion.
        if (isExpanded) Expanded(child: Padding(
          padding: EdgeInsets.only(left: AppSize.spaceXS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextLarge(client.fullName, ellipsis: true, multiplier: 1.5),
              TextSmall(client.email, ellipsis: true)
            ])))
      ])
    );
  }

  void _open(BuildContext context) {
    final path = EmployeeDetailPage.path(BusinessEmployeeModel.meKey);

    // Already there: pushing it again would stack the same page.
    if (Navis.currentPath != path) Navis.push(context, path);
  }
}
