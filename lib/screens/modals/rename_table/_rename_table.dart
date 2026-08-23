import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Le cambia el nombre a una tabla de productos, y nada mas.
///
/// Es un formulario de un solo campo porque el titulo es lo unico de la
/// cabecera que se corrige mirando el listado: es lo que se lee de la tabla
/// cuando todavia no se entro en ella. El resto de lo que se puede cambiar —la
/// descripcion, los tipos de las columnas, cuanto ve el modelo— se cambia en
/// los ajustes de la tabla, que es la otra opcion del mismo menu
/// ([TableOptionsButton]).
///
/// Es la diferencia con [EditTableDetailsModal], el formulario de un campo de
/// esos ajustes: aquel escribe contra `PUT /tables/details/` el dato que se
/// toco en la ficha, y este escribe el titulo contra la estructura
/// ([TablesService.edit]), que es de donde sale el listado.
///
/// La descripcion viaja igual aunque no se muestre: el endpoint de la
/// estructura reescribe la cabecera entera, asi que mandarla vacia seria
/// borrarla (ver `editTableRequest`).
///
/// Se cierra devolviendo `true` cuando el cambio entro, para que quien lo abrio
/// sepa que hubo uno. La fila del listado no necesita hacer nada con eso: el
/// servicio ya la corrigio.
class RenameTableModal extends StatefulWidget {
  const RenameTableModal({super.key, required this.table});

  final TableLiteModel table;

  @override
  State<RenameTableModal> createState() => _RenameTableModalState();
}

class _RenameTableModalState extends State<RenameTableModal> {
  final _form = FormController();

  /// El mismo juego de caracteres que acepta el alta: es el mismo nombre de
  /// tabla, escrito en otro momento.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]";

  /// Ancho del formulario. Fijo y no un maximo, igual que el de la ficha: el
  /// modal se ajusta a lo que mide su contenido, y un titulo corto lo dejaria
  /// mas angosto que su propio boton. En ventana chica el dialogo lo recorta
  /// solo.
  static const double _width = 400;

  late final _title = InputController(
    key: "TITLE",
    form: _form,
    initial: widget.table.title,
    pattern: _namePattern,
    min: 3,
    max: 60,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).table_title_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).table_title_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).table_title_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).table_title_input)
    }
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextMedium(S.of(context).rename_table_subtitle)
        ),
        Input(
          title: S.of(context).table_title_input,
          placeholder: S.of(context).table_title_placeholder,
          controller: _title,
          leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
          autofocus: true,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    // Nada que guardar: se cierra sin escribir. Una escritura para dejar el
    // titulo como estaba es un viaje al backend que no cambia nada.
    if (_title.value.trim() == widget.table.title.trim()) {
      Navigator.pop(context);
      return;
    }

    _form.loading.value = true;

    final saved = await context.read<TablesService>().edit(
      context,
      widget.table,
      title: _title.value,
      description: widget.table.description
    );

    if (!mounted) return;

    _form.loading.value = false;

    // Si fallo, el error ya se mostro en el servicio: el modal se queda abierto
    // con lo escrito para corregirlo o cerrarlo a mano.
    if (!saved) return;

    FloatFlag.of(context).message(S.of(context).table_renamed);
    Navigator.pop(context, true);
  }
}
