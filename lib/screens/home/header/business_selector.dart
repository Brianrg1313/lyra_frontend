import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form/style.dart';
import 'package:app/screens/home/sections/business/business_avatar.dart';
import 'package:app/screens/modals/create_business/_create_business.dart';

/// Empresa activa y cambio de empresa. Vive en el header y no en el side bar
/// porque lo que se elige aca manda sobre todo lo que se ve: cambiarla vuelve a
/// montar la seccion abierta con los datos de la elegida.
///
/// Se mide por su contenido: ocupa lo que ocupe el nombre de la empresa activa.
/// Quien lo coloca ([HomeHeader]) solo le pone un techo, para que un nombre
/// largo no se coma la barra entera.
class BusinessSelector extends StatefulWidget {
  const BusinessSelector({super.key});

  @override
  State<BusinessSelector> createState() => _BusinessSelectorState();
}

class _BusinessSelectorState extends State<BusinessSelector> {
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _portal = OverlayPortalController();

  bool _showing = false;
  int _highlighted = -1;

  /// Ancho minimo del desplegable: el ancla muestra una empresa y la lista
  /// muestra todas, cada una con su nombre y su descripcion, asi que seguir al
  /// ancla la dejaria demasiado angosta para leerla.
  double get _minWidth => AppSize.action * 5.5;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();

