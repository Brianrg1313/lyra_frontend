import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/capabilities/capability_service.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/measure_units.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/inventory/stock_column/_stock_column.dart';
import 'package:app/screens/modals/inventory/unit_change/_unit_change.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The columns of the table, one below the other: what it is recognized by,
/// what it is called, what type it is, how much of it the model sees, whether
/// it enters the inventory summary and —depending on the type— what options it
/// offers or with what symbol its numbers are written.
///
/// Each column is a **two-part block**: above, its name with the icon of its
/// type; below, in a grid, the four data points that are changed, each one
/// with its label on top. It is read in the order in which they are seen in
/// the spreadsheet, so the third here in is the third there.
///
/// The label above each control is not decorative: it is the only thing that
/// says **what is being chosen**. One button that says "Text" and another that
/// says "Declared", next to each other, are two loose words until above it
/// says which one is the type and which the visibility. Before that it was
/// said by a single header above everything, which worked while the card
/// occupied one screen: at twenty columns of distance, the header was already
/// out of sight.
///
/// **The controls arrange themselves in a grid and not in a single stack.**
/// The name takes its own row —it is the one that can be long, because it was
/// written by whoever made the spreadsheet— and the four controls share the
/// ones below, four at a time when the four fit and **two by two** when not.
/// The widths in between are the usual ones —the card split into two columns,
/// a side panel—, and there the stack of one per row left four buttons the
/// whole width of the card with one word inside and all the rest empty, while
/// it stretched the row of each column to four lines: in a table of twenty
/// columns, eighty scroll lines.
///
/// That they are two and not three is what keeps the cells aligned from one
/// row to the next: four data points in rows of two are two even lines, and
/// in rows of three they are one full and another with a hole.
///
/// Each cell does not go below [_cell]: it is what the longest value it can
/// show needs —the name of a type, "Date and time"— without its own arrow
/// cutting it, and a cut data point is precisely the one that has to be
/// opened to know what it says. Where not even two of those fit (the phone
/// sheet) they stack one below the other: before shrinking them until they
/// are cut, they are left whole and one goes down.
///
/// And it is **edited** from here, which is what makes it a table and not a
/// report: the data points that are compared are the ones that are corrected,
/// and they are corrected in the same block where they were read. Each choice
/// saves itself (see [TableDetailService.editField]); there is no save button
/// because there is no form.
class TableColumnsTable extends StatelessWidget {
  const TableColumnsTable({super.key, required this.fields});

  final List<TableDetailFieldModel> fields;

  /// Minimum useful width of a cell: what the longest value it can show —the
  /// name of a type— needs without its own arrow cutting it.
  static double get _cell => AppSize.action * 3.2;

  /// How many controls fit in a row with the width there is.
  ///
  /// They are four, two or one and never three: see the class note. Without a
  /// measured width they stack, which is what is read at any width.
  static int _perRow(double width) {
    if (!width.isFinite) return 1;
    if (width >= _cell * 4 + AppSize.gap * 3) return 4;

    return width >= _cell * 2 + AppSize.gap ? 2 : 1;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final perRow = _perRow(constraints.maxWidth);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) Separator.horizontal(
              margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
            ),
            _Field(field: fields[i], perRow: perRow)
          ]
        ]
      );
    }
  );
}

/// A column of the table: its name above and its four data points below.
///
/// The four save themselves when chosen and none asks anything: they are
/// changes to a table that already exists and all of them have a way back by
/// choosing the previous value. The only one that also touches what is loaded
/// is the type, and that is resolved by the backend rewriting the column (see
/// `PUT /inventory/products/builder/fields/`).
class _Field extends StatelessWidget {
  const _Field({required this.field, required this.perRow});

  final TableDetailFieldModel field;

  /// How many controls go per row. See the note of [TableColumnsTable].
  final int perRow;

