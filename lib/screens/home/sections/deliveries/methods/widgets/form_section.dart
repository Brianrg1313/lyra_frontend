import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One part of the own delivery's form: what it asks, one line on how it is
/// read, and the control under them. The parts are told apart by the space
/// between them and not by rules or boxes, so the panel reads as one form.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final note = this.note;

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextSmall(title, bold: true),
          if (note != null) ...[
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(note, lines: 3, color: ThemeColor.of(context).text.secondary)
          ],
          SizedBox(height: AppSize.spaceXS),
          child
        ]
      )
    );
  }
}
