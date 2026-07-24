import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './_sections.dart';

/// Contenido temporal de las secciones que todavia no tienen pantalla propia.
/// A medida que cada una se construya se reemplaza en `HomeSection.build`.
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