  @override
  Widget build(BuildContext context) {
    final cells = _cells(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _TypeIcon(type: field.type),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: _Name(field: field))
        ]),
        SizedBox(height: AppSize.spaceXS),
        // The rows of the grid. With one per row the usual stack is left, so
        // it is the same code for the three widths and not three branches
        // that keep separating.
        for (int start = 0; start < cells.length; start += perRow) ...[
          if (start > 0) SizedBox(height: AppSize.spaceXS),
          Row(
            // At the bottom and not at the top: the labels measure the same,
            // but if any were to go to two lines its controls have to keep
            // being aligned with each other.
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = start; i < start + perRow; i++) ...[
                if (i > start) SizedBox(width: AppSize.gap),
                // The last row can remain short: the slot is reserved anyway
                // so the cells keep measuring the same as the ones above and
                // the last one is not stretched to fill it.
                Expanded(
                  child: i < cells.length ? cells[i] : const SizedBox.shrink()
                )
              ]
            ]
          )
        ]
      ]
    );
  }

  /// The four data points that are changed, each one with its name above.
  /// They are the same in the two widths: the only thing that changes is
  /// whether they go in one row or one below the other.
  ///
  /// The third one is the only one that changes its question according to the
  /// type: a list has options and a price or a measure have a unit, and no
  /// type has both things. They go in the same cell —with its label saying
  /// which of the two it is— and not in two, because a fifth empty cell in
  /// the twenty columns that do not use it would be a whole column of dashes.
  List<_Cell> _cells(BuildContext context) => [
    _Cell(
      label: S.of(context).table_settings_column_type,
      child: SettingsSelect(
        label: field.type.label(context),
        message: S.of(context).table_settings_pick_type,
        open: _pickType
      )
    ),
    // How much the cloud's agents see: no agents where the AI areas aren't offered.
    if (CapabilityService().shows("channels")) _Cell(
      label: S.of(context).table_settings_column_visibility,
      child: SettingsSelect(
        icon: field.visibility.icon,
        label: field.visibility.label(context),
        color: _visibilityColor(context, field.visibility),
        message: S.of(context).table_settings_pick_visibility,
        open: _pickVisibility
      )
    ),
    _Cell(
      label: field.type.united
        ? S.of(context).table_settings_column_unit
        : S.of(context).table_settings_column_options,
      child: field.type.united
        ? _Unit(field: field)
        : _Options(field: field)
    ),
    _Cell(
      label: S.of(context).table_settings_column_summary,
      child: _Summary(field: field)
    )
  ];

  /// Opens the type list, anchored to the dropdown.
  ///
  /// It is the same one as the spreadsheet ([TableFieldType.menu]) and with a
  /// search box for the same reason: there are twenty-three, and with the
  /// list open choosing becomes writing three letters instead of going over
  /// them. Choosing the one it already had sends nothing.
  Future<void> _pickType(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: TableFieldType.menu(anchor),
      selected: field.type.value,
      searchPlaceholder: S.of(anchor).table_field_type_placeholder,
      emptyText: S.of(anchor).table_field_type_empty,
      maxOptions: 4
    );

    if (picked == null || !anchor.mounted) return;

    final type = TableFieldType.from(picked.value);
    if (type == field.type) return;

    if (type == TableFieldType.stock) {
      final records = anchor.read<TableDetailService>().detail.records;
      if (!await confirmStockColumn(anchor, records: records) || !anchor.mounted) return;
    }

    await anchor
      .read<TableDetailService>()
      .editField(anchor, field, type: type);
  }

  /// Opens the three visibility states, anchored to the dropdown.
  ///
  /// Each one goes with its explanation below ([TableFieldVisibility.hint])
  /// and not only with its name: all three are called similar, and the middle
  /// one —the one that lets the model filter by a column without being able to
  /// say what it is worth— nobody guesses reading "declared". Without a search
  /// box: there are three.
  Future<void> _pickVisibility(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: [
        for (final state in TableFieldVisibility.values) SelectOption(
          value: state.value,
          placeholder: state.label(anchor),
          subtitle: state.hint(anchor),
          icon: state.icon
        )
      ],
      selected: field.visibility.value,
      maxOptions: 3
    );

    if (picked == null || !anchor.mounted) return;

    final visibility = TableFieldVisibility.from(picked.value);
    if (visibility == field.visibility) return;

    await anchor
      .read<TableDetailService>()
      .editField(anchor, field, visibility: visibility);
  }
}

