import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// A row of the cloud account where the running mode has no cloud (a master without the
/// internet): said instead of hidden, since it is the person's and comes back with the internet.
class OwnOffline extends StatelessWidget {
  const OwnOffline({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => SettingsRow(
    icon: icon,
    label: label,
    child: TextSmall(S.of(context).account_needs_internet, lines: 2, color: ThemeColor.of(context).text.secondary)
  );
}
