import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/desktop/_body.dart';
import 'package:app/screens/home/sections/_sections.dart';

/// Shell del home. Cada seccion entra por su propia URL (`/home/...`) pero
/// todas comparten esta unica pagina: al cambiar de seccion el arbol se
/// actualiza en vez de recrearse, por lo que el side bar conserva su estado
/// (scroll incluido) y no se apila un shell por seccion visitada.
///
/// Por eso la seccion no llega por constructor: el `Navigator` cachea el widget
/// de la pagina y no lo reconstruye al actualizarla. La fuente es
/// [Navis.currentKey].
class Home extends PageBuilder {
  const Home({super.key});

  /// Identificador del shell compartido por las rutas de las secciones.
  static const String shell = "home";

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: Navis.currentKey,
    builder: (context, currentKey, _) {
      // Una sub-pagina no es una seccion, pero vive dentro de una: se muestra
      // la seccion que la contiene para que el shell siga siendo coherente.
      final section = HomeSection.byKey(currentKey)
        ?? HomeSection.containing(currentKey)
        ?? HomeSection.dashboard;

      // La seccion resuelta marca la opcion del side bar; el contenido puede ser
      // el de la seccion o el de una sub-pagina suya (p. ej. el perfil de una
      // empresa dentro de `business`).
      final content = homeContent(currentKey, section);

      return DeviceSelector(
        phone: (context) => _HomeBody(content: content),
        desktop: (context) => DesktopBody(section: section, content: content)
      );
    }
  );
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: content
  );
}