/// A column data point with its name above.
///
/// The name goes above and not inside the button because the button is
/// already busy saying how much the data point is worth: "Declared" is the
/// answer, and "Visibility" is the question it answers. The two together in
/// the same line do not fit, and the question alone cannot be taken out —it
/// is the only thing that says what is being touched—.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      TextSmall(
        label,
        ellipsis: true,
        color: ThemeColor.of(context).text.secondary
      ),
      SizedBox(height: AppSize.gap * 0.5),
      child
    ]
  );
}

/// The type of the column drawn, in the same box as in the spreadsheet.
class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final TableFieldType type;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      width: AppSize.button,
      height: AppSize.button,
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.spaceXS),
      child: Center(child: Icon(
        type.icon,
        size: AppSize.text,
        color: scheme.icon
      ))
    );
  }
}

/// What the column is called and, if it has one, what it is for.
///
/// The number is the place it occupies in the spreadsheet, and it goes because
/// the list is in that order: it is what lets crossing this block with the
/// column that was being looked at there without having to count.
///
/// The description only draws if it is there: almost no column imported from a
/// spreadsheet has one, and the empty row in all of them would make the list
/// twice as long without saying anything.
class _Name extends StatelessWidget {
  const _Name({required this.field});

  final TableDetailFieldModel field;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Flexible(child: TextMedium(field.name, bold: true, ellipsis: true)),
          SizedBox(width: AppSize.gap),
          TextSmall("${field.position + 1}", color: scheme.text.secondary)
        ]),
        if (field.description.isNotEmpty) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            field.description,
            lines: 2,
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      ]
    );
  }
}

/// The options of the column, when it chooses from a list (one label per
/// product or several, see [TableFieldType.listed]).
///
/// In any other type a dash is left and not a dimmed dropdown: the options are
/// not a data point that that field has empty, it is a data point that does
/// not exist for it. The dash goes in the place of the button —with its label
/// above the same— so that the three data points keep being aligned from one
/// column to the next.
///
/// The dropdown shows the ones there are and, glued below, the row to add one
/// (see [showSelectMenu]): it is where the list is built without having to go
/// to the spreadsheet to look for a cell of that column. Choosing one of the
/// ones that are already there does nothing —here the list is the data point,
/// not a value that is being chosen—, so what the dropdown returns is
/// discarded.
class _Options extends StatelessWidget {
  const _Options({required this.field});

  final TableDetailFieldModel field;

  /// How many options the list has to have for the dropdown to bring a search
  /// box. With few, the search box is one more row between the button and
  /// what is wanted to be touched.
  static const int _searchFrom = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    if (!field.type.listed) return _Missing(scheme: scheme);

    final empty = field.options.isEmpty;

    return SettingsSelect(
      label: empty
        ? S.of(context).table_settings_options_empty
        : S.of(context).table_settings_options(field.options.length),
      color: empty ? scheme.text.secondary : null,
      message: S.of(context).table_settings_pick_options,
      open: _open
    );
  }

  Future<void> _open(BuildContext anchor) => showSelectMenu(
    context: anchor,
    options: [
      for (final option in field.options)
        SelectOption(value: option, placeholder: option)
    ],
    searchPlaceholder: field.options.length > _searchFrom
      ? S.of(anchor).table_field_option_search
      : null,
    emptyText: S.of(anchor).table_settings_options_empty,
    createText: S.of(anchor).table_field_option_create,
    createPlaceholder: S.of(anchor).table_field_option_placeholder,
    onCreate: (name) => _create(anchor, name)
  );

  /// Adds an option to the list from the dropdown itself.
  ///
  /// An option is a property of the column, so it is saved like any other: by
  /// sending the list that has to remain. Writing one that was already there
  /// creates nothing nor fails —the one there is, is returned, which is what
  /// whoever wrote it meant— and two that only differ in capital letters or
  /// accents are the same ([sameFieldOption]), because they would be
  /// indistinguishable when choosing them.
  ///
  /// Returns `null` if it could not be saved; the error was already shown by
  /// the service and the dropdown row stays open with what was written to
  /// retry.
  Future<SelectOption?> _create(BuildContext context, String name) async {
    final existing = fieldOptionLike(field.options, name);
    if (existing != null) {
      return SelectOption(value: existing, placeholder: existing);
    }

    final options = fieldOptionsWith(field.options, name);
    if (options == null) return null;

    final saved = await context
      .read<TableDetailService>()
      .editField(context, field, options: options);

    if (!saved) return null;

    final created = name.trim();
    return SelectOption(value: created, placeholder: created);
  }
}

