import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/api.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_detail_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/images.dart';
import 'package:core/widgets/button.dart';
import 'package:app/screens/modals/create_business/_create_business.dart';

class BusinessListSection extends StatefulWidget {
  const BusinessListSection({super.key});

  @override
  State<BusinessListSection> createState() => _BusinessListSectionState();
}

class _BusinessListSectionState extends State<BusinessListSection> {
  final _search = InputController.search();
  String _query = "";

  @override
  void initState() {
    super.initState();
    // La carga notifica a los oyentes; se difiere al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessService>().loadDetails();
    });
  }

  // El controlador no se libera aca: [SearchInput] es dueno de liberarlo porque
  // `InputController.search()` crea su propio form (`controlledByInput`).
  // Liberarlo tambien aca lo desecharia dos veces (FocusNode usado tras dispose)
  // al desmontar la lista, por ejemplo al abrir el perfil de una empresa.

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();

    return Surface(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(children: [
        Row(children: [
          Expanded(child: SearchInput(
            placeholder: S.of(context).search,
            controller: _search,
            onSearch: (value) => setState(() => _query = value.trim().toLowerCase())
          )),
          SizedBox(width: AppSize.padding),
          SizedBox(
            width: AppSize.action * 4,
            child: Button(
              title: S.of(context).create_business,
              leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
              action: _openCreateModal
            )
          )
        ]),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.padding)
        ),
        Expanded(child: _body(context, service))
      ])
    );
  }

  Widget _body(BuildContext context, BusinessService service) => switch (service.status) {
    BusinessListStatus.loading || BusinessListStatus.idle => const Center(child: Loading()),
    BusinessListStatus.error => _Message(
      icon: CI.info,
      title: S.of(context).business_list_error_title,
      subtitle: S.of(context).business_list_error_subtitle,
      action: () => service.loadDetails(force: true),
      actionLabel: S.of(context).business_list_retry
    ),
    BusinessListStatus.empty => _Message(
      icon: CI.store,
      title: S.of(context).business_list_empty_title,
      subtitle: S.of(context).business_list_empty_subtitle,
      action: _openCreateModal,
      actionLabel: S.of(context).create_business
    ),
    BusinessListStatus.ready => _list(context, service.details)
  };

  Widget _list(BuildContext context, List<BusinessDetailModel> businesses) {
    final filtered = _query.isEmpty
      ? businesses
      : businesses.where((b) => b.name.toLowerCase().contains(_query)).toList();

    if (filtered.isEmpty) {
      return _Message(
        icon: CI.search,
        title: S.of(context).business_list_search_empty
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
      itemBuilder: (context, index) => _BusinessRow(business: filtered[index])
    );
  }

  // Al cerrar el modal se recarga el detalle. Si se creo una empresa,
  // [createBusiness] dejo la cache en `idle` y esta llamada la repuebla; si se
  // cancelo, la cache sigue en `ready` y `loadDetails` retorna sin pegarle al
  // backend. Es necesario porque la seccion no se desmonta al abrir el modal
  // (queda por detras), asi que no basta con invalidar la cache: nadie mas
  // dispararia la recarga.
  Future<void> _openCreateModal() async {
    await showModal(
      context: context,
      title: S.of(context).create_business,
      builder: (BuildContext context) => const CreateBusinessModal()
    );

    if (mounted) context.read<BusinessService>().loadDetails();
  }
}

/// Fila de una empresa: logo, nombre y rango a la izquierda; a la derecha el
/// vinculo del cliente (distintivo) y el estado operativo de la empresa.
class _BusinessRow extends StatelessWidget {
  const _BusinessRow({required this.business});

  final BusinessDetailModel business;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => Navis.push(context, "/home/business/${business.id}"),
    color: ThemeColor.of(context).surfaceOver,
    padding: EdgeInsets.all(AppSize.spaceS),
    child: Row(children: [
      _BusinessLogo(business: business),
      SizedBox(width: AppSize.spaceS),
      Expanded(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextMedium(business.name, ellipsis: true, bold: true),
          SizedBox(height: AppSize.gap),
          _StateDot(state: business.state)
        ]
      )),
      SizedBox(width: AppSize.spaceS),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Badge(
            label: business.membership.label(context),
            color: business.membership.color
          ),
          SizedBox(height: AppSize.gap),
          TextSmall(
            business.rank.label(context),
            color: ThemeColor.of(context).text.secondary
          )
        ]
      )
    ])
  );
}

/// Logo de la empresa. Si no subio ninguno cae al mismo avatar en gradiente con
/// la inicial que usa el selector del side bar.
class _BusinessLogo extends StatelessWidget {
  const _BusinessLogo({required this.business});

  final BusinessDetailModel business;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final logo = business.logo;

    if (logo != null) {
      return CacheImage(
        api: assets,
        image: logo,
        width: _size,
        height: _size,
        radius: AppSize.corner
      );
    }

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(40)),
          left: BorderSide(color: Colors.white.withAlpha(40))
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(50), Colors.white.withAlpha(0)]
        )
      ),
      child: Center(child: business.name.isEmpty
        ? Icon(CI.store, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon)
        : TextMedium(business.name.characters.first.toUpperCase(), bold: true))
    );
  }
}

/// Punto de color + etiqueta del estado operativo de la empresa.
class _StateDot extends StatelessWidget {
  const _StateDot({required this.state});

  final BusinessState state;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: AppSize.gap,
        height: AppSize.gap,
        decoration: BoxDecoration(color: state.color, shape: BoxShape.circle)
      ),
      SizedBox(width: AppSize.gap),
      Flexible(child: TextSmall(
        state.label(context),
        ellipsis: true,
        color: ThemeColor.of(context).text.secondary
      ))
    ]
  );
}

/// Distintivo del vinculo del cliente con la empresa (activo, restringido,
/// pendiente): texto sobre un relleno tenue del color del estado.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.spaceXS,
      vertical: AppSize.gap / 2
    ),
    decoration: BoxDecoration(
      color: color.withAlpha(38),
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: TextSmall(label, color: color)
  );
}

/// Estado a pantalla completa (vacio, error o busqueda sin resultados) con un
/// icono, un mensaje y una accion opcional.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final void Function()? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSize.action, color: ThemeColor.of(context).text.secondary),
        SizedBox(height: AppSize.spaceS),
        TextMedium(title, bold: true, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          SizedBox(height: AppSize.gap),
          TextSmall(
            subtitle!,
            textAlign: TextAlign.center,
            color: ThemeColor.of(context).text.secondary
          )
        ],
        if (action != null && actionLabel != null) ...[
          SizedBox(height: AppSize.spaceM),
          SizedBox(
            width: AppSize.action * 4,
            child: Button(
              title: actionLabel!,
              leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
              action: action!
            )
          )
        ]
      ]
    )
  );
}
