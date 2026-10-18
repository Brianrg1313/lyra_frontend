part of '../sheet_controller.dart';

/// The cells set by a gesture of their own type: a yes / no flipped, a date picked in a
/// calendar, and a measure column's unit picked from its button or typed after a number.
extension SheetCellPicks on SheetController {
  /// Flips a `BOOLEAN` cell. Empty or unreadable counts as «no», so the first tap is a «yes».
  void toggleBoolean(SheetCell cell) {
    select(cell);
    _writeOption(cell, fieldBooleanValue(!(fieldBoolean(rawOf(cell)) ?? false)));
  }

  /// Opens the calendar of a date cell anchored to its button ([anchor]) and writes the day
  /// picked. A tap on the cell itself opens its text editor, like any other: a date can
  /// always be typed too.
  ///
  /// A `DATETIME` keeps the time it had —picking a day changes the day— and one that had
  /// none takes this moment's: the engine refuses a datetime without its time.
  Future<void> pickDate(SheetCell cell, BuildContext anchor) async {
    if (!anchor.mounted) return;

    select(cell);

    final column = columns.keyOf(cell.column);
    final current = ProductDate.parse(valueOf(cell));

    final picked = await showDateMenu(
      context: anchor,
      current: current,
      full: dates.isFull(column),
      onToggle: () => dates.toggle(column)
    );

    if (_disposed || picked == null) return;

    final day = picked.day;
    if (day == null) {
      _writeOption(cell, "");
      return;
    }

    final timed = typeAt(cell.column) == TableFieldType.datetime;
    final clock = current != null && current.hasTime ? current.at : DateTime.now();

    final stamp = DateTime(day.year, day.month, day.day, clock.hour, clock.minute);
    final text = "${stamp.year.toString().padLeft(4, "0")}-${_two(stamp.month)}-${_two(stamp.day)}"
      "${timed ? " ${_two(stamp.hour)}:${_two(stamp.minute)}" : ""}";

    _writeOption(cell, text);
  }

  /// Opens a measure column's units anchored to the button of one of its cells ([anchor])
  /// and saves the one picked as the column's (`UNIT`): every row reads in it. Above go the
  /// unit it has and units (no `UNIT`, the default); any other is typed in the create row.
  Future<void> pickUnit(int column, BuildContext anchor) async {
    final field = columns.fieldAt(column);
    if (field == null || field.id.isEmpty || !columns.canEditAt(column)) return;

    final unit = field.unit;

    final picked = await showSelectMenu(
      context: anchor,
      options: [
        if (unit.isNotEmpty) SelectOption(value: unit, placeholder: unit),
        // No unit is units: what a column counts until it is told otherwise.
        SelectOption(
          value: "",
          placeholder: S.of(anchor).product_table_view_unit_count,
          subtitle: S.of(anchor).product_table_view_unit_count_symbol
        ),
        for (final measure in measureUnits)
          if (measure.symbol != unit) SelectOption(
            value: measure.symbol,
            placeholder: measure.symbol,
            subtitle: _magnitude(anchor, measure.magnitude)
          )
      ],
      selected: unit,
      searchPlaceholder: S.of(anchor).product_table_view_unit_search,
      emptyText: S.of(anchor).table_settings_unit_empty,
      maxOptions: 6,
      dense: true,
      createText: S.of(anchor).table_settings_unit_create,
      createPlaceholder: S.of(anchor).product_table_view_unit_placeholder,
      onCreate: (typed) async => typed.trim().isEmpty
        ? null
        : SelectOption(value: typed.trim(), placeholder: typed.trim())
    );

    if (_disposed || picked == null || picked.value == unit) return;

    await service.editField(_context(), field, unit: picked.value);
  }

  /// Reads a unit typed after a measure's number on leaving the cell: «300lt» leaves `300`
  /// in it and the column in `l`, «5 uds» the column in units. The column's own unit, even
  /// one nobody offers («2 cajas» in a column of `cajas`), is only taken off the number.
  ///
  /// A column counts in one unit (see [UnitCell]), so a typed one changes the whole
  /// column's, as its button does. What is no unit the sheet knows stays written as is, and
  /// so does a different one where the column cannot be changed: taking it off would leave
  /// the number in a unit nobody wrote.
  void _readUnit(SheetCell? cell) {
    final editor = this.editor;

    if (cell == null || editor == null || cell.row == kFieldsRow) return;
    if (typeAt(cell.column) != TableFieldType.measure) return;

    final typed = splitMeasure(editor.text);
    if (typed == null || typed.unit.isEmpty) return;

    final field = columns.fieldAt(cell.column);
    final current = field?.unit ?? "";
    final symbol = typed.unit.toLowerCase() == current.toLowerCase()
      ? current
      : measureSymbolOf(typed.unit);

    if (symbol == null) return;

    final changes = symbol != current;
    if (changes && (field == null || field.id.isEmpty || !columns.canEditAt(cell.column))) return;

    editor.text = typed.number;
    if (changes) unawaited(service.editField(_context(), field!, unit: symbol));
  }

  String _magnitude(BuildContext context, MeasureMagnitude magnitude) => switch (magnitude) {
    MeasureMagnitude.weight => S.of(context).product_table_view_unit_weight,
    MeasureMagnitude.volume => S.of(context).product_table_view_unit_volume,
    MeasureMagnitude.length => S.of(context).product_table_view_unit_length
  };

  static String _two(int value) => value.toString().padLeft(2, "0");
}
