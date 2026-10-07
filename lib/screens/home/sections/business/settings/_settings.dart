import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_notes.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

import 'profile_details.dart';

/// Settings tab: how the company is configured. Today that's its profile
/// —who it is, how it operates, how it's contacted— which is what
/// `GET /business/profile/` answers, in a single top-to-bottom column.
///
/// It's called settings and not profile because it's where the company is
/// **changed**, not where it's looked at: the profile is all there is to
/// configure for now, but what comes next —who can do what, how it invoices,
/// what it notifies— goes here and not in a new tab. Hence the widgets inside
/// staying named `profile_*`: they're the profile's, which is one of the
/// settings.
///
/// It starts with the header —the logo, and beside it the name up large with
/// the legal status and the role of whoever is looking— and continues with the
/// data one by one, grouped by what they answer.
///
/// There is no separate column for the logo: it was a whole column taken up by
/// a single image, and that width is what the data needs, since the data is
/// what gets read. Placed next to the name, what identifies the company is read
/// once and in the same place, at any window width.
///
/// The profile isn't fetched here: the page fetches it on mount, because the
/// name it brings is the header's and it's seen from any of the tabs (see
/// `BusinessDetailSection`). This one just watches how it comes in.
///
/// It brings no surface of its own: the page's is the body's, and this tab is
/// one of its contents. The ones that are surfaces are the cards inside
/// ([Surface.over]): one per data group. They're blocks on that sheet, not
/// another sheet.
class BusinessSettingsTab extends StatelessWidget {
  const BusinessSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();
    final profile = service.profile;

    return switch (service.profileStatus) {
      BusinessProfileStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).business_profile_error_title,
        subtitle: S.of(context).business_profile_error_subtitle,
        action: () => service.loadProfile(force: true),
        actionLabel: S.of(context).business_list_retry
      ),
      BusinessProfileStatus.ready when profile != null => ScrollableWidget(
        showBar: false,
        children: [
          // What is missing here, in words, before the sheet: the tab's dot led here.
          BadgeNotes(
            place: BadgePlace.businessSettings,
            padding: EdgeInsets.fromLTRB(AppSize.padding, AppSize.padding, AppSize.padding, 0)
          ),
          BusinessProfileDetails(profile: profile)
        ]
      ),
      _ => const Center(child: Loading())
    };
  }
}
