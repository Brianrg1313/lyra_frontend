import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/badges/badges_service.dart';

import 'badge_mark.dart';
import 'badge_title.dart';

/// What [place] has pending, **in words**, one line each, loudest first: the dot that led here
/// said that something is missing, this says what. A page puts it on top so nobody has to hunt
/// for the row with the mark. Nothing at all when the place is clear.
class BadgeNotes extends StatelessWidget {
  const BadgeNotes({super.key, required this.place, this.padding = EdgeInsets.zero});

  final BadgePlace place;

  /// Around the notes, only when there are some: a clear page keeps no empty gap.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: BadgesService(),
    builder: (context, _) {
      final service = BadgesService();
      final badges = [
        for (final key in service.at(place).badges) ?service.state.byKey(key)
      ]..sort((a, b) => b.level.index.compareTo(a.level.index));

      if (badges.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < badges.length; i++) ...[
              if (i > 0) SizedBox(height: AppSize.gap),
              _note(context, badgeTitle(context, badges[i]), badgeColor(context, badges[i].level))
            ]
          ]
        )
      );
    }
  );

  /// Tinted with the level's colour, so the line and the dot read as the same thing.
  Widget _note(BuildContext context, String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap)),
      border: Border.all(color: color.withValues(alpha: .4))
    ),
    child: Row(children: [
      Icon(CI.info, size: AppSize.text, color: color),
      SizedBox(width: AppSize.spaceXS),
      Expanded(child: TextMedium(text))
    ])
  );
}
