import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

// WIDGETS
import 'package:core/form.dart';

import './delivery_meeting_field.dart';

/// What holds for every delivery, being written beside one method: whether
/// the areas are fixed or flexible, and the company's own note.
///
/// Company-wide (`/business/delivery/`), not the option's, so it is drafted
/// apart and saved only when it changed. The note's controller belongs to
/// **no** form: the option's form validates its own fields, and this one is
/// free text that is never refused.
class DeliveryGeneralDraft {
  DeliveryGeneralDraft(BusinessDeliveryModel delivery)
    : meeting = delivery.meeting,
      notes = InputController(key: "NOTES_GENERAL", initial: delivery.notes, max: 255);

  bool meeting;
  final InputController notes;

  void dispose() => notes.dispose();
}

/// The block under a method's own fields: where it delivers (drawn on the
/// map; fixed or flexible) for a local reach, and the delivery note always.
///
/// Titled as what it is —for all deliveries— so changing it on one method is
/// not read as changing only that one.
class DeliveryGeneralBlock extends StatelessWidget {
  const DeliveryGeneralBlock({
    super.key,
    required this.draft,
    required this.reach,
    required this.onMeeting,
    required this.onArea
  });

  final DeliveryGeneralDraft draft;

  /// The method's reach so far; the areas only hold for a local one.
  final DeliveryCoverage? reach;

  final void Function(bool value) onMeeting;

  /// Closes the panel onto the areas, on the desk under it.
  final void Function() onArea;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Separator.horizontal(),
          SizedBox(height: AppSize.spaceS),
          TextMedium(S.of(context).deliveries_method_general, bold: true),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            S.of(context).deliveries_method_general_note,
            lines: 2,
            color: scheme.text.secondary
          ),
          if (reach == DeliveryCoverage.local) ...[
            SizedBox(height: AppSize.spaceS),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextSmall(S.of(context).deliveries_method_area, bold: true),
                  TextSmall(
                    S.of(context).deliveries_method_area_note,
                    lines: 2,
                    color: scheme.text.secondary
                  )
                ]
              )),
              SizedBox(width: AppSize.gap),
              FeedbackButton(
                action: onArea,
                height: AppSize.button,
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
                radius: AppSize.corner,
                color: scheme.surfaceOver,
                feedbackColor: scheme.line,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CI.globe_shopping, size: AppSize.text * 0.9, color: scheme.icon),
                    SizedBox(width: AppSize.gap * 0.75),
                    TextSmall(S.of(context).deliveries_method_area_open, bold: true)
                  ]
                )
              )
            ]),
            SizedBox(height: AppSize.spaceS),
            TextSmall(S.of(context).business_delivery_meeting_note, lines: 2),
            SizedBox(height: AppSize.gap),
            DeliveryMeetingField(value: draft.meeting, onChanged: onMeeting)
          ],
          SizedBox(height: AppSize.spaceS),
          Input(
            title: S.of(context).business_delivery_notes,
            placeholder: S.of(context).business_delivery_notes_hint,
            controller: draft.notes,
            leftIcon: Icon(CI.chat, color: scheme.icon)
          ),
          TextSmall(
            S.of(context).business_delivery_notes_note,
            lines: 2,
            color: scheme.text.secondary
          )
        ]
      )
    );
  }
}
