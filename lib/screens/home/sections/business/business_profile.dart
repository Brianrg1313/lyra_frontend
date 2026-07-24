import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/api.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_detail_model.dart';

// WIDGETS
import 'package:core/images.dart';

/// Perfil de una empresa. Es una sub-pagina de la seccion de empresas
/// (`business_detail`, `parents: ["business"]`): se abre al tocar una fila en
/// [BusinessListSection] y muestra el detalle de esa empresa.
///
/// Cual empresa se resuelve del id en la URL (`/home/business/:id`), no por
/// constructor: la sub-pagina comparte el shell del home, que reusa una sola
/// pagina del `Navigator` y no reconstruye el arbol al navegar. El detalle sale
/// de la lista que ya cargo [BusinessService]; si se entra por deep link con la
/// lista todavia sin cargar, se dispara la carga como hace la propia seccion.
class BusinessProfileSection extends StatefulWidget {
  const BusinessProfileSection({super.key});

  /// Key de la ruta de esta sub-pagina. Es la unica fuente: la usan tanto la
  /// tabla de rutas como el shell para decidir cuando mostrarla.
  static const String routeKey = "business_detail";

  @override
  State<BusinessProfileSection> createState() => _BusinessProfileSectionState();
}

class _BusinessProfileSectionState extends State<BusinessProfileSection> {
  @override
  void initState() {
    super.initState();
    // Deep link: si se llego directo a la URL sin pasar por la lista, el detalle
    // todavia no esta en cache. Se difiere al primer frame para no notificar
    // mientras el arbol se monta, igual que en la lista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessService>().loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();
    final id = Navis.currentArgs?["id"] ?? "";
    final business = _find(service.details, id);

    return Surface(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(children: [
        _header(context, business),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.padding)
        ),
        Expanded(child: _body(context, service, business))
      ])
    );
  }

  /// Barra superior con el boton de volver a la lista y el titulo.
  Widget _header(BuildContext context, BusinessDetailModel? business) => Row(
    children: [
      FeedbackButton(
        action: _back,
        width: AppSize.action,
        height: AppSize.action,
        message: S.of(context).business,
        child: Center(child: Icon(
          Icons.arrow_back,
          color: ThemeColor.of(context).text.primary
        ))
      ),
      SizedBox(width: AppSize.spaceS),
      Expanded(child: TextMedium(
        business?.name ?? S.of(context).business,
        bold: true,
        ellipsis: true
      ))
    ]
  );

  Widget _body(
    BuildContext context,
    BusinessService service,
    BusinessDetailModel? business
  ) {
    if (business != null) return _Profile(business: business);

    // Sin detalle: mientras carga se muestra el spinner; ya cargada, la empresa
    // no existe (id invalido o fuera de la lista del cliente).
    return switch (service.status) {
      BusinessListStatus.loading || BusinessListStatus.idle =>
        const Center(child: Loading()),
      _ => _NotFound(onBack: _back)
    };
  }

  void _back() => Navis.push(context, "/home/business");

  static BusinessDetailModel? _find(List<BusinessDetailModel> list, String id) {
    for (final business in list) {
      if (business.id == id) return business;
    }
    return null;
  }
}

/// Contenido del perfil cuando la empresa existe: cabecera con logo, nombre y
/// estado, y una lista con los datos del vinculo del cliente con ella.
class _Profile extends StatelessWidget {
  const _Profile({required this.business});

  final BusinessDetailModel business;

  @override
  Widget build(BuildContext context) => ScrollableWidget(
    showBar: false,
    children: [
      Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Row(children: [
          _Logo(business: business),
          SizedBox(width: AppSize.padding),
          Expanded(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextLarge(business.name, ellipsis: true),
              SizedBox(height: AppSize.spaceXS),
              _StateDot(state: business.state)
            ]
          ))
        ])
      ),
      SizedBox(height: AppSize.padding),
      Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Column(children: [
          _Field(
            label: S.of(context).business_profile_state,
            value: business.state.label(context),
            color: business.state.color
          ),
          _Field(
            label: S.of(context).business_profile_membership,
            value: business.membership.label(context),
            color: business.membership.color
          ),
          _Field(
            label: S.of(context).business_profile_rank,
            value: business.rank.label(context)
          ),
          _Field(
            label: S.of(context).business_profile_id,
            value: business.id,
            last: true
          )
        ])
      )
    ]
  );
}

/// Logo grande de la empresa. Si no subio ninguno cae al avatar en gradiente
/// con la inicial, el mismo criterio que usa la lista y el selector.
class _Logo extends StatelessWidget {
  const _Logo({required this.business});

  final BusinessDetailModel business;

  static const double _size = 72;

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
        ? Icon(CI.store, size: AppSize.text * 1.6, color: ThemeColor.of(context).icon)
        : TextLarge(business.name.characters.first.toUpperCase()))
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

/// Fila etiqueta-valor de un dato del perfil. El valor puede pintarse con un
/// color propio (estado, vinculo) o con el color de texto por defecto.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.color,
    this.last = false
  });

  final String label;
  final String value;
  final Color? color;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: TextSmall(
        label,
        color: ThemeColor.of(context).text.secondary
      )),
      SizedBox(width: AppSize.padding),
      Flexible(child: TextMedium(
        value,
        ellipsis: true,
        textAlign: TextAlign.right,
        color: color
      ))
    ]),
    if (!last) Separator.horizontal(
      margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
    )
  ]);
}

/// Estado a pantalla completa cuando el id no corresponde a ninguna empresa de
/// la lista del cliente.
class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final void Function() onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CI.info, size: AppSize.action, color: ThemeColor.of(context).text.secondary),
        SizedBox(height: AppSize.spaceS),
        TextMedium(
          S.of(context).business_profile_not_found_title,
          bold: true,
          textAlign: TextAlign.center
        ),
        SizedBox(height: AppSize.gap),
        TextSmall(
          S.of(context).business_profile_not_found_subtitle,
          textAlign: TextAlign.center,
          color: ThemeColor.of(context).text.secondary
        )
      ]
    )
  );
}
