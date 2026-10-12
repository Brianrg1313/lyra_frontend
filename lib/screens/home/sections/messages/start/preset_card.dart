import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_preset.dart';

/// One ready-made channel: its network, what connecting it takes, and a short
/// exchange of the kind it will bring to this desk — a customer's message and
/// the assistant's answer, drawn with the desk's own bubble fills so the card
/// reads as a preview of what lands here.
///
/// [action] null draws it disabled with the "soon" caption: a network the
/// catalog has and this app cannot configure yet.
class PresetCard extends StatelessWidget {
  const PresetCard({super.key, required this.preset, required this.action});

  final ChannelPreset preset;
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final (ask, answer) = preset.sample(context);
    final enabled = action != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: StartCardFrame(
        action: action,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(preset.icon, size: AppSize.text * 1.2, color: enabled ? scheme.primary : scheme.text.secondary),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextMedium(preset.title(context), bold: true, ellipsis: true)),
              if (!enabled) TextSmall(S.of(context).channel_preset_soon, color: scheme.text.secondary)
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(preset.needs(context), color: scheme.text.secondary, lines: 2, ellipsis: true),
            // The exchange sits at the bottom, so cards of one row line up on it.
            const Spacer(),
            SizedBox(height: AppSize.spaceS),
            _Bubble(text: ask, fill: scheme.background, end: false),
            SizedBox(height: AppSize.gap * 0.5),
            _Bubble(text: answer, fill: scheme.primary.withValues(alpha: 0.14), end: true)
          ]
        )
      )
    );
  }
}

/// Starting from nothing: the create panel, empty.
class BlankPresetCard extends StatelessWidget {
  const BlankPresetCard({super.key, required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return StartCardFrame(
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(CI.plus, size: AppSize.text * 1.2, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(S.of(context).channel_preset_blank, bold: true, ellipsis: true))
          ]),
          SizedBox(height: AppSize.gap),
          TextSmall(S.of(context).channel_preset_blank_hint, color: scheme.text.secondary, lines: 3, ellipsis: true)
        ]
      )
    );
  }
}

/// The frame both cards share.
class StartCardFrame extends StatelessWidget {
  const StartCardFrame({super.key, required this.action, required this.child});

  final void Function()? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    mouseCursor: action == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
    color: ThemeColor.of(context).surfaceOver,
    radius: AppSize.corner,
    padding: EdgeInsets.all(AppSize.spaceS),
    child: child
  );
}

/// A message of the sample exchange: the customer's on the left, the
/// assistant's on the right, as in the open chat.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fill, required this.end});

  final String text;
  final Color fill;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final bubble = Flexible(child: Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
      ),
      child: TextSmall(text, lines: 2, ellipsis: true)
    ));

    // A margin on the far side keeps the two apart the way a chat does.
    final margin = SizedBox(width: AppSize.spaceL);

    return Row(
      mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: end ? [margin, bubble] : [bubble, margin]
    );
  }
}
