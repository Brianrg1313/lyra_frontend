import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A block of a channel's form: its title, a line explaining what it is for
/// and what is chosen below.
///
/// The form is five different decisions —what network, what the agent does,
/// where it gets the data from, what it can process and with what credentials
/// it logs in— and without separating them it reads like a list of loose
/// fields. The subtitle is not decorative: almost none of those decisions
/// explains itself with its title alone.
class FormBlock extends StatelessWidget {
  const FormBlock({
    super.key,
    required this.title,
    required this.child,
    this.subtitle
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSize.spaceM),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextMedium(title, bold: true, ellipsis: true),
        if (subtitle != null) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            subtitle!,
            lines: 2,
            ellipsis: true,
            color: ThemeColor.of(context).text.secondary
          )
        ],
        SizedBox(height: AppSize.spaceXS),
        child
      ]
    )
  );
}
