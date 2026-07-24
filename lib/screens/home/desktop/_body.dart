import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import 'package:app/screens/home/sections/_sections.dart';

import './side_bar/side_bar.dart';

class DesktopBody extends StatelessWidget {
  const DesktopBody({
    required this.section,
    required this.content,
    super.key
  });

  /// Seccion abierta, usada para marcar su opcion en el side bar. Una sub-pagina
  /// se refleja en la seccion que la contiene.
  final HomeSection section;

  /// Contenido del panel central: el de la seccion o el de su sub-pagina.
  final Widget content;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.padding),
    child: Row(children: [
      SideBar(section: section),
      SizedBox(width: AppSize.padding),
      Expanded(child: content)
    ])
  );
}
