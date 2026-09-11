import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';

/// Deleting the company: the last thing on the sheet, and the only one that
/// can't be undone.
///
/// It goes at the end and not up top with the rest of the actions for the same
/// reason something you don't want to read first is written at the end of a
/// letter: it isn't a datum to correct, it's the end of everything else.
/// Whoever goes in to change the phone number doesn't run into it.
///
/// The warning goes **above** the button, not in the confirming modal: what's
/// lost and how long it takes to be lost is what makes the decision, and in
/// the modal it would arrive once the decision was already made. The modal only
/// asks again.
///
/// Only the owner sees it. It's the only thing on the sheet shown based on who
/// is looking: the rest reads the same from any role, but a company is deleted
/// by whoever created it.
class BusinessProfileDanger extends StatelessWidget {
  const BusinessProfileDanger({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final danger = scheme.snackBar.error;

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextSmall(
            S.of(context).business_delete_section,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: AppSize.gap),
                child: Icon(CI.info, size: AppSize.text, color: danger)
              ),
              SizedBox(width: AppSize.spaceXS),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // What it takes and when: those are the two questions that
                  // whoever is about to tap the button asks, and in that order.
                  TextMedium(S.of(context).business_delete_warning, lines: 4),
                  SizedBox(height: AppSize.gap),
                  TextSmall(
                    S.of(context).business_delete_schedule,
                    lines: 4,
                    color: scheme.text.secondary
                  ),
                  SizedBox(height: AppSize.spaceS),
                  _button(context, scheme, danger)
                ]
              ))
            ]
          )
        ]
      )
    );
  }

  /// The button isn't painted all red: on a sheet meant for reading, a block of
  /// color draws the eye before any datum. The red is where it needs to be —the
  /// text and the icon— and the background only lights up when you point at it.
  Widget _button(BuildContext context, SchemeColor scheme, Color danger) =>
    Align(alignment: Alignment.centerLeft, child: FeedbackButton(
      action: () => _confirm(context),
      height: AppSize.button,
      message: S.of(context).business_delete_action,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: danger.withValues(alpha: 0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.trash, size: AppSize.text, color: danger),
          SizedBox(width: AppSize.gap),
          TextSmall(S.of(context).business_delete_action, color: danger)
        ]
      )
    ));

  /// Asks again, with the company's name inside: it's the only thing that tells
  /// this one apart from the client's others, and what has to be recognized
  /// before accepting.
  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).business_delete_confirm_title,
      message: S.of(context).business_delete_confirm_message(profile.name),
      confirmText: S.of(context).business_delete_action,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // The backend still has nothing for it: there's no company deletion
    // endpoint nor, therefore, the two deadlines the warning promises —those
    // are set by the deletion process, not this screen—. It warns instead of
    // leaving the button mute, like the panels missing from the top bar, and
    // when it exists the only thing that changes here is this line for the
    // service call.
    FloatFlag.of(context).message(S.of(context).coming_soon);
  }
}