    return service.hasBusiness
      ? _selectBusiness(context, service)
      : _createBusiness(context);
  }

  // -- Ancla --

  /// Muestra la empresa activa y despliega la lista al pulsarla.
  Widget _selectBusiness(BuildContext context, BusinessService service) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => _dropdown(context, service),
    child: CompositedTransformTarget(
      link: _link,
      child: FeedbackButton(
        key: _anchor,
        action: _toggle,
        color: ThemeColor.of(context).input.fill,
        height: AppSize.action,
        radius: AppSize.cornerInset(AppSize.gap),
        padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
        child: _current(context, service.active)
      )
    )
  );

  /// La fila se mide por lo que hay adentro (`min`), asi el boton vale lo que
  /// vale el nombre y no un ancho inventado.
  ///
  /// El nombre va en un Flexible y no en un Expanded: con Expanded se quedaria
  /// con todo el techo que le da el header aunque la empresa se llame de dos
  /// letras. Suelto se mide por el texto, y solo se recorta con puntos
  /// suspensivos cuando el nombre no entra en ese techo; el avatar y el chevron
  /// miden lo que miden.
  Widget _current(BuildContext context, BusinessModel business) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _avatar(business),
      Flexible(child: Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(business.name, ellipsis: true),
            if (business.caption.isNotEmpty)
              TextSmall(business.caption, ellipsis: true)
          ])
      )),
      SizedBox(
        width: AppSize.button,
        child: AnimatedRotation(
          turns: _showing ? 0.5 : 0,
          duration: const Duration(milliseconds: 150),
          child: Icon(
            CI.arrow_down,
            color: ThemeColor.of(context).text.secondary
          )
        )
      )
    ]
  );

  /// La cara de la empresa: su logo, y si todavia no subio ninguno la inicial
  /// de su nombre. Es el mismo widget con el que se dibuja en su ficha
  /// ([BusinessAvatar]), dibujado del alto de una fila: una empresa se reconoce
  /// por la misma imagen se la mire donde se la mire.
  ///
  /// Pide la miniatura y no el archivo entero: aca ocupa lo que ocupa un icono,
  /// y el original es el que subio la empresa, con el peso que tenga.
  Widget _avatar(BusinessModel business) => BusinessAvatar(
    name: business.name,
    url: business.logo?.thumbnail,
    size: AppSize.action - AppSize.spaceXS
  );

  // -- Despliegue --

  Widget _dropdown(BuildContext context, BusinessService service) {
    final geometry = _geometry(service);
    if (geometry == null) return const SizedBox.shrink();

    return Stack(children: [
      Positioned.fill(child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close
      )),
      CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: geometry.upward ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: geometry.upward ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, geometry.upward ? -AppSize.gap : AppSize.gap),
        child: SizedBox(
          width: geometry.width,
          child: Container(
            constraints: BoxConstraints(maxHeight: geometry.maxHeight),
            decoration: FormStyle.dropdown(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.cornerInset(1)),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: AppSize.gap),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < service.businesses.length; i++)
                      _option(context, service, service.businesses[i], i),
                    Separator.horizontal(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppSize.padding,
                        vertical: AppSize.gap
                      )
                    ),
                    _createOption(context, service.businesses.length)
                  ])
              )
            )
          )
        )
      )
    ]);
  }

  Widget _option(
    BuildContext context,
    BusinessService service,
    BusinessModel business,
    int index
  ) {
    final isSelected = business.id == service.active.id;

    return _Hoverable(
      index: index,
      highlighted: _highlighted,
      onHover: (value) => setState(() => _highlighted = value),
      onTap: () {
        service.selectBusiness(business.id);
        _close();
      },
      child: Row(children: [
        _avatar(business),
        Expanded(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(business.name, ellipsis: true),
              if (business.caption.isNotEmpty)
                TextSmall(business.caption, ellipsis: true)
            ])
        )),
        if (isSelected) Icon(
          CI.check,
          size: AppSize.text * 1.2,
          color: ThemeColor.of(context).primary
        )
      ])
    );
  }

  /// [overlay] solo sirve para pintar: al pulsar se cierra el desplegable y ese
  /// contexto queda desmontado, asi que el modal se abre con el del selector.
  Widget _createOption(BuildContext overlay, int index) => _Hoverable(
    index: index,
    highlighted: _highlighted,
    onHover: (value) => setState(() => _highlighted = value),
    onTap: () {
      _close();
      _openCreateModal(context);
    },
    child: Row(children: [
      SizedBox(
        width: AppSize.action,
        child: Icon(CI.plus, color: ThemeColor.of(overlay).icon)
      ),
      SizedBox(width: AppSize.spaceXS),
      Expanded(child: TextMedium(S.of(overlay).create_business, ellipsis: true))
    ])
  );

  /// Se recalcula en cada build del overlay, asi el desplegable reacciona a los
  /// cambios de tamano de la ventana.
  _DropdownGeometry? _geometry(BusinessService service) {
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final media = MediaQuery.of(context);
    final margin = AppSize.spaceXS;

    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;

    final below = (media.size.height - margin) - bottom - AppSize.gap;
    final above = top - (media.padding.top + margin) - AppSize.gap;

    // Empresas + separador + la opcion de crear.
    final desired = (AppSize.gap * 2)
      + (_optionHeight * (service.businesses.length + 1))
      + (AppSize.gap * 2) + 1;

    // Baja salvo que no quepa y arriba haya mas sitio; en el header el ancla
    // esta arriba de todo, asi que casi siempre baja.
    final upward = below < desired && above > below;
    double available = upward ? above : below;

    if (available < AppSize.action) {
      available = math.max(above, below);
    }

    return _DropdownGeometry(
      width: math.max(box.size.width, _minWidth),
      maxHeight: math.max(math.min(desired, available), 0),
      upward: upward
    );
  }

  // -- Interaccion --

  void _toggle() => _showing ? _close() : _open();

  void _open() {
    if (_showing) return;

    setState(() {
      _showing = true;
      _highlighted = -1;
    });

    _portal.show();
  }

  void _close() {
    if (!_showing) return;

    _portal.hide();

    if (mounted) {
      setState(() {
        _showing = false;
        _highlighted = -1;
      });
    }
  }

  // -- Sin empresas --

  /// Sin ninguna empresa no hay nada que elegir, asi que en lugar del selector
  /// va el alta: es el unico camino desde el que arranca todo lo demas.
  Widget _createBusiness(BuildContext context) => Button(
    leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
    title: S.of(context).create_business,
    action: () => _openCreateModal(context)
  );

  void _openCreateModal(BuildContext context) => showModal(
    context: context,
    title: S.of(context).create_business,
    builder: (BuildContext context) => CreateBusinessModal()
  );
}

/// Alto de cada fila del desplegable, al ras del avatar. Lo comparten el
/// calculo de la geometria y las propias filas: si divergieran, el desplegable
/// se recortaria o dejaria hueco muerto al final.
double get _optionHeight => AppSize.action;

/// Fila del desplegable: resaltado al pasar el raton, con el mismo relleno que
/// las opciones de `SelectInput`.
class _Hoverable extends StatelessWidget {
  const _Hoverable({
    required this.index,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
    required this.child
  });

  final int index;
  final int highlighted;
  final void Function(int index) onHover;
  final void Function() onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHover(index),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _optionHeight,
        color: FormStyle.optionFill(context, index == highlighted),
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
        child: child
      )
    )
  );
}

class _DropdownGeometry {
  const _DropdownGeometry({
    required this.width,
    required this.maxHeight,
    required this.upward
  });

  final double width;
  final double maxHeight;
  final bool upward;
}
