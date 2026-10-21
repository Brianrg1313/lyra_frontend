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
import 'package:app/screens/modals/shared/option_tile.dart';

/// Creating a product table. Replaces the old creation sub-page: now the table
/// is created with its header (title, description and color) in a single
/// request. If a template rubric was chosen (`Blank template` is the one that
/// sends none), the backend builds its columns there itself: the frontend
/// neither knows nor creates columns on its own.
///
/// It is a modal and not a screen because the form is short and fixed-size.
/// It is opened from the inventory (`InventoryTables`) and the menu (`MenuSection`), which,
/// when it closes with the new table's id, reload their tables and open that one.
///
/// **The kind** (`cocina-frontend.md` §2): the menu's is fixed ([kind] `made`, never asked);
/// the inventory lists products and supplies together, so it passes none and the form asks
/// between the two, saying it can't be changed afterwards — the backend never lets it change,
/// since a supply's stock is kept in millionths of its unit.
///
/// A menu is spoken of as a menu (its name's examples, «Create menu») and picks what it starts
/// with between two tiles, [TableTemplate.blank] or [TableTemplate.made], instead of the
/// catalog's template list.
class CreateTableModal extends StatefulWidget {
  const CreateTableModal({super.key, this.kind});

  /// What the table holds; `null` asks between [TableKind.catalog] and [TableKind.supplies].
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

  /// The create request asks for a header color even though the form no longer
  /// asks for one, so it travels fixed: any red, literal Flutter ARGB (`0x`
  /// plus 8 hex digits, alpha first), which is the only format accepted.
  static const _color = "0xFFF87171";

  /// The kind picked, or the opener's.
  late TableKind _kind = widget.kind ?? TableKind.catalog;

  bool get _menu => _kind == TableKind.made;

  /// What a menu starts with ([TableTemplate.blank] or [TableTemplate.made]).
  String _start = TableTemplate.blank;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _menu || widget.kind == null ? 440 : 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.kind == null) ...[
            TextMedium(s.create_table_kind, bold: true),
            SizedBox(height: AppSize.spaceXS),
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final kind in const [TableKind.catalog, TableKind.supplies]) ...[
                if (kind == TableKind.supplies) SizedBox(width: AppSize.spaceS),
                Expanded(child: OptionTile(
                  title: kind == TableKind.supplies ? s.table_kind_supplies : s.table_kind_catalog,
                  note: kind == TableKind.supplies ? s.table_kind_supplies_note : s.table_kind_catalog_note,
                  selected: _kind == kind,
                  action: () => setState(() => _kind = kind)
                ))
              ]
            ])),
            Padding(
              padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceS),
              child: TextSmall(s.create_table_kind_fixed, lines: 2, color: ThemeColor.of(context).text.secondary)
            )
          ] else Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextMedium(switch (_kind) {
              TableKind.supplies => s.table_kind_supplies_note,
              TableKind.made => s.menu_create_note,
              TableKind.catalog => s.create_table_subtitle
            })
          ),
          Input(
            title: s.table_title_input,
            placeholder: _menu ? s.menu_create_name_placeholder : s.table_title_placeholder,
            controller: _title,
            leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
            next: _description.focus
          ),
          Input(
            title: s.table_description_title,
            placeholder: _menu ? s.menu_create_description_placeholder : s.table_description_placeholder,
            controller: _description,
            leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
          ),
          if (_menu) ...[
            SizedBox(height: AppSize.spaceS),
            TextMedium(s.menu_create_start, bold: true),
            SizedBox(height: AppSize.spaceXS),
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final start in [TableTemplate.blank, TableTemplate.made]) ...[
                if (start == TableTemplate.made) SizedBox(width: AppSize.spaceS),
                Expanded(child: OptionTile(
                  title: start == TableTemplate.made ? s.menu_create_details : s.menu_create_blank,
                  note: start == TableTemplate.made ? s.menu_create_details_note : s.menu_create_blank_note,
                  selected: _start == start,
                  action: () => setState(() => _start = start)
                ))
              ]
            ]))
          ] else SelectInput(
            title: s.table_template_title,
            placeholder: s.table_template_placeholder,
            emptyText: s.table_template_empty,
            controller: _template,
            options: TableTemplate.options(context)
          ),
          SizedBox(height: AppSize.spaceM),
          Button(
            title: _menu ? s.menu_create_action : s.create_table,
            loading: _form.loading,
            action: _submit
          )
        ])
    );
  }

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    context.read<TablesService>().create(context, _payload())
      .then((id) {
        if (!mounted) return;
        _form.loading.value = false;
        FloatFlag.of(context).message(_menu ? S.of(context).menu_created : S.of(context).table_created);
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
  Map<String, dynamic> _payload() {
    final template = _menu ? _start : _template.value;

    return createTableRequest(
      title: _title.value,
      description: _description.value,
      color: _color,
      template: template == TableTemplate.blank ? null : template,
      kind: _kind
    );
  }
}