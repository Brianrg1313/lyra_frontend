import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/employment_invitation_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/employees/employee_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// What the invitation says, and the button to accept it. Pops `true` once
/// accepted; the opener re-reads `/init` to know where to land. Declining
/// (`ACTION: decline`) is not offered yet.
class InvitationModal extends StatefulWidget {
  const InvitationModal({super.key, required this.invitation});

  final EmploymentInvitation invitation;

  @override
  State<InvitationModal> createState() => _InvitationModalState();
}

class _InvitationModalState extends State<InvitationModal> {
  final _loading = ValueNotifier(false);

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final invitation = widget.invitation;

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      children: [
        Row(children: [
          ProfilePicture(
            kind: ProfileKind.business,
            url: invitation.businessLogo?.thumbnail,
            size: AppSize.action,
            label: invitation.businessName
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextLarge(
            s.welcome_invitation_title(invitation.businessName),
            lines: 2,
            ellipsis: true
          ))
        ]),
        SizedBox(height: AppSize.spaceM),
        SettingsBlock(
          title: s.welcome_invitation_modal_title,
          child: SettingsList(rows: [
            SettingsValue(icon: CI.store, label: s.welcome_invitation_company, value: invitation.businessName),
            if (invitation.jobTitle.isNotEmpty)
              SettingsValue(icon: CI.employee_badge, label: s.welcome_invitation_role, value: invitation.jobTitle),
            if (invitation.department.isNotEmpty)
              SettingsValue(icon: CI.employee, label: s.welcome_invitation_department, value: invitation.department),
            if (invitation.branch?.isNotEmpty ?? false)
              SettingsValue(icon: CI.shop, label: s.welcome_invitation_branch, value: invitation.branch!),
            if (invitation.invitedDate != null)
              SettingsValue(
                icon: CI.calendar,
                label: s.welcome_invitation_date,
                value: employeeMomentLabel(context, invitation.invitedDate)
              )
          ])
        ),
        SizedBox(height: AppSize.spaceS),
        TextMedium(
          s.welcome_invitation_accept_notice(invitation.businessName),
          lines: 3,
          color: ThemeColor.of(context).subtitle
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: s.welcome_invitation_accept,
          loading: _loading,
          action: _accept
        )
      ]
    );
  }

  Future<void> _accept() async {
    if (_loading.value) return;
    _loading.value = true;

    try {
      await context.read<ClientService>().acceptInvitation(widget.invitation.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      FloatFlag.showFromError(e);
      if (mounted) _loading.value = false;
    }
  }
}
