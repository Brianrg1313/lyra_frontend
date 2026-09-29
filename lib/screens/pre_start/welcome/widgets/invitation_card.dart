import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/employment_invitation_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/business_avatar.dart';

/// A pending invitation: which company sent it and, when it says, for what
/// position. Only drawn while `/init` lists the `employment.invitation` task.
/// Drawn first and larger than the ways to start: it is an answer owed, not
/// one more choice.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.invitation,
    required this.action
  });

  final EmploymentInvitation invitation;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final company = invitation.businessName;
    final job = invitation.jobTitle.trim();

    return FeedbackButton(
      width: double.infinity,
      color: scheme.surface,
      feedbackColor: scheme.surfaceOver,
      action: action,
      padding: EdgeInsets.all(AppSize.spaceM),
      child: Row(children: [
        BusinessAvatar(
          name: company,
          url: invitation.businessLogo?.thumbnail,
          size: AppSize.action * 1.5
        ),
        SizedBox(width: AppSize.spaceM),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextLarge(S.of(context).welcome_invitation_title(company), lines: 1, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              job.isEmpty
                ? S.of(context).welcome_invitation_subtitle
                : S.of(context).welcome_invitation_job(job, company),
              lines: 2,
              ellipsis: true,
              color: scheme.subtitle
            )
          ]
        )),
        SizedBox(width: AppSize.spaceM),
        FeedbackButton(
          color: scheme.surfaceOver,
          feedbackColor: scheme.surfaceFeedback,
          action: action,
          padding: EdgeInsets.symmetric(
            vertical: AppSize.gap,
            horizontal: AppSize.spaceS
          ),
          child: TextSmall(S.of(context).welcome_invitation_action, color: scheme.text.primary)
        )
      ])
    );
  }
}
