import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/business/edit_business_email/_edit_business_email.dart';

import './profile_text_action.dart';

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
