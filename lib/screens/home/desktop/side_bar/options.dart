import 'package:flutter/material.dart' hide SearchBar;
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';

import 'package:app/screens/home/sections/_sections.dart';

import './option.dart';
import './search_bar.dart';

/// [active] es la seccion abierta, ya resuelta en `Home` desde
/// [Navis.currentKey] (una sub-pagina se refleja en la seccion que la
/// contiene). Cada opcion se marca comparandose contra ella.
List<Widget> options(BuildContext context, HomeSection active, bool isExpanded) => [
  SearchBar(isExpanded: isExpanded),
  Sp(isExpanded),
  ...HomeSection.main.map((section) => _option(context, section, active, isExpanded)),
  Sp(isExpanded),
  ...HomeSection.tools.map((section) => _option(context, section, active, isExpanded))
];

Widget _option(BuildContext context, HomeSection section, HomeSection active, bool isExpanded) => Option(
  key: ValueKey(section.key),
  icon: section.icon,
  title: section.title(context),
  isExpanded: isExpanded,
  isActive: section == active,
  action: () => context.read<HomeService>().goTo(context, section)
);

class Sp extends StatelessWidget {
  const Sp(this.isExpanded, {super.key});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return Padding(
        padding: EdgeInsets.only(
          top: AppSize.spaceS,
          left: AppSize.padding * 2
        ),
        child: TextSmall("Main"),
      );
    } else {
      return Separator.horizontal(
        margin: EdgeInsets.all(AppSize.padding)
      );
    }
  }
}
