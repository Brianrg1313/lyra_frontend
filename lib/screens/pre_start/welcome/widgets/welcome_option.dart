import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/images.dart';

/// The page's main way to start, full width: the only card that carries a
/// gradient, so the eye lands on it before the quieter [WelcomeChoice]s.
class WelcomeOption extends StatelessWidget {
  const WelcomeOption({
    super.key,
    required this.image,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.action
  });

  /// Asset name under `assets/images/<dark|light>/` (`ImageDynamic`).
  final String image;
  final IconData icon;
  final String title;
  final String subtitle;

  /// The verb of the button at the card's side. The whole card does the same
  /// thing; the button is there so the card reads as actionable.
  final String actionLabel;
  final VoidCallback action;

  /// A fixed band rather than the image's ratio: full width, the 16:10
  /// gradient would take most of the window.
  static const _imageHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      width: double.infinity,
      color: scheme.surface,
      feedbackColor: scheme.surfaceOver,
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flush with the card's edges, so only its top corners follow the
          // card's radius.
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.corner)),
            child: SizedBox(
              width: double.infinity,
              height: _imageHeight,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: ImageDynamic(image)
              )
            )
          ),
          Padding(
            padding: EdgeInsets.all(AppSize.spaceM),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, size: 18, color: scheme.text.primary),
                    SizedBox(width: AppSize.gap),
                    Expanded(child: TextMedium(title, bold: true, ellipsis: true))
                  ]),
                  SizedBox(height: AppSize.spaceXS),
                  TextSmall(subtitle, lines: 2, ellipsis: true, color: scheme.subtitle)
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
                child: TextSmall(actionLabel, color: scheme.text.primary)
              )
            ])
          )
        ]
      )
    );
  }
}
