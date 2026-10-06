import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/business/business_profile_model.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_mark.dart';

import 'profile_logo.dart';
import 'profile_tag.dart';

/// Whose everything that follows is: the company logo and, beside it, its name
/// up large with what legal status it's in and whether it belongs to whoever is
/// looking at it.
///
/// It opens the profile because it isn't a sheet looked at out of the corner
/// of the eye: it's the title of what's being read. Placed to the side it
/// forced crossing the screen to know which company the phone being corrected
/// belonged to; placed up top it's read once and holds for everything below.
///
/// The logo is here and not in its own column for the same reason: it's the
/// other half of the same presentation —the only thing recognized without
/// reading it—, and a whole column for a single image took the width away
/// from the data, which is what does need it. It goes first because it's what's
/// recognized at a glance: you see whose sheet it is before reading the name.
///
/// It carries the name and not the rest that identifies the company —the
/// handle, the caption— because those are data and are loaded as such a few
/// lines further down (see [BusinessProfileIdentity]). Writing them here was
/// writing them twice on the same screen.
///
/// The two tags do go here even though they aren't data that get edited: they
/// change how all the rest is read. An unverified company operates with
/// limits, and whether the sheet is one or the other decides what can be done
/// with it.
class BusinessProfileHeader extends StatelessWidget {
  const BusinessProfileHeader({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Dot over the corner when the company has no logo yet (`setup.logo`).
      BadgeCorner(place: BadgePlace.logoField, dot: true, child: BusinessProfileLogo(profile: profile)),
      SizedBox(width: AppSize.padding),
      // The text takes all the width that's left over: the logo measures the
      // same always, and what breaks into several rows is the name.
      Expanded(child: _identity(context))
    ]
  );

  /// The name and, below it, how the company is: verified or not, and whose it
  /// is.
  Widget _identity(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextLarge(profile.name, lines: 2, ellipsis: true),
        SizedBox(height: AppSize.spaceXS),
        // They wrap because they're two tags of variable length: in a fixed
        // row, the second would get clipped in a narrow window.
        Wrap(
          spacing: AppSize.gap,
          runSpacing: AppSize.gap,
          children: [
            ProfileTag(
              icon: profile.verification.icon,
              label: profile.verification.label(context),
              color: profile.verification.color
            ),
            if (profile.owner) ProfileTag(
              icon: CI.user,
              label: S.of(context).business_profile_owner,
              color: scheme.primary
            )
          ]
        )
      ]
    );
  }
}
