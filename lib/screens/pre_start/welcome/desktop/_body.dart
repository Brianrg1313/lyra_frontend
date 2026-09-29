import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/employment_invitation_model.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/images.dart';
import 'package:app/screens/pre_start/welcome/_welcome.dart';
import 'package:app/screens/pre_start/welcome/widgets/welcome_avatar.dart';
import 'package:app/screens/pre_start/welcome/widgets/welcome_option.dart';
import 'package:app/screens/pre_start/welcome/widgets/welcome_choice.dart';
import 'package:app/screens/pre_start/welcome/widgets/invitation_card.dart';
import 'package:app/screens/modals/business/create_business/_create_business.dart';
import 'package:app/screens/modals/pre_start/invitation/_invitation.dart';
import 'package:app/screens/modals/pre_start/awaiting_invitation/_awaiting_invitation.dart';
import 'package:app/screens/modals/pre_start/job_openings/_job_openings.dart';

/// Signing out is the only way off the page besides finishing a task: the
/// dashboard stays closed while one is pending.
class DesktopBody extends StatelessWidget {
  const DesktopBody({super.key});

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientService>();

    // Signing out empties the client once the page is left, but the leaving
    // transition can still paint it.
    if (!client.isAuthenticated) return const SizedBox.shrink();

    final invitations = client.invitations;

    // `employment.invitation` is also sent to someone who already has a
    // company: they only owe the answer, not a way to start.
    final hasBusiness = context.watch<BusinessService>().hasBusiness;

    return Skeleton.simple(
      padding: EdgeInsets.all(AppSize.spaceM),
      // Centered in the window while it fits; once it does not, the minimum
      // height gives way and the page scrolls from the top.
      body: LayoutBuilder(builder: (context, constraints) => ScrollableWidget(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
        children: [ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - AppSize.spaceL * 2).clamp(0, double.infinity)
          ),
          child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WelcomeAvatar(picture: client.picture, name: client.client.name),
              SizedBox(height: AppSize.spaceM),
              TextInter(
                S.of(context).welcome_title(client.client.name),
                bold: true,
                multiplier: 3,
                textAlign: TextAlign.center
              ),
              TextMedium(
                S.of(context).welcome_subtitle,
                lines: 3,
                textAlign: TextAlign.center,
                color: ThemeColor.of(context).subtitle
              ),
              SizedBox(height: AppSize.spaceL * 2),
              for (final invitation in invitations) Padding(
                padding: EdgeInsets.only(bottom: AppSize.spaceS),
                child: InvitationCard(
                  invitation: invitation,
                  action: () => _reviewInvitation(context, invitation)
                )
              ),
              // The invitation is the answer owed; the ways to start step
              // back under it.
              if (invitations.isNotEmpty && !hasBusiness) Padding(
                padding: EdgeInsets.only(top: AppSize.spaceL, bottom: AppSize.spaceS),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextMedium(
                    S.of(context).welcome_other_ways,
                    color: ThemeColor.of(context).subtitle
                  )
                )
              ),
              if (!hasBusiness) ...[
                WelcomeOption(
                  image: "gradient-2.png",
                  icon: CI.store,
                  title: S.of(context).welcome_create_title,
                  subtitle: S.of(context).welcome_create_subtitle,
                  actionLabel: S.of(context).welcome_create_action,
                  action: () => _createBusiness(context)
                ),
                SizedBox(height: AppSize.spaceS),
                // Same height for the two, whichever description runs longest.
                IntrinsicHeight(child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: WelcomeChoice(
                      icon: CI.mail,
                      title: S.of(context).welcome_awaiting_title,
                      subtitle: S.of(context).welcome_awaiting_subtitle,
                      action: () => showModal(
                        context: context,
                        title: S.of(context).welcome_awaiting_modal_title,
                        builder: (context) => const AwaitingInvitationModal()
                      )
                    )),
                    SizedBox(width: AppSize.spaceS),
                    Expanded(child: WelcomeChoice(
                      icon: CI.employee_badge,
                      title: S.of(context).welcome_jobs_title,
                      subtitle: S.of(context).welcome_jobs_subtitle,
                      tag: S.of(context).welcome_jobs_soon,
                      action: () => showModal(
                        context: context,
                        title: S.of(context).welcome_jobs_modal_title,
                        builder: (context) => const JobOpeningsModal()
                      )
                    ))
                  ]
                ))
              ],
              SizedBox(height: AppSize.spaceL),
              _signOut(context)
            ]
          )
        )))]
      ))
    );
  }

  /// Quiet on purpose: a way out, not one more option to weigh.
  Widget _signOut(BuildContext context) => FeedbackButton(
    color: ThemeColor.of(context).surface.withAlpha(0),
    feedbackColor: ThemeColor.of(context).surface,
    action: () => context.read<ClientService>().signOut(context),
    padding: EdgeInsets.symmetric(
      vertical: AppSize.gap,
      horizontal: AppSize.spaceS
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CI.log_out, size: 16, color: ThemeColor.of(context).subtitle),
        SizedBox(width: AppSize.gap),
        TextSmall(S.of(context).sign_out, color: ThemeColor.of(context).subtitle)
      ]
    )
  );

  /// An accepted invitation always lands on the dashboard, even with other
  /// invitations still pending: the person has just picked a company to work
  /// at, and the rest can wait. `/init` is still re-read, for the new company.
  Future<void> _reviewInvitation(BuildContext context, EmploymentInvitation invitation) async {
    final accepted = await showModal(
      context: context,
      title: S.of(context).welcome_invitation_modal_title,
      builder: (context) => InvitationModal(invitation: invitation)
    );

    if (accepted != true || !context.mounted) return;

    final route = await context.read<ClientService>().resolve();
    if (!context.mounted) return;

    // Invitations still pending must not bring the person back here, but
    // anything else `resolve` answers must win over the dashboard: a failed
    // session (it already dropped the token) or another task.
    Navis.pushAndClearStack(
      context,
      route == null || route == Welcome.path ? "/home" : route
    );
  }

  /// A created company ends `business.none`: `/init` is read again so the
  /// next landing is whatever the backend says is left, not assumed to be home.
  Future<void> _createBusiness(BuildContext context) async {
    final created = await showImageModal(
      context: context,
      image: const ImageDynamic("gradient-2.png"),
      imageHeight: 160,
      fit: BoxFit.fill,
      title: S.of(context).create_business,
      builder: (context) => const CreateBusinessModal()
    );

    if (created != true || !context.mounted) return;
    await _landAfterTask(context);
  }

  Future<void> _landAfterTask(BuildContext context) async {
    final route = await context.read<ClientService>().resolve();
    if (!context.mounted) return;

    Navis.pushAndClearStack(context, route ?? "/home");
  }
}
