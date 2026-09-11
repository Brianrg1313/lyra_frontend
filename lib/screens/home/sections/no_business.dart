import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/business/create_business/_create_business.dart';

/// What is seen in a home section when the customer still has no business.
///
/// Everything that lives inside the home hangs off the active business —the
/// tables, the channels, the connections, the business itself—, so without any
/// there is nothing to ask the backend: the section is not mounted and in its
/// place goes this message with the sign-up, which is the only path from which
/// the rest starts (see `homeContent`).
///
/// The one that does not go through here is the dashboard, which is the home
/// cover page and is seen from day one. The business section does, but through
/// the other path: it is not blocked —it is exactly where the first one is
/// created— so it opens and shows this as its content, because without any
/// business there is no detail to show.
class NoBusinessSection extends StatelessWidget {
  const NoBusinessSection({super.key});

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: SectionMessage(
      icon: CI.store,
      title: S.of(context).section_no_business_title,
      subtitle: S.of(context).section_no_business_subtitle,
      action: () => showModal(
        context: context,
        title: S.of(context).create_business,
        builder: (BuildContext context) => const CreateBusinessModal()
      ),
      actionLabel: S.of(context).create_business,
      actionIcon: CI.plus
    )
  );
}
