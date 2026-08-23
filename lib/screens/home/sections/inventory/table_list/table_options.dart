import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/inventory/table_settings/_table_settings.dart';
import 'package:app/screens/modals/rename_table/_rename_table.dart';

/// El boton de las opciones de una tabla en el listado, con el desplegable que
/// despliega. Lo usan las dos formas del listado: la fila del telefono
/// ([TableListRow]) y la tarjeta del escritorio ([TableCard]).
///
/// Es un widget aparte y no un metodo de la fila por dos motivos. El primero es
/// que el desplegable se cuelga **de el**: se ancla al contexto de quien lo
/// abre, y ese tiene que ser el boton y no la fila entera, o se abriria desde
/// el borde izquierdo. El segundo es que la fila y la tarjeta son el mismo
/// listado dibujado de dos maneras, y las opciones de una tabla no cambian
/// porque cambie el ancho de la ventana.
///
/// Ofrece las tres cosas que se le pueden hacer a una tabla sin abrirla:
///
/// - **Renombrarla**, que es lo unico de su cabecera que se lee desde aca.
/// - **Abrir sus ajustes**, que es todo lo demas: la descripcion, las columnas,
///   los canales y las fechas.
/// - **Eliminarla**.
///
/// Renombrar y configurar son lo mismo visto de cerca y de lejos, y por eso son
/// dos opciones y no una: cambiarle el nombre a una tabla es un campo y un
/// Enter, y mandarlo a la ficha entera para eso seria cambiar de pantalla para
/// escribir una palabra.
class TableOptionsButton extends StatelessWidget {
  const TableOptionsButton({super.key, required this.table});

  final TableLiteModel table;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => _open(context),
    width: AppSize.action,
    height: AppSize.action,
    color: ThemeColor.of(context).surfaceOver,
    message: S.of(context).table_options,
    child: Center(child: Icon(
      CI.dots_horizontal,
      size: AppSize.text * 1.2,
      color: ThemeColor.of(context).icon
    ))
  );

  /// Abre el desplegable anclado al boton. Sin buscador y sin la medida de un
  /// formulario ([dense]): son tres opciones, no una lista.
  Future<void> _open(BuildContext context) async {
    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        SelectOption(
          value: "rename",
          placeholder: S.of(context).rename_table,
          icon: CI.edit
        ),
        SelectOption(
          value: "settings",
          placeholder: S.of(context).table_settings_title,
          icon: CI.setting
        ),
        SelectOption(
          value: "delete",
          placeholder: S.of(context).delete_table,
          icon: CI.trash
        )
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "rename":
        await _rename(context);
      case "settings":
        await _settings(context);
      case "delete":
        await _delete(context);
    }
  }

  /// Abre el modal del nombre. Lo que cambie lo guarda el propio modal contra el
  /// servicio, que corrige la fila del listado: aca no queda nada por hacer
  /// cuando se cierra.
  Future<void> _rename(BuildContext context) => showModal(
    context: context,
    title: S.of(context).rename_table,
    builder: (BuildContext context) => RenameTableModal(table: table)
  );

  /// Abre los ajustes de la tabla: todo lo que hay de ella menos sus filas.
  ///
  /// Es el mismo panel que abre el boton de ajustes de la planilla, y se llega
  /// sin pasar por ella: cambiarle el tipo a una columna o mirar que canales
  /// leen la tabla no necesita cargar sus registros. Al cerrarlo se vuelve al
  /// listado tal cual estaba, que es lo que el panel deja ver a su lado.
  Future<void> _settings(BuildContext context) =>
    showTableSettings(context, table.id);

  /// Elimina la tabla, previa confirmacion.
  ///
  /// Se pregunta aca y no en el servicio porque lo que se lleva la baja no cabe
  /// en el listado: la tabla, sus columnas y todo lo cargado en ellas. El aviso
  /// nombra la tabla para que no se confirme sobre la fila equivocada.
  Future<void> _delete(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).table_delete_title,
      message: S.of(context).table_delete_message(table.title),
      confirmText: S.of(context).delete_table,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // El aviso se arma **antes** de la baja: cuando esta salga bien, esta fila
    // ya no va a existir —el listado se repinta sin ella— y su contexto no
    // servira ni para leer el texto.
    final message = S.of(context).table_deleted;

    final deleted = await context.read<TablesService>().remove(context, table);

    // Si fallo, el error ya se mostro en el servicio y la tabla sigue en el
    // listado, que es lo que corresponde: no se elimino nada.
    if (!deleted) return;

    // Sin contexto: el de la fila se desmonto con ella. La bandera flotante se
    // cuelga del navegador, que sigue ahi.
    FloatFlag.of().message(message);
  }
}
