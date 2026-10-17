import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/inventory/table_template.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Creating a product table. Replaces the old creation sub-page: now the table
/// is created with its header (title, description and color) in a single
/// request. If a template rubric was chosen (`Blank template` is the one that
/// sends none), the backend builds its columns there itself: the frontend
/// neither knows nor creates columns on its own.
///
/// It is a modal and not a screen because the form is short and fixed-size.
/// It is opened from the inventory section (`InventorySection`) and from the production
/// line's supplies tab, which, when it closes with the new table's id, reload their tables
/// and open that one.
///
/// **The kind** (`cocina-frontend.md` §2) is the opener's when it gives one ([kind]: the
/// production line makes supplies, never asked); the inventory lists products and made
/// products together, so there it is asked, a catalog unless picked. The backend never lets
/// it change.
class CreateTableModal extends StatefulWidget {
  const CreateTableModal({super.key, this.kind});

  /// What the table holds; `null` asks between a catalog and made products.
  final TableKind? kind;

  @override
  State<CreateTableModal> createState() => _CreateTableModalState();
}

class _CreateTableModalState extends State<CreateTableModal> {
  final _form = FormController();

  /// Letters (with accents and diaeresis), digits, spaces and the punctuation
  /// a table name usually carries: `Price (VAT inc.)`, `Size / Color`.
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

  /// Optional description: without `obligatory`, only the length is validated.
  late final _description = InputController(
    key: "DESCRIPTION",
    form: _form,
    max: 240,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).table_description_title)
    }
  );

  /// Chosen template. Starts on [TableTemplate.blank], which brings no columns:
  /// choosing a template is never mandatory to create a table.
  late final _template = InputController.select(
    key: "TEMPLATE",
    form: _form,
    initial: TableTemplate.blank
  );

  /// What the table holds when it is asked ([CreateTableModal.kind] null).
  late final _kind = InputController.select(
    key: "KIND",
    form: _form,
    initial: TableKind.catalog.name
  );

  TableKind get _picked => widget.kind ?? TableKind.from(_kind.value);

  /// The create request asks for a header color even though the form no longer
  /// asks for one, so it travels fixed: any red, literal Flutter ARGB (`0x`
  /// plus 8 hex digits, alpha first), which is the only format accepted.
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
          child: TextMedium(widget.kind == TableKind.supplies ? S.of(context).table_kind_supplies_note : S.of(context).create_table_subtitle)
        ),
        if (widget.kind == null) SelectInput(
          title: S.of(context).table_kind_title,
          placeholder: S.of(context).table_kind_catalog,
          emptyText: S.of(context).table_template_empty,
          controller: _kind,
          searchable: false,
          options: [
            SelectOption(
              value: TableKind.catalog.name,
              placeholder: S.of(context).table_kind_catalog,
              subtitle: S.of(context).table_kind_catalog_note,
              icon: CI.product
            ),
            SelectOption(
              value: TableKind.made.name,
              placeholder: S.of(context).table_kind_made,
              subtitle: S.of(context).table_kind_made_note,
              icon: CI.fire_sqaure
            )
          ]
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
      .then((id) {
        if (!mounted) return;
        _form.loading.value = false;
        FloatFlag.of(context).message(S.of(context).table_created);
        // The id goes back to whoever opened it, which opens the new table.
        Navigator.pop(context, id);
      })
      .catchError((_) {
        // The error was already shown in the service; here the button is
        // simply released.
        if (!mounted) return;
        _form.loading.value = false;
      });
  }

  /// Request body. The texts are read from the controllers; the color is the
  /// fixed one from [_color]. If a template rubric was chosen its code is
  /// sent, and it is the backend that creates its columns along with the table.
  Map<String, dynamic> _payload() => createTableRequest(
    title: _title.value,
    description: _description.value,
    color: _color,
    template: _template.value == TableTemplate.blank ? null : _template.value,
    kind: _picked
  );
}