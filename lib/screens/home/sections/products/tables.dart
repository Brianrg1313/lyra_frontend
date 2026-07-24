import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/widgets/button.dart';
import 'package:app/screens/modals/create_table/_create_table.dart';

/// Tablas de productos: es el contenido de la seccion `products` del home.
///
/// Misma estructura que la lista de empresas: barra de busqueda arriba con las
/// acciones a la derecha (importar y crear) y el listado debajo. El listado sale
/// de [TablesService], que lee `GET /tables/list/` de la empresa activa.
class ProductTablesSection extends StatefulWidget {
  const ProductTablesSection({super.key});

  @override
  State<ProductTablesSection> createState() => _ProductTablesSectionState();
}

class _ProductTablesSectionState extends State<ProductTablesSection> {
  final _search = InputController.search();
  String _query = "";

  // El controlador no se libera aca: [SearchInput] es dueno de liberarlo porque
  // `InputController.search()` crea su propio form (`controlledByInput`).
  // Liberarlo tambien aca lo desecharia dos veces (FocusNode usado tras dispose)
  // al desmontar la seccion.

  @override
  void initState() {
    super.initState();
    // La carga notifica a los oyentes; se difiere al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// Pide las tablas de la empresa activa. El servicio cachea por empresa, asi
  /// que esta llamada no vuelve a pegarle al backend si ya estan cargadas.
  void _load({bool force = false}) => context.read<TablesService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();

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
          _ImportButton(action: _import),
          SizedBox(width: AppSize.padding),
          SizedBox(
            width: AppSize.action * 4,
            child: Button(
              title: S.of(context).create_table,
              leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
              action: _create
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

  Widget _body(BuildContext context, TablesService service) => switch (service.status) {
    TablesStatus.loading || TablesStatus.idle => const Center(child: Loading()),
    TablesStatus.error => _Message(
      icon: CI.info,
      title: S.of(context).product_tables_error_title,
      subtitle: S.of(context).product_tables_error_subtitle,
      action: () => _load(force: true),
      actionLabel: S.of(context).product_tables_retry
    ),
    TablesStatus.empty => _Message(
      icon: CI.list,
      title: S.of(context).product_tables_empty_title,
      subtitle: S.of(context).product_tables_empty_subtitle,
      action: _create,
      actionLabel: S.of(context).create_table
    ),
    TablesStatus.ready => _list(context, service.tables)
  };

  Widget _list(BuildContext context, List<TableLiteModel> tables) {
    final filtered = _query.isEmpty
      ? tables
      : tables.where((t) => t.title.toLowerCase().contains(_query)).toList();

    if (filtered.isEmpty) {
      return _Message(
        icon: CI.search,
        title: S.of(context).product_tables_search_empty
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
      itemBuilder: (context, index) => _TableRow(table: filtered[index])
    );
  }

  /// Abre el modal de alta. La tabla se crea vacia (titulo, descripcion y
  /// color); al cerrarse el modal se recarga el listado para mostrarla.
  ///
  /// Si se creo una tabla, [TablesService.create] dejo la cache en `idle` y la
  /// recarga la repuebla; si se cancelo, la cache sigue `ready` y [_load]
  /// retorna sin pegarle al backend. La seccion no se desmonta al abrir el modal
  /// (queda por detras), asi que nadie mas dispararia esta recarga.
  Future<void> _create() async {
    await showModal(
      context: context,
      title: S.of(context).create_table,
      builder: (BuildContext context) => const CreateTableModal()
    );

    if (mounted) _load();
  }

  // Todavia sin pantalla: la importacion se engancha aca cuando exista.
  void _import() {}
}

/// Fila de una tabla: el icono, el titulo con la cantidad de columnas y, si la
/// tiene, la descripcion. Al tocarla abre la vista de la tabla y sus datos
/// (`/home/products/:id`).
class _TableRow extends StatelessWidget {
  const _TableRow({required this.table});

  final TableLiteModel table;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => Navis.push(context, "/home/products/${table.id}"),
    color: ThemeColor.of(context).surfaceOver,
    padding: EdgeInsets.all(AppSize.spaceS),
    child: Row(children: [
      Container(
        width: AppSize.action,
        height: AppSize.action,
        decoration: BoxDecoration(
          color: ThemeColor.of(context).surfaceOver,
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: Center(child: Icon(
          CI.list,
          size: AppSize.text * 1.2,
          color: ThemeColor.of(context).icon
        ))
      ),
      SizedBox(width: AppSize.spaceS),
      Expanded(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(child: TextMedium(table.title, ellipsis: true, bold: true)),
            SizedBox(width: AppSize.spaceS),
            TextSmall(
              S.of(context).table_field_count(table.fields),
              color: ThemeColor.of(context).text.secondary
            )
          ]),
          if (table.description.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              table.description,
              ellipsis: true,
              color: ThemeColor.of(context).text.secondary
            )
          ]
        ]
      ))
    ])
  );
}

/// Accion secundaria de la barra: importar una tabla ya existente. Es un
/// [FeedbackButton] y no un [Button] para que no compita visualmente con la
/// accion principal de crear.
class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    height: AppSize.action,
    color: ThemeColor.of(context).surfaceOver,
    padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
    message: S.of(context).import_table,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.file_upload_outlined,
          size: AppSize.text * 1.2,
          color: ThemeColor.of(context).icon
        ),
        SizedBox(width: AppSize.gap),
        TextMedium(S.of(context).import_table)
      ]
    )
  );
}

/// Estado a pantalla completa (vacio o busqueda sin resultados) con un icono,
/// un mensaje y una accion opcional.
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
