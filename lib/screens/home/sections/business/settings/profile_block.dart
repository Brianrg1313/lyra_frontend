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

/// A group of data with its title, on its own surface.
///
/// The surface is a block **over** the body's sheet ([Surface.over]) and not
/// another sheet: what separates is one data group from the next, not one
/// screen from another.
class ProfileBlock extends StatelessWidget {
  const ProfileBlock({
    super.key,
    required this.title,
    required this.fields,
    this.action
  });

  final String title;
  final List<Widget> fields;

  /// What can be done with the whole group and not with one of its data (adding
  /// an email). It goes in the title because it doesn't belong to any row.
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: TextSmall(
          title,
          color: ThemeColor.of(context).text.secondary
        )),
        ?action
      ]),
      SizedBox(height: AppSize.spaceS),
      ProfileFieldList(fields: fields)
    ]
  );
}