/// The symbol with which the numbers of the column are written: the currency
/// code of a price or an amount, the magnitude of a measure.
///
/// It is the sibling of [_Options] for the types that carry a unit and not a
/// list (see [TableFieldType.united]), and it occupies its same cell: no type
/// has both things. A percentage does not come in here either —there the unit
/// **is** the type— and that is why its cell stays with the dash of the
/// others.
///
/// It is written in the same create row of the dropdown that builds an option
/// (see [showSelectMenu]), and not in a separate field, for the same reason:
/// it is a short text written once and saved alone. Above goes the unit it
/// has set —to be able to come back to it in one touch— and the row to remove
/// it, which is what returns the column to the business currency.
///
/// **An empty unit is sent the same.** It is the only way to erase it: the
/// backend reads the empty as a value and not as the absence of one (see
/// `editFieldRequest`).
///
/// A measure and a stock offer the sheet's units ([measureUnits]), and count
/// units without one. A recipe writes a supply in any unit of its magnitude
/// (`kitchenUnitsFor`): one counted in `kg` is written in grams too.
///
/// While the table has rows, a unit the figures can follow (kg → g) asks whether
/// they do ([askUnitChange]), as the sheet's ruler does; any other change of a
/// stock asks first, since its figures stay as they are.
class _Unit extends StatelessWidget {
  const _Unit({required this.field});

  final TableDetailFieldModel field;

  bool get _counts => field.type == TableFieldType.measure || field.type == TableFieldType.stock;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final empty = field.unit.isEmpty;
    // A measure or a stock without a unit counts units (see `UnitCell`).
    final none = _counts
      ? S.of(context).product_table_view_unit_count
      : S.of(context).table_settings_unit_empty;

    return SettingsSelect(
      label: empty ? none : field.unit,
      color: empty ? scheme.text.secondary : null,
      message: S.of(context).table_settings_pick_unit,
      open: _open
    );
  }

  Future<void> _open(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: [
        if (field.unit.isNotEmpty) ...[
          SelectOption(value: field.unit, placeholder: field.unit),
          if (!_counts) SelectOption(
            value: "",
            placeholder: S.of(anchor).table_settings_unit_none,
            icon: Icons.remove
          )
        ],
        if (_counts) SelectOption(
          value: "",
          placeholder: S.of(anchor).product_table_view_unit_count,
          subtitle: S.of(anchor).product_table_view_unit_count_symbol
        ),
        if (_counts)
          for (final unit in measureUnits)
            if (unit.symbol != field.unit) SelectOption(value: unit.symbol, placeholder: unit.symbol)
      ],
      selected: field.unit,
      emptyText: S.of(anchor).table_settings_unit_empty,
      createText: S.of(anchor).table_settings_unit_create,
      createPlaceholder: S.of(anchor).table_settings_unit_placeholder,
      onCreate: (unit) async => SelectOption(
        value: unit.trim(),
        placeholder: unit.trim()
      )
    );

    if (picked == null || picked.value == field.unit) return;
    if (!anchor.mounted) return;

    final service = anchor.read<TableDetailService>();
    final rows = service.detail.records != 0;
    final stock = field.type == TableFieldType.stock;
    final factor = _counts && CapabilityService().shows("inventory.units")
      ? measureFactor(field.unit, picked.value)
      : null;
    var convert = false;

    if (factor != null && factor != 1 && rows) {
      final change = await askUnitChange(
        anchor,
        from: field.unit,
        to: picked.value,
        factor: factor,
        note: stock ? S.of(anchor).unit_change_stock_note : S.of(anchor).unit_change_measure_note
      );

      if (change == null || !anchor.mounted) return;
      convert = change == UnitChange.convert;
    } else if (stock && rows) {
      final none = S.of(anchor).product_table_view_unit_count_symbol;
      final confirmed = await showAlertModal(
        context: anchor,
        title: S.of(anchor).product_table_view_unit_stock_title,
        message: S.of(anchor).product_table_view_unit_stock_message(
          field.unit.isEmpty ? none : field.unit,
          picked.value.isEmpty ? none : picked.value
        ),
        confirmText: S.of(anchor).product_table_view_unit_stock_confirm,
        cancelText: S.of(anchor).cancel
      );

      if (!confirmed || !anchor.mounted) return;
    }

    await service.editField(anchor, field, unit: picked.value, convert: convert);
  }
}

