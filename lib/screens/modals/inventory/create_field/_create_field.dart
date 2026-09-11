import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Creating a column (field) of a table, in the style of a spreadsheet: it
/// opens from the table view when the add-column button is touched, asks for
/// the name and type of the field (and an optional description) and adds it at
/// the end.
///
/// It is a modal and not a screen because the form is short and fixed-size,
/// like the one that creates the table. It does not own the service: it gets it
/// from the screen that opens it ([service]), which owns the open table and its
/// reload, so the create and the grid refresh go through the same place.
class CreateFieldModal extends StatefulWidget {
  const CreateFieldModal({super.key, required this.service});

  /// Service of the open table. It does the `POST /inventory/products/builder/fields/` (sending the
  /// `TABLE_ID` and the position) and reloads the page to bring in the new column.
  final TableViewService service;

  @override
  State<CreateFieldModal> createState() => _CreateFieldModalState();
}

class _CreateFieldModalState extends State<CreateFieldModal> {
  final _form = FormController();

  /// Letters (with accents and diaeresis), digits, spaces and the usual
  /// punctuation a column name carries: `Price (VAT inc.)`, `Size / Color`.
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

  /// Field type. The `value` of each option is the code that travels to the
  /// backend (`TEXT`, `PRICE`, ...); the labels are built by [TableFieldType].
  late final _type = InputController.select(
    key: "TYPE",
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).table_field_type_title)
    }
  );

  /// Optional description: without `obligatory`, only the length is validated.
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
          options: TableFieldType.menu(context)
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

      // The error, if any, was already shown by the service; here it only
      // closes and announces the create.
      FloatFlag.of(context).message(S.of(context).field_added);
      Navigator.pop(context);
    });
  }
}