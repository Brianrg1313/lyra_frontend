import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The 24 recovery words, numbered, three to a row: the order matters when they are typed back.
/// Selectable, so they can be copied into a password manager.
class RecoveryWords extends StatelessWidget {
  const RecoveryWords({super.key, required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      color: scheme.surface,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Column(children: [
        for (var row = 0; row < words.length; row += 3) Row(children: [
          for (var i = row; i < row + 3 && i < words.length; i++) Expanded(child: Padding(
            padding: EdgeInsets.all(AppSize.gap * 0.5),
            child: Row(children: [
              SizedBox(width: 24, child: TextSmall("${i + 1}", color: scheme.subtitle)),
              Expanded(child: TextMedium(words[i], bold: true, selectable: true))
            ])
          ))
        ])
      ])
    );
  }
}
