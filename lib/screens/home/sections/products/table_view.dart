import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// SCREENS
import 'package:app/screens/modals/create_field/_create_field.dart';

// WIDGETS
import 'package:core/widgets/button.dart';

/// Vista de una tabla y sus datos, pensada como una planilla: una grilla de
/// columnas y filas que se arma a mano. Es una sub-pagina de la seccion
/// `products` (`parents: ["products"]`): se abre al tocar una fila del listado
/// de tablas y comparte el shell del home, por lo que la opcion del side bar
/// sigue marcada.
///
/// La tabla crece en dos ejes, como en un Excel:
/// - **Horizontal**: el boton `+` a la derecha de los encabezados agrega una
///   columna (un campo). Abre un modal que pide nombre y tipo y hace el
///   `POST /tables/fields/`.
/// - **Vertical**: el boton de abajo agrega una fila-borrador vacia, que
///   representa un producto por cargar. Se pueden apilar varias; cada una se
///   guarda por separado con el tilde de su fila (`POST /products/manage/`).
///
/// Cual tabla se resuelve del id en la URL (`/home/products/:id`), no por
/// constructor: la sub-pagina reusa la unica pagina del shell y el `Navigator`
/// no reconstruye el arbol al navegar, asi que el id se lee de
/// [Navis.currentArgs]. Los datos salen de `GET /tables/view/<id>/<index>` y se
/// pintan con `DataTableView` de `core/tables`.
///
/// El servicio de datos ([TableViewService]) lo posee esta pantalla y no el
/// scope de la app: es estado efimero de una tabla abierta (la pagina actual),
/// que debe reiniciarse cada vez que se entra y descartarse al salir.
class TableViewSection extends StatefulWidget {
  const TableViewSection({super.key});

  /// Key de la ruta de esta sub-pagina. Es la unica fuente: la usan tanto la
  /// tabla de rutas como el shell para decidir cuando mostrarla.
  static const String routeKey = "product_table_view";

  @override
  State<TableViewSection> createState() => _TableViewSectionState();
}

class _TableViewSectionState extends State<TableViewSection> {
  // Propio de la pantalla: se crea al entrar y se libera al salir, sin pasar por
  // un provider de la app, porque su estado (la pagina abierta) no debe
  // sobrevivir a la navegacion.
  final _service = TableViewService();

  /// Filas-borrador que se estan cargando, en el orden en que se agregaron. Cada
  /// una es una fila vacia de la planilla —un producto por dar de alta— con sus
  /// propios editores y estado de guardado. Se apilan al final de la grilla,
  /// despues de las filas de datos, y se descartan al guardarse o al salir.
  final List<_Draft> _drafts = [];

  /// Alto del encabezado de la grilla. Se comparte con la barra de agregar
  /// columna para que su boton `+` quede alineado con la fila de encabezados.
  static const double _headerHeight = 44;

