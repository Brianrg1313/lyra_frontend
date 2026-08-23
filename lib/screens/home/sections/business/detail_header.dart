import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import 'business_tab.dart';

/// Barra de pestanas de la pagina de una empresa.
///
/// No lleva titulo. Cual empresa es lo dice la pestana que se abre —con su
/// nombre en grande— y el selector de la barra del home, que esta siempre a la
/// vista: repetirlo aca era escribir el mismo nombre dos veces en la misma
/// pantalla y robarle el ancho a las pestanas.
///
/// Tampoco lleva un boton de volver: no hay a donde. La seccion de empresas es
/// esta pagina, la de la empresa con la que se esta trabajando; para pasar a
/// otra esta el selector del header.
///
/// **No lleva superficie.** La unica de la pagina es la del cuerpo, y la
/// pestana activa se dibuja justamente con ese color: apoyada sobre el fondo,
/// se lee como la lengueta de lo que hay abajo. Envolver la barra en su propia
/// superficie partiria la pagina en dos tarjetas sueltas y la pestana dejaria
/// de senalar nada.
///
/// No guarda cual pestana esta abierta ni sabe que hay en ella: recibe [tab] y
/// avisa por [onTab]. Quien manda es la pagina, que es la que navega.
class BusinessDetailHeader extends StatelessWidget {
  const BusinessDetailHeader({
    super.key,
    required this.tab,
    required this.onTab
  });

  /// Pestana abierta, la que se dibuja marcada.
  final BusinessTab tab;

  /// Se pidio abrir otra pestana. Es una navegacion: cada pestana es una URL
  /// (ver `BusinessDetailSection`).
  final void Function(BusinessTab tab) onTab;

  /// Las pestanas se corren en vez de encogerse: son cinco con icono y texto, y
  /// en una ventana angosta entrarian recortadas o apretadas hasta no poder
  /// leerse. Corriendolas, la que se este mirando se ve entera.
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (final value in BusinessTab.values) Padding(
        padding: EdgeInsets.only(right: AppSize.gap),
        child: _Tab(
          tab: value,
          isActive: value == tab,
          action: () => onTab(value)
        )
      )
    ])
  );
}

/// Una pestana de la barra.
///
/// La activa toma el color de la superficie del cuerpo y la inactiva el del
/// fondo. Los dos son opacos a proposito: [FeedbackButton] anima el color al
/// pasar el raton, y partir de un color translucido hace que la transicion pase
/// por valores a medio alpha —el destello que ya se evito en las opciones del
/// side bar—.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.isActive,
    required this.action
  });

  final BusinessTab tab;
  final bool isActive;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: tab.title(context),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.surface : scheme.background,
      feedbackColor: scheme.line,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab.icon,
            size: AppSize.text * 1.2,
            color: isActive ? scheme.primary : scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(
            tab.title(context),
            bold: isActive,
            multiplier: 0.95,
            color: isActive ? scheme.text.primary : scheme.text.secondary
          )
        ]
      )
    );
  }
}
