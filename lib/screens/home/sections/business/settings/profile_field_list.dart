import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A group's data, one below the other and separated by a line.
///
/// The separation is wider than that of any list because each datum is no
/// longer a single row: they're three —name, explanation and value— and packed
/// against one another they stop reading as distinct data.
class ProfileFieldList extends StatelessWidget {
  const ProfileFieldList({super.key, required this.fields});

  final List<Widget> fields;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < fields.length; i++) ...[
        if (i > 0) Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
        ),
        fields[i]
      ]
    ]
  );
}