  @override
  void initState() {
    super.initState();
    // El id vive en la URL. La carga se difiere al primer frame para no
    // notificar mientras el arbol se monta, igual que el resto de las secciones.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.open(Navis.currentArgs?["id"] ?? "");
    });
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El titulo sale del listado que ya cargo [TablesService]; si se entro por
    // deep link con el listado sin cargar, cae a un titulo generico.
    final id = Navis.currentArgs?["id"] ?? "";
    final found = _title(context.watch<TablesService>().tables, id);
    final title = found.isNotEmpty ? found : S.of(context).product_table_view_title;

    return Surface(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(children: [
        _header(context, title),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.padding)
        ),
        Expanded(child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) => _body(context)
        ))
      ])
    );
  }

  /// Barra superior con el boton de volver al listado y el titulo de la tabla.
  Widget _header(BuildContext context, String title) => Row(children: [
    FeedbackButton(
      action: _back,
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).products,
      child: Center(child: Icon(
        Icons.arrow_back,
        color: ThemeColor.of(context).text.primary
      ))
    ),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextMedium(title, bold: true, ellipsis: true))
  ]);

  Widget _body(BuildContext context) => switch (_service.status) {
    TableViewStatus.loading || TableViewStatus.idle =>
      const Center(child: Loading()),
    TableViewStatus.error => _Message(
      icon: CI.info,
      title: S.of(context).product_table_view_error_title,
      subtitle: S.of(context).product_table_view_error_subtitle,
      action: _service.retry,
      actionLabel: S.of(context).product_tables_retry
    ),
    // Una tabla sin columnas todavia no es una planilla: no hay donde cargar
    // nada. En vez de un callejon sin salida, el estado vacio invita a crear la
    // primera columna, que es por donde se empieza a armar la tabla.
    TableViewStatus.ready || TableViewStatus.empty =>
      _service.data.columns.isEmpty
        ? _Message(
            icon: CI.list,
            title: S.of(context).product_table_view_empty_title,
            subtitle: S.of(context).table_fields_empty,
            action: _addField,
            actionLabel: S.of(context).add_field
          )
        : _table(context, _service.data)
  };

  Widget _table(BuildContext context, TableViewModel data) {
    // La grilla apila las filas de datos y, debajo, las filas-borrador que se
    // estan cargando. Se distinguen por tipo: [TableRowModel] son datos y
    // [_Draft] son borradores editables.
    final rows = <Object>[...data.rows, ..._drafts];

    return Column(children: [
      // La tabla necesita una altura acotada: el [Expanded] se la da y ella
      // virtualiza y scrollea sus filas por dentro. A su derecha, fija, la barra
      // para agregar una columna.
      Expanded(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: DataTableView<Object>(
            items: rows,
            headerHeight: _headerHeight,
            columns: [
              for (final (index, column) in data.columns.indexed)
                TableColumn<Object>(
                  // El id de la columna en la grilla es el FIELD_ID; si no vino,
                  // la posicion alcanza para que el orden y el hover funcionen.
                  id: column.id.isNotEmpty ? column.id : "col_$index",
                  title: column.name,
                  cell: (context, row, _) => row is _Draft
                    ? _editor(context, row, index, column)
                    : Text(_cell((row as TableRowModel).at(index)))
                ),
              TableColumn<Object>(
                id: "__actions",
                title: "",
                width: AppSize.action + AppSize.spaceS,
                alignment: Alignment.center,
                cell: (context, row, _) => row is _Draft
                  ? _saveButton(context, row)
                  : const SizedBox.shrink()
              )
            ]
          )),
          _addColumnBar(context)
        ]
      )),
      _footer(context)
    ]);
  }

  /// Barra fija a la derecha de la grilla con el boton de agregar una columna.
  /// El `+` se alinea con la fila de encabezados (mismo alto) para que se lea
  /// como "una columna mas al final".
  Widget _addColumnBar(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: AppSize.gap),
    child: SizedBox(
      width: AppSize.action,
      child: Column(children: [
        FeedbackButton(
          action: _addField,
          width: AppSize.action,
          height: _headerHeight,
          color: ThemeColor.of(context).surfaceOver,
          message: S.of(context).add_field,
          child: Center(child: Icon(
            CI.plus,
            color: ThemeColor.of(context).text.primary
          ))
        )
      ])
    )
  );

  /// Celda editable de una fila-borrador. Es un campo de texto crudo (sin la
  /// decoracion del [Input] del formulario, que no entra en el alto de una fila)
  /// atado al editor de su columna dentro del borrador. El teclado se ajusta al
  /// tipo del campo.
  Widget _editor(BuildContext context, _Draft draft, int index, TableColumnModel column) {
    final controller = draft.editors.putIfAbsent(index, () => TextEditingController());

    return TextField(
      controller: controller,
      keyboardType: _keyboard(column.type),
      style: TextStyle(color: ThemeColor.of(context).text.primary, fontSize: AppSize.text),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: column.name,
        hintStyle: TextStyle(color: ThemeColor.of(context).text.secondary, fontSize: AppSize.text)
      )
    );
  }

  /// Boton de confirmar de una fila-borrador: guarda esa fila como un item nuevo.
  /// Muestra un spinner mientras se manda el alta de esa fila en particular.
  Widget _saveButton(BuildContext context, _Draft draft) => ValueListenableBuilder<bool>(
    valueListenable: draft.saving,
    builder: (context, saving, _) => FeedbackButton(
      action: saving ? null : () => _saveDraft(draft),
      width: AppSize.action,
      height: AppSize.action,
      message: S.of(context).product_table_view_add_item,
      child: Center(
        child: saving
          ? SizedBox(
              width: AppSize.text,
              height: AppSize.text,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ThemeColor.of(context).primary
              )
            )
          : Icon(CI.check, color: ThemeColor.of(context).primary)
      )
    )
  );

  /// Pie con el boton de agregar una fila (izquierda) y la paginacion (derecha).
  Widget _footer(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSize.spaceS),
    child: Row(children: [
      SizedBox(
        width: AppSize.action * 4,
        child: Button(
          title: S.of(context).product_table_view_add_item,
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          action: _addRow
        )
      ),
      const Spacer(),
      TextSmall(
        S.of(context).product_table_view_page(_service.page),
        color: ThemeColor.of(context).text.secondary
      ),
      SizedBox(width: AppSize.spaceS),
      _PageButton(
        icon: Icons.chevron_left,
        message: S.of(context).product_table_view_previous,
        action: _service.canGoBack ? () => _service.previous() : null
      ),
      SizedBox(width: AppSize.gap),
      _PageButton(
        icon: Icons.chevron_right,
        message: S.of(context).product_table_view_next,
        action: _service.canGoNext ? () => _service.next() : null
      )
    ])
  );

  /// Agrega una fila-borrador vacia al final de la grilla. Sus editores se crean
  /// a demanda cuando la fila se pinta, ya con las columnas conocidas.
  void _addRow() => setState(() => _drafts.add(_Draft()));

  /// Abre el modal de alta de una columna. El modal usa el mismo [_service], que
  /// hace el `POST /tables/fields/` y recarga la pagina; la grilla se vuelve a
  /// pintar sola con la columna nueva por el [ListenableBuilder].
  void _addField() {
    showModal(
      context: context,
      title: S.of(context).add_field,
      builder: (_) => CreateFieldModal(service: _service)
    );
  }

  /// Guarda una fila-borrador como un item nuevo.
  ///
  /// Arma el `DATA` del alta indexado por FIELD_ID, salteando las celdas vacias
  /// y las columnas sin id (que no se pueden guardar). Si no se cargo nada, avisa
  /// y no pega. Al terminar bien saca el borrador de la grilla; la recarga del
  /// servicio ya lo trajo como una fila real. El error ya lo mostro el servicio.
  void _saveDraft(_Draft draft) async {
    if (draft.saving.value) return;

    final columns = _service.data.columns;

    final values = <String, dynamic>{};
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      final text = draft.editors[i]?.text.trim() ?? "";
      if (text.isEmpty || column.id.isEmpty) continue;
      values[column.id] = text;
    }

    if (values.isEmpty) {
      FloatFlag.of(context).message(S.of(context).product_table_view_empty_row);
      return;
    }

    draft.saving.value = true;
    final saved = await _service.add(context, values);
    if (!mounted) return;

    if (!saved) {
      draft.saving.value = false;
      return;
    }

    // El item quedo persistido y la recarga ya lo trae como fila real: se saca
    // el borrador de la grilla y se liberan sus recursos.
    setState(() => _drafts.remove(draft));
    draft.dispose();
    FloatFlag.of(context).message(S.of(context).product_table_view_item_added);
  }

  void _back() => Navis.push(context, "/home/products");

  /// Teclado apropiado para el tipo del campo. Los tipos numericos abren el
  /// teclado de numeros; el resto, el de texto.
  static TextInputType _keyboard(String type) => switch (type.toUpperCase()) {
    "NUMBER" || "COUNTER" || "STOCK" => TextInputType.number,
    "DECIMAL" || "PRICE" => const TextInputType.numberWithOptions(decimal: true),
    "EMAIL" => TextInputType.emailAddress,
    "PHONE" => TextInputType.phone,
    "URL" => TextInputType.url,
    "TEXTAREA" => TextInputType.multiline,
    _ => TextInputType.text
  };

  /// Formatea el valor de una celda a texto: `null` se muestra vacio y el resto
  /// con su representacion por defecto.
  static String _cell(dynamic value) => value?.toString() ?? "";

  /// Titulo de la tabla [id] segun el listado cacheado, o vacio si todavia no
  /// esta cargado (el llamador resuelve el generico).
  String _title(List<TableLiteModel> tables, String id) {
    for (final table in tables) {
      if (table.id == id && table.title.isNotEmpty) return table.title;
    }
    return "";
  }
}

/// Una fila-borrador de la planilla: la fila vacia con la que se carga un item
/// nuevo. Guarda un editor de texto por columna (indexado por posicion, creado a
/// demanda) y el estado de guardado de esa fila en particular, para que el
/// spinner del tilde afecte solo a la fila que se esta mandando.
class _Draft {
  final Map<int, TextEditingController> editors = {};
  final ValueNotifier<bool> saving = ValueNotifier(false);

  void dispose() {
    for (final controller in editors.values) {
      controller.dispose();
    }
    saving.dispose();
  }
}

/// Boton de una flecha de paginacion. Apagado (gris, sin accion) cuando [action]
/// es nulo.
class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;
  final String message;
  final void Function()? action;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    width: AppSize.action,
    height: AppSize.action,
    color: ThemeColor.of(context).surfaceOver,
    message: message,
    child: Center(child: Icon(
      icon,
      color: action == null
        ? ThemeColor.of(context).text.secondary
        : ThemeColor.of(context).text.primary
    ))
  );
}

/// Estado a pantalla completa (vacio o error) con un icono, un mensaje y una
/// accion opcional.
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
            child: Button(title: actionLabel!, action: action!)
          )
        ]
      ]
    )
  );
}
