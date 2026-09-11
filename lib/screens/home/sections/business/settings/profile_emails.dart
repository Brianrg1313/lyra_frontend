import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/modals/business/edit_business_email/_edit_business_email.dart';
import 'package:app/screens/modals/business/verify_business_email/_verify_business_email.dart';

import 'profile_field.dart';
import 'profile_tag.dart';

/// A company email address, as a row of the emails block.
///
/// The name is what the company calls it —its own, or what it's for—, the
/// explanation is what's done with it and the value the address, which can be
/// selected because it's used outside the app.
///
/// Beside the address goes whether it's verified, which is the only thing that
/// says if it **works**: an address is what someone typed in a form, and until
/// a code reaches that mailbox nobody knows whether what's sent to it arrives
/// or bounces. Both states are shown and not just the bad one: a row without a
/// tag wouldn't read as verified, it would read as incomplete.
///
/// The verify action goes next to the tag and not up top with the others: it's
/// the answer to what was just read right there, and up top promote, change
/// and delete already coexist.
///
/// The three things that can be done to it are together on top: promote it to
/// primary (only if it isn't), change it and delete it. Promoting doesn't ask
/// anything —it's a change undone by promoting another— but deleting does: the
/// address leaves with its name and its purpose.
class ProfileEmailField extends StatelessWidget {
  const ProfileEmailField({super.key, required this.email});

  final BusinessEmailModel email;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: email.purpose.icon,
    label: email.title(context),
    // What's done with this address, and not that it's an address: the list is
    // of emails, what changes from one to another is where what's written goes.
    // It holds even when the company gave it its own name ("Billing
    // Colombia"), because the name says which one it is and not what it's for.
    description: email.purpose.description(context),
    // The primary is marked up top and not by manually ordering it first: it
    // already arrives first, but that isn't visible, and which one the company
    // publishes is the first thing one comes to look at in this list.
    note: email.main ? S.of(context).business_email_main : null,
    action: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!email.main) ...[
          // Written out and not a check mark: which of the addresses the
          // company publishes is a decision, and an icon doesn't say which one
          // is being taken.
          ProfileTextAction(
            label: S.of(context).business_email_promote,
            action: () => _promote(context)
          ),
          SizedBox(width: AppSize.gap)
        ],
        ProfileAction(
          icon: CI.edit,
          message: S.of(context).business_profile_edit(
            S.of(context).business_email_address
          ),
          action: () => _edit(context)
        ),
        SizedBox(width: AppSize.gap),
        ProfileAction(
          icon: CI.trash,
          message: S.of(context).delete_business_email,
          action: () => _delete(context)
        )
      ]
    ),
    child: _value(context)
  );

  /// The address and, stuck to it, whether it was proven to arrive. They wrap
  /// because they're three things of variable length —a long address, the tag
  /// and, if verification is missing, the button— and in a fixed row the last
  /// one would get clipped.
  Widget _value(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSize.spaceXS,
    runSpacing: AppSize.gap,
    children: [
      TextMedium(email.email, lines: 2, ellipsis: true, selectable: true),
      ProfileTag(
        icon: email.verificationIcon,
        label: email.verificationLabel(context),
        color: email.verificationColor
      ),
      if (!email.verified) ProfileTextAction(
        label: S.of(context).business_email_verify,
        action: () => _verify(context)
      )
    ]
  );

  /// Opens verification. What happens inside is saved by the modal itself
  /// against the service, which re-reads the profile: nothing is left to do
  /// here when it closes.
  Future<void> _verify(BuildContext context) => showModal(
    context: context,
    title: S.of(context).business_email_verify_title,
    builder: (BuildContext context) => VerifyBusinessEmailModal(email: email)
  );

  /// Promoting doesn't announce anything on success: the primary tag moved to
  /// this row and the promote button disappeared, which is all there was to
  /// tell. The error is shown by the service.
  Future<void> _promote(BuildContext context) => context
    .read<BusinessService>()
    .editEmail(context, email.id, {"MAIN": true});

  Future<void> _edit(BuildContext context) => showModal(
    context: context,
    title: S.of(context).business_email_edit_title,
    builder: (BuildContext context) => EditBusinessEmailModal(email: email)
  );

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).business_email_delete_title,
      message: S.of(context).business_email_delete_message(email.email),
      confirmText: S.of(context).delete_business_email,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    final removed = await context.read<BusinessService>().removeEmail(
      context,
      email.id
    );

    if (!removed || !context.mounted) return;

    FloatFlag.of(context).message(S.of(context).business_email_deleted);
  }
}

/// The button to add an address, for the emails block's title.
///
/// It goes in the title and not as one more row because adding isn't a company
/// datum: it's what's done with the whole list, even when it's empty.
class ProfileEmailAdd extends StatelessWidget {
  const ProfileEmailAdd({super.key});

  @override
  Widget build(BuildContext context) => ProfileTextAction(
    label: S.of(context).business_email_add,
    action: () => showModal(
      context: context,
      title: S.of(context).business_email_add,
      builder: (BuildContext context) => const EditBusinessEmailModal()
    )
  );
}
