import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './_sections.dart';

/// Temporary content of the sections that do not have their own screen yet.
/// As each one is built it is replaced in `HomeSection.build`.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({
    required this.section,
    super.key
  });

  final HomeSection section;

  @override
  Widget build(BuildContext context) => Center(
    child: TextLarge(section.title(context))
  );
}
