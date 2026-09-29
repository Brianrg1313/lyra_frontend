import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// For someone whose company already uses Lyra: a company invites by email
/// (`POST /business/employees/invite/`), so the one thing to hand over is the
/// address this account signed up with.
class AwaitingInvitationModal extends StatelessWidget {
  const AwaitingInvitationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      children: [
        TextMedium(
          s.welcome_awaiting_body,
          lines: 4,
          color: ThemeColor.of(context).subtitle
        ),
        SizedBox(height: AppSize.spaceM),
        SettingsValue(
          icon: CI.mail,
          label: s.email_input,
          value: context.read<ClientService>().email,
          selectable: true
        )
      ]
    );
  }
}