/// The place of the control of a cell that that column type does not have: a
/// dash instead of a dimmed dropdown.
///
/// It measures what a button measures so the data points keep being aligned
/// from one column to the next: without it, the row of a column without
/// options or unit would end lower than the one next to it and the grid would
/// stop being read vertically, which is what it is for.
class _Missing extends StatelessWidget {
  const _Missing({required this.scheme});

  final SchemeColor scheme;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSize.button,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS),
        child: TextSmall("—", color: scheme.text.secondary)
      )
    )
  );
}

/// Whether the column enters the inventory summary.
///
/// It is a checkbox and not a dropdown because they are two states: unfolding
/// a two-row list to choose between yes and no is one more step in a screen
/// where twenty columns have to be gone over deciding precisely that.
///
/// **It is not the visibility with another name.** That one says how much the
/// AI sees of the column; this one, that it is shown to a person at a glance,
/// and the two do not go together: a cost price is hidden from the agent and
/// is the first thing the owner wants to see in his summary. That is why they
/// are two controls next to each other and not four states of one.
///
/// The checkbox is drawn with what the card has and not with what was just
/// touched: the one that saves is the write, which paints the column as soon
/// as the backend accepts it (see [TableDetailService.editField]). If it
/// fails, the checkbox stays as it was and the error goes out through the
/// floating flag, which is correct: turning it on anyway would say the column
/// is in the summary when it is not.
class _Summary extends StatelessWidget {
  const _Summary({required this.field});

  final TableDetailFieldModel field;

  @override
  Widget build(BuildContext context) => SettingsToggle(
    value: field.summary,
    label: field.summary
      ? S.of(context).table_settings_column_summary_on
      : S.of(context).table_settings_column_summary_off,
    message: field.summary
      ? S.of(context).table_settings_column_summary_hide
      : S.of(context).table_settings_column_summary_show,
    toggle: () => _toggle(context)
  );

  Future<void> _toggle(BuildContext context) => context
    .read<TableDetailService>()
    .editField(context, field, summary: !field.summary);
}

/// The color of a visibility state.
///
/// They are the three states read as what they mean for whoever looks at the
/// table: the brand one when the agent can cite the data point, the notice
/// one when it uses it without saying it —which is the one that has to be
/// distinguishable at a glance, because that is where the cost price lives—
/// and grey when it does not even know the column exists.
Color _visibilityColor(BuildContext context, TableFieldVisibility visibility) {
  final scheme = ThemeColor.of(context);

  return switch (visibility) {
    TableFieldVisibility.visible => scheme.primary,
    TableFieldVisibility.declared => scheme.accent,
    TableFieldVisibility.hidden => scheme.text.secondary
  };
}