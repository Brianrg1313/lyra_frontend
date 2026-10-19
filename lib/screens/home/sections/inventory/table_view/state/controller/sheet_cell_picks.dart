part of '../sheet_controller.dart';

/// The cells set by a gesture of their own type: a yes / no flipped, a date picked in a
/// calendar, a measure column's unit picked from its button or typed after a number, and what
/// one product's stock is counted in.
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

  /// Opens a measure's or a stock's units anchored to the button of one of its cells
  /// ([anchor]) and saves the one picked as the column's (`UNIT`): every row reads in it.
  /// Above go the unit it has and units (no `UNIT`, the default); any other is typed in the
  /// create row.
  ///
  /// While the table has rows, a unit the figures can follow (kg → g, [measureFactor]) asks
  /// whether they do ([askUnitChange]): a measure's values and a stock's products counted in the
  /// column's unit are converted by the backend. Any other change keeps them, and a stock asks
  /// first: 10 kg would read 10 u, and nothing in the sheet would say they were weighed.
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

    final stock = typeAt(column) == TableFieldType.stock;
    final factor = _factor(unit, picked.value);
    var convert = false;

    if (factor != null && service.records > 0) {
      final context = _context();
      if (!context.mounted) return;

      final change = await askUnitChange(
        context,
        from: unit,
        to: picked.value,
        factor: factor,
        note: stock ? S.of(context).unit_change_stock_note : S.of(context).unit_change_measure_note
      );

      if (_disposed || change == null) return;
      convert = change == UnitChange.convert;
    } else if (stock && service.records > 0) {
      final context = _context();
      if (!context.mounted) return;

      final none = S.of(context).product_table_view_unit_count_symbol;

      final confirmed = await showAlertModal(
        context: context,
        title: S.of(context).product_table_view_unit_stock_title,
        message: S.of(context).product_table_view_unit_stock_message(
          unit.isEmpty ? none : unit,
          picked.value.isEmpty ? none : picked.value
        ),
        confirmText: S.of(context).product_table_view_unit_stock_confirm,
        cancelText: S.of(context).cancel
      );

      if (_disposed || !confirmed) return;
    }

    await service.editField(_context(), field, unit: picked.value, convert: convert);
  }

  /// Opens the units of one record's stock anchored to its ruler ([anchor]) and saves the one
  /// picked as that product's ([TableViewService.setUnit]): a supplies table weighs its meat in
  /// kg and counts its sodas, so the column's unit is only the default its rows start in. Above
  /// go the column's (picking it takes the product back to it) and units, written as `u` when
  /// the column counts in another; any other is typed in the create row.
  ///
  /// Between units the figures can follow (kg → g) it asks whether they do ([askUnitChange]),
  /// even at 0: the recipes that spend it and its presentations are written in its unit too.
  /// Any other change asks only while it has stock, like [pickUnit]: the figure stays.
  Future<void> pickRowUnit(SheetCell cell, BuildContext anchor) async {
    final record = service.rowAt(cell.row);
    final field = columns.fieldAt(cell.column);
    if (record == null || record.id.isEmpty || field == null) return;

    final strings = S.of(anchor);
    final count = strings.product_table_view_unit_count_symbol;
    final column = field.unit;
    final current = record.unit;

    // What the row reads in now, and what each option leaves stored: the column's is "".
    String shown(String stored) => stored.isNotEmpty ? stored : column.isEmpty ? count : column;
    final now = shown(current);

    final picked = await showSelectMenu(
      context: anchor,
      options: [
        SelectOption(
          value: "",
          placeholder: strings.product_table_view_unit_default(column.isEmpty ? count : column)
        ),
        if (column.isNotEmpty) SelectOption(
          value: count,
          placeholder: strings.product_table_view_unit_count,
          subtitle: count
        ),
        if (current.isNotEmpty && current != count && measureSymbolOf(current) == null)
          SelectOption(value: current, placeholder: current),
        for (final measure in measureUnits)
          if (measure.symbol != column) SelectOption(
            value: measure.symbol,
            placeholder: measure.symbol,
            subtitle: _magnitude(anchor, measure.magnitude)
          )
      ],
      selected: current,
      searchPlaceholder: strings.product_table_view_unit_search,
      emptyText: strings.table_settings_unit_empty,
      maxOptions: 6,
      dense: true,
      createText: strings.table_settings_unit_create,
      createPlaceholder: strings.product_table_view_unit_placeholder,
      onCreate: (typed) async => typed.trim().isEmpty
        ? null
        : SelectOption(value: typed.trim(), placeholder: typed.trim())
    );

    if (_disposed || picked == null) return;

    // A unit equal to the column's is the column's: stored as "", it follows the column.
    final unit = picked.value == column ? "" : picked.value;
    if (unit == current) return;

    final value = record.at(columns.slotAt(cell.column));
    final figure = value is num ? value : num.tryParse("${value ?? ""}") ?? 0;
    final factor = _factor(now, shown(unit));
    var convert = false;

    if (factor != null) {
      final context = _context();
      if (!context.mounted) return;

      final change = await askUnitChange(
        context,
        from: now,
        to: shown(unit),
        factor: factor,
        figure: figure,
        note: S.of(context).unit_change_product_note
      );

      if (_disposed || change == null) return;
      convert = change == UnitChange.convert;
    } else if (figure != 0) {
      final context = _context();
      if (!context.mounted) return;

      final confirmed = await showAlertModal(
        context: context,
        title: S.of(context).product_table_view_unit_stock_title,
        message: S.of(context).product_table_view_unit_stock_message(now, shown(unit)),
        confirmText: S.of(context).product_table_view_unit_stock_confirm,
        cancelText: S.of(context).cancel
      );

      if (_disposed || !confirmed) return;
    }

    await service.setUnit(_context(), row: cell.row, unit: unit, convert: convert);
  }

  /// How many of [to] one [from] is when the backend can carry the figures there (cloud only:
  /// a master converts nothing, `inventory.units`); `null` when only the word can change, and
  /// when nothing would (the same unit written two ways).
  double? _factor(String from, String to) {
    if (!CapabilityService().shows("inventory.units")) return null;

    final factor = measureFactor(from, to);
    return factor == null || factor == 1 ? null : factor;
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
