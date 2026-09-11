import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A block of a connection's form: its title, a line explaining what it's
/// for, and what's chosen or written below it.
///
/// They're three different things —what the account is called, which service
/// it belongs to, and which credentials it logs in with— and without
/// separating them it reads like a list of loose fields. The subtitle isn't
/// decorative: none of the three explains itself with its title alone, and the
/// credentials one least of all.
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
