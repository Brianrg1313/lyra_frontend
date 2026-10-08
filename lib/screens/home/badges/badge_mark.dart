import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/badges/badges_service.dart';

/// The colour of a badge level: blue for information, yellow for a warning, red for what is
/// critical — the state colours the charts already use, so "needs attention" reads the same
/// everywhere.
///
/// Info is not the app's own colour: `primary` is white in the dark theme, and a white dot only
/// says "something", never what kind of something. The charts' first series is blue in both.
Color badgeColor(BuildContext context, BadgeLevel level) {
  final chart = ThemeColor.of(context).chart;

  return switch (level) {
    BadgeLevel.critical => chart.critical,
    BadgeLevel.warning => chart.warning,
    _ => chart.at(0)
  };
}

/// What [place] has pending, drawn: a number when something in it counts things (chats
/// waiting, tickets open), a dot when it is only alerts or news, whose 1 says nothing. Nothing at
/// all when the place is clear.
///
/// The number is always a red circle whatever the level: a count of things waiting is the call
/// to act, and a fixed diameter keeps `99+` from stretching it into a pill (the text shrinks
/// instead). The dot keeps the level's colour.
///
/// [dot] forces the dot where a number does not fit (a collapsed side bar, a tab).
class BadgeMark extends StatelessWidget {
  const BadgeMark({super.key, required this.place, this.dot = false});

  final BadgePlace place;
  final bool dot;

  /// Above this the bubble says `99+`: the exact number is the page's to show.
  static const _max = 99;

  /// It listens to the singleton itself rather than through `provider`: it is drawn inside the
  /// side bar, the tabs and the forms, and none of them should have to know where it reads from.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BadgesService(),
    builder: (context, _) => _mark(context, BadgesService())
  );

  Widget _mark(BuildContext context, BadgesService badges) {
    final anchor = badges.at(place);

    if (anchor.isEmpty) return const SizedBox.shrink();

    final color = badgeColor(context, anchor.level);

    if (dot || !anchor.counts(badges.state)) {
      return Container(
        width: AppSize.gap * 1.6,
        height: AppSize.gap * 1.6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)
      );
    }

    return Container(
      width: AppSize.corner,
      height: AppSize.corner,
      padding: EdgeInsets.all(AppSize.gap / 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: ThemeColor.of(context).chart.critical, shape: BoxShape.circle),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: TextSmall(anchor.count > _max ? "$_max+" : "${anchor.count}", color: Colors.white)
      )
    );
  }
}

/// The mark of one row a side bar number counts: a conversation with messages this person has not
/// read, a sale they have not opened. The same red as the number, so the rows it points at are
/// found by looking for its colour.
class UnseenMark extends StatelessWidget {
  const UnseenMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: AppSize.gap * 1.8,
    height: AppSize.gap * 1.8,
    decoration: BoxDecoration(color: ThemeColor.of(context).chart.critical, shape: BoxShape.circle)
  );
}

/// [child] with [place]'s mark on its top-right corner: an icon button, an avatar.
class BadgeCorner extends StatelessWidget {
  const BadgeCorner({super.key, required this.place, required this.child, this.dot = false, this.outside = false});

  final BadgePlace place;
  final Widget child;
  final bool dot;

  /// Hangs the mark off the corner instead of inside it: a bare icon is too small to hold it.
  final bool outside;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      child,
      Positioned(
        top: outside ? -AppSize.gap / 2 : AppSize.gap / 2,
        right: outside ? -AppSize.gap / 2 : AppSize.gap / 2,
        child: IgnorePointer(child: BadgeMark(place: place, dot: dot))
      )
    ]
  );
}
