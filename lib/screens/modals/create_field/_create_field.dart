import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Alta de una columna (campo) de una tabla, pensada al estilo de una planilla:
/// se abre desde la vista de la tabla al tocar el boton de agregar columna, pide
/// el nombre y el tipo del campo (y una descripcion opcional) y lo agrega al
/// final.
///
/// Es un modal y no una pantalla porque el formulario es corto y de tamaño fijo,
/// como el de crear la tabla. No posee el servicio: lo recibe de la pantalla que
/// lo abre ([service]), que es la dueña de la tabla abierta y de su recarga, asi
/// el alta y el refresco de la grilla pasan por el mismo lugar.
class CreateFieldModal extends StatefulWidget {
  const CreateFieldModal({super.key, required this.service});

  /// Servicio de la tabla abierta. Hace el `POST /tables/fields/` (poniendo el
  /// `TABLE_ID` y la posicion) y recarga la pagina para traer la columna nueva.
  final TableViewService service;

  @override
  State<CreateFieldModal> createState() => _CreateFieldModalState();
}

class _CreateFieldModalState extends State<CreateFieldModal> {
  final _form = FormController();

  /// Letras (con tildes y dieresis), digitos, espacios y la puntuacion que suele
  /// llevar el nombre de una columna: `Precio (IVA inc.)`, `Talla / Color`.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]";

  late final _name = InputController(
    key: "NAME",
    form: _form,
    pattern: _namePattern,
    max: 60,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).table_field_name_title),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).table_field_name_title),
      InputError.long: S.of(context).form_long_ma(S.of(context).table_field_name_title)
    }
  );

  /// Tipo del campo. El `value` de cada opcion es el codigo que viaja al backend
  /// (`TEXT`, `PRICE`, ...); las etiquetas las arma [TableFieldType].
  late final _type = InputController.select(
    key: "TYPE",
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).table_field_type_title)
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
          child: TextMedium(S.of(context).add_field_subtitle)
        ),
        Input(
          title: S.of(context).table_field_name_title,
          placeholder: S.of(context).table_field_name_placeholder,
          controller: _name,
          leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon)
        ),
        SelectInput(
          title: S.of(context).table_field_type_title,
          placeholder: S.of(context).table_field_type_placeholder,
          emptyText: S.of(context).table_field_type_empty,
          controller: _type,
          options: TableFieldType.options(context)
        ),
        Input(
          title: S.of(context).table_description_title,
          placeholder: S.of(context).table_description_placeholder,
          controller: _description,
          leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).add_field,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    widget.service.addField(
      context,
      name: _name.value,
      description: _description.value,
      type: _type.value
    ).then((ok) {
      if (!mounted) return;
      _form.loading.value = false;
      if (!ok) return;

      // El error, si lo hubo, ya lo mostro el servicio; aca solo se cierra y se
      // avisa el alta.
      FloatFlag.of(context).message(S.of(context).field_added);
      Navigator.pop(context);
    });
  }
}
