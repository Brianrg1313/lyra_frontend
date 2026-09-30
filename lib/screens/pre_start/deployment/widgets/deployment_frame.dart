import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The frame of every deployment and LAN page: a centered column, the title and subtitle, then
/// [children]. Centered while it fits the window; past that, it scrolls from the top.
class DeploymentFrame extends StatelessWidget {
  const DeploymentFrame({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.maxWidth = 440
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: LayoutBuilder(builder: (context, constraints) => ScrollableWidget(
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
      children: [ConstrainedBox(
        constraints: BoxConstraints(minHeight: (constraints.maxHeight - AppSize.spaceL * 2).clamp(0, double.infinity)),
        child: Center(child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextInter(title, multiplier: 2.2, bold: true, lines: 2),
              if (subtitle != null) Padding(
                padding: EdgeInsets.only(top: AppSize.spaceXS),
                child: TextMedium(subtitle!, lines: 5, color: ThemeColor.of(context).subtitle)
              ),
              SizedBox(height: AppSize.spaceL),
              ...children
            ]
          )
        ))
      )]
    ))
  );
}

/// A tick box with its label, for the confirmations the setup asks for (licence, recovery key).
class DeploymentCheck extends StatelessWidget {
  const DeploymentCheck({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FocusableWidget(
      action: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
        child: Row(children: [
          Icon(value ? CI.chack_circle : CI.circle, size: 20, color: value ? scheme.primary : scheme.icon),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(label, lines: 3))
        ])
      )
    );
  }
}

/// A line of quiet text under a form: an error in red, a note in the subtitle color.
class DeploymentNote extends StatelessWidget {
  const DeploymentNote(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
    child: TextSmall(
      text,
      lines: 5,
      color: error ? ThemeColor.of(context).accent : ThemeColor.of(context).subtitle
    )
  );
}
