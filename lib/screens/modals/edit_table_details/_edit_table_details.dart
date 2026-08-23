import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'table_detail_field.dart';

/// Cambia **un** dato de la cabecera de una tabla desde sus ajustes.
///
/// Es un formulario de un solo campo, como el del perfil de la empresa: la
/// ficha se corrige donde se lee —se toca el renglon que esta mal y se
/// escribe— y no abriendo el formulario entero para cambiar una palabra. Lo
/// que se guarda es solo ese campo, con una escritura parcial contra
/// `PUT /tables/details/` (ver [TableDetailService.edit]).
///
/// Es la diferencia con `RenameTableModal`, que es el formulario del menu del
/// listado: ahi solo se cambia el titulo, que es lo unico de la cabecera que se
/// lee sin haber entrado a la tabla.
///
/// No sabe que dato esta editando: lo describe quien lo abre ([field]) y de
/// ahi sale todo —de donde se lee, cuanto mide, si puede quedar vacio, con que
/// clave se guarda—.
///
/// El servicio llega por constructor y no del arbol: lo posee la pantalla de
/// ajustes, que lo provee **dentro** de su pagina, y un dialogo se monta arriba
/// del `Navigator`, donde ese provider ya no esta.
class EditTableDetailsModal extends StatefulWidget {
  const EditTableDetailsModal({
    super.key,
    required this.field,
    required this.service
  });

  final TableDetailField field;

  /// De donde sale lo que hay guardado y a donde va lo que se escriba.
  final TableDetailService service;

  @override
  State<EditTableDetailsModal> createState() => _EditTableDetailsModalState();
}

class _EditTableDetailsModalState extends State<EditTableDetailsModal> {
  final _form = FormController();

  /// Lo que la tabla tenia al abrir el modal. Se guarda aparte del servicio
  /// porque con el se compara al final: si no cambio nada, no hay nada que
  /// escribir.
  late final String _initial = widget.field.value(widget.service.detail);

  /// El controlador se arma con lo que dice el dato: lo guardado abre el campo
  /// lleno y el resto —la forma, el largo, si es obligatorio— es lo que se
  /// valida al guardar.
  late final _input = InputController(
    key: "VALUE",
    form: _form,
    initial: _initial,
    pattern: widget.field.pattern,
    min: widget.field.min,
    max: widget.field.max,
    obligatory: widget.field.obligatory,
    customErrors: _errors
  );

  /// Los errores nombran el dato como lo nombra la ficha: son los mismos
  /// cuatro de siempre y lo unico que cambia es de que estan hablando.
  Map<InputError, String> get _errors {
    final label = widget.field.label(context);

    return {
      InputError.empty: S.of(context).form_empty_ma(label),
      InputError.invalid: S.of(context).form_invalid_ma(label),
      InputError.long: S.of(context).form_long_ma(label),
      InputError.incomplete: S.of(context).form_incomplete_ma(label)
    };
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Ancho del formulario. Fijo y no un maximo, como el del perfil: el modal se
  /// ajusta a lo que mide su contenido, y un campo de un titulo corto lo
  /// dejaria mas angosto que su propio boton. En ventana chica el dialogo lo
  /// recorta solo.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: widget.field.label(context),
          placeholder: widget.field.placeholder(context),
          controller: _input,
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

    // El valor se lee del controlador y no de `_form.data`: ese solo junta lo
    // que quedo escrito, y una descripcion vaciada —que es borrarla— no
    // llegaria nunca al backend.
    final value = _input.value;

    // Nada que guardar. Se cierra sin escribir: una escritura y una relectura
    // del detalle para dejar todo como estaba es peor que no hacer nada.
    if (value.trim() == _initial.trim()) {
      Navigator.pop(context);
      return;
    }

    _form.loading.value = true;

    final saved = await widget.field.save(context, widget.service, value);

    if (!mounted) return;

    _form.loading.value = false;

    // Si fallo, el error ya se mostro en el servicio: el modal se queda abierto
    // con lo escrito para corregirlo o cerrarlo a mano.
    if (!saved) return;

    // El listado de tablas tiene su propia copia de estos dos textos y no se
    // entero de nada: lo que se acaba de escribir viajo por el endpoint de los
    // ajustes. Sin esto, volver al listado mostraria el nombre viejo hasta la
    // proxima lectura entera.
    _syncList(value);

    // Sin aviso de guardado: el modal se cierra y la ficha de atras ya muestra
    // el valor nuevo. Anunciar lo que se esta viendo es una bandera que tapa
    // parte de la pantalla para contar algo que la pantalla ya conto.
    Navigator.pop(context, true);
  }

  void _syncList(String value) {
    final tables = context.read<TablesService>();
    final id = widget.service.tableId;

    switch (widget.field) {
      case TableDetailField.title:
        tables.applyText(id, title: value);
      case TableDetailField.description:
        tables.applyText(id, description: value);
    }
  }
}
