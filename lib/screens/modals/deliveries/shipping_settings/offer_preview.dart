import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipping_settings_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **What a customer would be told today**: the options the bot writes when a
/// delivery's payment is approved (`GET /shipments/offer`), as the customer
/// reads them, and the franjas of each day ahead with how many still have
/// room. It is measured, so it answers whether the settings below do what
/// was meant.
class OfferPreview extends StatelessWidget {
  const OfferPreview({super.key, required this.service, required this.hasHours});

  final ShippingSettingsService service;

  /// Whether the branch has any opening hours: without them there is nothing
  /// to cut, and the preview says so instead of "full".
  final bool hasHours;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final error = service.slotsError;
    final days = <String, List<DeliverySlot>>{};

    for (final slot in service.slots) {
      (days[slot.day] ??= []).add(slot);
    }

    Widget line(String text, {Color? color, bool bold = false}) => Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap * 0.5),
      child: TextSmall(text, lines: 3, color: color, bold: bold)
    );

    return SettingsBlock(
      title: s.shipping_offer_title,
      subtitle: s.shipping_offer_subtitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (error != null)
          line(error.isEmpty ? s.shipping_offer_error : error, color: scheme.chart.critical)
        else if (!hasHours)
          line(s.shipping_offer_no_hours, color: scheme.chart.warning)
        else if (service.offer.isEmpty)
          line(s.shipping_offer_none, color: scheme.chart.warning)
        else
          for (final option in service.offer) line(
            option.isRange
              ? s.shipping_offer_range(option.label, option.opens, option.closes)
              : s.shipping_offer_window(option.label, option.opens, option.closes),
            bold: true
          ),
        if (days.isNotEmpty) ...[
          SizedBox(height: AppSize.gap),
          for (final entry in days.entries) line(
            s.shipping_offer_day(
              entry.key,
              entry.value.length,
              entry.value.where((slot) => !slot.full).length
            ),
            color: scheme.text.secondary
          )
        ]
      ])
    );
  }
}
