import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/images.dart';

/// Pin and name heading the form column of every auth page, so moving from
/// the email to the code keeps the same top edge.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ImageDynamic("l.png", height: AppSize.flag, fit: BoxFit.contain),
      SizedBox(width: AppSize.gap),
      TextInter(S.of(context).auth_brand, multiplier: 1.4, bold: true)
    ]
  );
}
