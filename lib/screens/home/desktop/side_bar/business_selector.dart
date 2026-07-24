import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_model.dart';

// WIDGETS
import 'package:core/buttons.dart';
import 'package:core/form/style.dart';
import 'package:app/screens/modals/create_business/_create_business.dart';

class BusinessSelector extends StatefulWidget {
  const BusinessSelector({super.key, required this.isExpanded});

  final bool isExpanded;

  @override
  State<BusinessSelector> createState() => _BusinessSelectorState();
}

class _BusinessSelectorState extends State<BusinessSelector> {
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _portal = OverlayPortalController();

  bool _showing = false;
  int _highlighted = -1;

  /// Ancho minimo del desplegable: con el sideBar plegado el ancla es un
  /// circulo de `AppSize.action` y la lista quedaria ilegible si lo siguiera.
  double get _minWidth => AppSize.action * 5.5;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSize.padding, AppSize.spaceS,
        AppSize.padding, AppSize.spaceXS
      ),
      child: service.hasBusiness
        ? _selectBusiness(context, service)
        : _createBusiness(context)
    );
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
        height: AppSize.action,
        action: _toggle,
        padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
        child: _current(context, service.active)
      )
    )
  );

  /// `isExpanded` cambia de golpe pero el ancho del sideBar se anima: durante
  /// esos frames el ancla sigue siendo estrecha. El texto va en un Expanded y
  /// se comprime, pero el chevron mide lo que mide y desbordaria, asi que la
  /// fila expandida se decide por el ancho real, igual que en [SignOut].
  Widget _current(BuildContext context, BusinessModel business) => LayoutBuilder(
    builder: (context, constraints) {
      final hasRoom = widget.isExpanded
        && constraints.maxWidth >= AppSize.action * 2;

      return Row(
        children: [
          _BusinessAvatar(business: business),
          if (hasRoom) ...[
            Expanded(child: Padding(
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
            AnimatedRotation(
              turns: _showing ? 0.5 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ThemeColor.of(context).text.secondary
              )
            )
          ]
        ]
      );
    }
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
            decoration: _surface(context),
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
        _BusinessAvatar(business: business),
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
          Icons.check,
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

  /// `FormStyle.dropdown` tira su sombra con `scheme.shadow`, que es un color
  /// opaco muy cercano al de la propia superficie: sobre el sideBar no separa
  /// nada. Se sustituye por una sombra negra que si despega el desplegable.
  Decoration _surface(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final base = FormStyle.dropdown(context) as BoxDecoration;

    return base.copyWith(boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(scheme.isLight ? 45 : 130),
        offset: Offset(0, 6),
        blurRadius: 24
      )
    ]);
  }

  /// Se recalcula en cada build del overlay, asi el desplegable reacciona al
  /// plegado del sideBar y a los cambios de tamano de la ventana.
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

    // Baja salvo que no quepa y arriba haya mas sitio; en el sideBar el ancla
    // esta al fondo, asi que casi siempre sube.
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

  /// Mismo problema que en [_current]: `isExpanded` cambia de golpe y el ancho
  /// del sideBar se anima detras, asi que hay que mirar el ancho real.
  ///
  /// Aqui el umbral no puede ser `AppSize.action * 2` como en [_current] o en
  /// [SignOut]: esos comprimen su texto con un Expanded, pero la fila interna de
  /// [Button] es intrinseca (icono + titulo sin flex), asi que desborda a
  /// cualquier ancho menor del que pide. Se espera al ancho expandido final.
  Widget _createBusiness(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final hasRoom = widget.isExpanded
        && constraints.maxWidth >= _expandedContentWidth;

      if (hasRoom) {
        return Button(
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          title: S.of(context).create_business,
          action: () => _openCreateModal(context)
        );
      }

      return FeedbackButton(
        width: AppSize.action,
        height: AppSize.action,
        color: ThemeColor.of(context).button.fill,
        feedbackColor: ThemeColor.of(context).button.fill.withAlpha(200),
        action: () => _openCreateModal(context),
        child: Center(child: Icon(CI.plus, color: ThemeColor.of(context).button.text))
      );
    }
  );

  /// Ancho util dentro del sideBar expandido, descontando el padding de esta
  /// fila. Con medio pixel de margen para no depender de que la animacion
  /// aterrice exacta en el ultimo frame.
  double get _expandedContentWidth =>
    HomeService.expandedWidth - (AppSize.padding * 2) - 0.5;

  void _openCreateModal(BuildContext context) => showModal(
    context: context,
    title: S.of(context).create_business,
    builder: (BuildContext context) => CreateBusinessModal()
  );
}

/// Las empresas no traen imagen desde `/init`, asi que el avatar es el mismo
/// gradiente que usa [ProfileCard] con la inicial del nombre encima.
class _BusinessAvatar extends StatelessWidget {
  const _BusinessAvatar({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSize.action - AppSize.spaceXS,
    height: AppSize.action - AppSize.spaceXS,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSize.action),
      border: Border(
        top: BorderSide(color: Colors.white.withAlpha(40)),
        left: BorderSide(color: Colors.white.withAlpha(40))
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(50),
          Colors.white.withAlpha(0)
        ])
    ),
    child: Center(child: business.name.isEmpty
      ? Icon(CI.store, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon)
      : TextMedium(business.name.characters.first.toUpperCase()))
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
