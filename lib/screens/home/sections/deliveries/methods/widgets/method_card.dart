import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

/// One way of delivering to pick from, as a card: what it is, what it means
/// for the order, and the companies of that kind in the company's country.
///
/// A card and not a dropdown row because it is the panel's first and only
/// question: three answers read side by side, each with its sentence, are
/// picked knowingly; a closed list hides them behind a tap.
class DeliveryMethodCard extends StatelessWidget {
  const DeliveryMethodCard({
    super.key,
    required this.mode,
    required this.onPick,
    this.examples = const []
  });

  final DeliveryMode mode;
  final void Function() onPick;

  /// Brands of this kind the catalog offers in the company's country, drawn
  /// as they came. Empty for the company's own riders, or with no catalog.
  final List<String> examples;

  /// Brands named on a card: enough to recognise the kind, not a catalog.
  static const int _shown = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final shown = examples.take(_shown).join(" · ");

    return FeedbackButton(
      action: onPick,
      padding: EdgeInsets.all(AppSize.spaceS),
      radius: AppSize.corner,
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Row(children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.spaceS))
          ),
          child: Icon(mode.icon, size: AppSize.text * 1.2, color: scheme.primary)
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(deliveryMethodName(context, mode), bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(deliveryMethodNote(context, mode), lines: 2, color: scheme.text.secondary),
            if (shown.isNotEmpty) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(shown, ellipsis: true, color: scheme.primary)
            ]
          ]
        )),
        SizedBox(width: AppSize.gap),
        Icon(CI.arrow_right, size: AppSize.text, color: scheme.icon)
      ])
    );
  }
}

/// What a card calls a way of delivering. The rows of an option keep the mode's
/// own name ([DeliveryMode.label]): there it says who carries one option, here
/// it names a kind of service.
String deliveryMethodName(BuildContext context, DeliveryMode mode) => switch (mode) {
  DeliveryMode.own => S.of(context).deliveries_method_own,
  DeliveryMode.platform => S.of(context).deliveries_method_platform,
  DeliveryMode.courier => S.of(context).deliveries_method_courier
};

/// What that kind of service means for the order, in one sentence.
String deliveryMethodNote(BuildContext context, DeliveryMode mode) => switch (mode) {
  DeliveryMode.own => S.of(context).deliveries_method_own_note,
  DeliveryMode.platform => S.of(context).deliveries_method_platform_note,
  DeliveryMode.courier => S.of(context).deliveries_method_courier_note
};
