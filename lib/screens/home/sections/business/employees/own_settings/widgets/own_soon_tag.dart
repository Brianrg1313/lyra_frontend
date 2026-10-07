import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// "Coming soon", as the tag of a whole block or group.
class OwnSoonTag extends StatelessWidget {
  const OwnSoonTag({super.key});

  @override
  Widget build(BuildContext context) =>
    SettingsTag(label: S.of(context).account_soon, color: ThemeColor.of(context).text.secondary);
}
