import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_section.dart';
import 'package:app/screens/home/sections/employees/employee_detail/_employee_detail.dart';

import 'connection_dot.dart';

/// The signed-in person, at the right end of the header. Pressing it unfolds a
/// menu of what is theirs: their own card in the active company's employees
/// section (where a member's profile lives), the account's pages that are edited
/// most, straight to them, and the app's updates (not built yet). Every page
/// lives on that card, so with no company there is nowhere to open them and it
/// stays still.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientService>();
    final businessId = context.select<BusinessService, String?>((service) => service.activeId);

    // Signing out empties the client once home is left, but a route leaving
    // with a transition can still be painted then.
    if (!client.isAuthenticated) return const SizedBox.shrink();

    return FeedbackButton(
      action: businessId == null ? null : () => _menu(context),
      mouseCursor: businessId == null ? SystemMouseCursors.basic : null,
      message: "${client.fullName}\n${client.email}",
      height: AppSize.action,
      radius: AppSize.cornerInset(AppSize.gap),
      color: ThemeColor.of(context).surface,
      feedbackColor: businessId == null ? Colors.transparent : ThemeColor.of(context).surfaceFeedback,
      // Only the picture: the name and email are the tooltip's.
      child: SizedBox(
        width: AppSize.action,
        height: AppSize.action,
        child: Center(child: Stack(clipBehavior: Clip.none, children: [
          ProfilePicture(
            kind: ProfileKind.user,
            url: client.picture,
            size: AppSize.action - AppSize.spaceXS,
            label: client.fullName
          ),
          // The connection's state hangs off the picture's bottom-right corner.
          Positioned(right: -AppSize.gap / 2, bottom: -AppSize.gap / 2, child: const ConnectionDot())
        ]))
      )
    );
  }

  /// The account's pages the menu goes straight to; the rest stay on the card.
  static const _shortcuts = [
    OwnSection.preferences,
    OwnSection.security,
    OwnSection.methods,
    OwnSection.sessions
  ];

  static const _account = "account";
  static const _updates = "updates";

  Future<void> _menu(BuildContext context) async {
    final s = S.of(context);
    final options = [
      SelectOption(
        value: _account,
        placeholder: s.account,
        icon: CI.user_circle
      ),
      for (final section in _shortcuts) SelectOption(
        value: section.name,
        placeholder: section.title(s),
        icon: section.icon
      ),
      SelectOption(
        value: _updates,
        placeholder: s.profile_menu_updates,
        icon: CI.gift
      )
    ];

    final chosen = await showSelectMenu(
      context: context,
      options: options,
      selected: _current(),
      maxOptions: options.length
    );
    if (chosen == null || !context.mounted) return;

    switch (chosen.value) {
      case _account: _open(context, EmployeeDetailPage.path(BusinessEmployeeModel.meKey));
      case _updates: FloatFlag.of(context).message(s.coming_soon);
      default: _open(context, OwnSection.values.byName(chosen.value).path);
    }
  }

  /// The option of the page open now, marked in the menu.
  String? _current() {
    final path = Navis.currentPath;
    if (path == EmployeeDetailPage.path(BusinessEmployeeModel.meKey)) return _account;

    return _shortcuts.where((section) => section.path == path).firstOrNull?.name;
  }

  void _open(BuildContext context, String path) {
    // Already there: pushing it again would stack the same page.
    if (Navis.currentPath != path) Navis.push(context, path);
  }
}
