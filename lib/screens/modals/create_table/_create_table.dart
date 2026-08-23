import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/inventory/table_template.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Alta de una tabla de productos. Reemplaza a la vieja sub-pagina de creacion:
/// ahora la tabla se crea con su cabecera (titulo, descripcion y color) en una
/// sola peticion. Si se eligio un rubro de plantilla (`Blank template` es el
/// que no manda ninguno), el backend arma sus columnas ahi mismo: el front no
/// conoce ni crea columnas por su cuenta.
///
/// Es un modal y no una pantalla porque el formulario es corto y de tamaño fijo.
/// Se abre desde el listado de tablas ([InventorySection]) y, al cerrarse,
/// el listado se recarga para mostrar la tabla nueva.
class CreateTableModal extends StatefulWidget {
  const CreateTableModal({super.key});

  @override
  State<CreateTableModal> createState() => _CreateTableModalState();
}

class _CreateTableModalState extends State<CreateTableModal> {
  final _form = FormController();

  /// Letras (con tildes y dieresis), digitos, espacios y la puntuacion que
  /// suele llevar el nombre de una tabla: `Precio (IVA inc.)`, `Talla / Color`.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]";

  late final _title = InputController(
    key: "TITLE",
    form: _form,
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

  /// Descripcion opcional: sin `obligatory`, solo se valida el largo.
  late final _description = InputController(
    key: "DESCRIPTION",
    form: _form,
    max: 240,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).table_description_title)
    }
  );

  /// Plantilla elegida. Arranca en [TableTemplate.blank], que no trae columnas:
  /// elegir una plantilla nunca es obligatorio para crear una tabla.
  late final _template = InputController.select(
    key: "TEMPLATE",
    form: _form,
    initial: TableTemplate.blank
  );

  /// El alta pide un color de cabecera aunque el formulario ya no lo pregunte,
  /// asi que viaja fijo: un rojo cualquiera, literal ARGB de Flutter (`0x` mas
  /// 8 digitos hex, con el alpha adelante), que es el unico formato que acepta.
  static const _color = "0xFFF87171";

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextMedium(S.of(context).create_table_subtitle)
        ),
        Input(
          title: S.of(context).table_title_input,
          placeholder: S.of(context).table_title_placeholder,
          controller: _title,
          leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
          next: _description.focus
        ),
        Input(
          title: S.of(context).table_description_title,
          placeholder: S.of(context).table_description_placeholder,
          controller: _description,
          leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
        ),
        SelectInput(
          title: S.of(context).table_template_title,
          placeholder: S.of(context).table_template_placeholder,
          emptyText: S.of(context).table_template_empty,
          controller: _template,
          options: TableTemplate.options(context)
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).create_table,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    context.read<TablesService>().create(context, _payload())
      .then((_) {
        if (!mounted) return;
        _form.loading.value = false;
        FloatFlag.of(context).message(S.of(context).table_created);
        Navigator.pop(context);
      })
      .catchError((_) {
        // El error ya se mostro en el servicio; aca solo se suelta el boton.
        if (!mounted) return;
        _form.loading.value = false;
      });
  }

  /// Cuerpo de la peticion. Los textos se leen de los controladores; el color
  /// es el fijo de [_color]. Si se eligio un rubro de plantilla se manda su
  /// codigo, y es el backend quien crea sus columnas junto con la tabla.
  Map<String, dynamic> _payload() => createTableRequest(
    title: _title.value,
    description: _description.value,
    color: _color,
    template: _template.value == TableTemplate.blank ? null : _template.value
  );
}
