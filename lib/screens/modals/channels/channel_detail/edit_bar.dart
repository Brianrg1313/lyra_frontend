import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// Confirm and cancel, at the foot of the channel's panel.
///
/// **It is not there until there is something to confirm.** A save button
/// permanently parked under a form that nobody touched is a button that means
/// nothing when it is pressed, and worse, one that has to be pressed before
/// closing "just in case". Appearing is what says a change is pending; the
/// line above it says so in words, because the bar sliding into view is easy
/// to miss when the eye is on the field that was just typed in.
///
/// It goes below the scroll and not inside it, so a change made in the first
/// block does not have to be scrolled down to be confirmed.
///
/// Cancel is not the destructive one of the two despite undoing work: it puts
/// the form back to what the channel already holds, which is exactly what
/// closing the panel would do anyway. That is why it is the quiet one and the
/// save is the filled one.
class ChannelEditBar extends StatelessWidget {
  const ChannelEditBar({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave
  });

  final ChannelFormController controller;
  final void Function() onCancel;
  final void Function() onSave;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: controller.dirty,
    builder: (context, dirty, _) => dirty
      ? _bar(context)
      : const SizedBox.shrink()
  );

  Widget _bar(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(children: [
      Separator.horizontal(
        margin: EdgeInsets.only(top: AppSize.spaceS, bottom: AppSize.spaceS)
      ),
      Row(children: [
        Icon(CI.info, size: AppSize.text, color: scheme.accent),
        SizedBox(width: AppSize.gap),
        Expanded(child: TextSmall(
          S.of(context).channel_changes_pending,
          lines: 2,
          ellipsis: true,
          color: scheme.text.secondary
        ))
      ]),
      SizedBox(height: AppSize.spaceXS),
      Row(children: [
        // While the save is in transit cancel is locked: reverting the form
        // under a write that is already on its way would leave the screen
        // showing the old values and the backend holding the new ones.
        Expanded(child: ValueListenableBuilder<bool>(
          valueListenable: controller.saving,
          builder: (context, saving, _) => FeedbackButton(
            action: saving ? null : onCancel,
            height: AppSize.button,
            message: S.of(context).cancel,
            radius: AppSize.cornerInset(AppSize.gap),
            color: scheme.surfaceOver,
            child: Center(child: TextSmall(
              S.of(context).cancel,
              color: saving ? scheme.text.secondary : scheme.text.primary
            ))
          )
        )),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Button(
          title: S.of(context).save,
          loading: controller.saving,
          action: onSave
        ))
      ])
    ]);
  }
}
