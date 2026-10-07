import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './profile_field_list.dart';

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
