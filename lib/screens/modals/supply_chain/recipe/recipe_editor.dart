import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/kitchen_units.dart';
import 'package:app/services/kitchen/recipe_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// One line as it is being written: the ingredient, its quantity (in one of the units its own
/// can be written in, [shown]) and its waste as typed.
class _LineDraft {
  _LineDraft({
    required this.tableId,
    required this.productId,
    required this.name,
    this.supplies,
    this.unit = "",
    double? qty,
    double waste = 0,
    this.negotiable = false
  }) : units = kitchenUnitsFor(unit),
       more = waste > 0 {
    this.waste = InputController(key: "WASTE", form: _form, pattern: "[0-9.,]", max: 6, initial: waste > 0 ? kitchenField(waste) : null);
    final best = qty == null ? null : kitchenBestUnit(qty, unit);

    // A new line of a weight or a volume starts on the small unit: 300 g, not 0.3 kg.
    shown = best?.unit ?? units.first;
    this.qty = InputController(key: "QTY", form: _form, pattern: "[0-9.,]", max: 16, initial: best == null ? null : kitchenField(best.qty));
  }

  final String tableId;
  final String productId;
  final String name;

  /// A supply takes decimals; a product for sale (the burger in a combo) whole units only.
  /// `null` on a saved line: the recipe doesn't say which, and the backend checks it anyway.
  final bool? supplies;

  /// The ingredient's own unit, the only one the backend takes (empty: counted in units).
  final String unit;

  /// What [qty] can be written in.
  final List<KitchenUnit> units;
  late KitchenUnit shown;

  /// Owns [qty] and [waste]: an input disposes a controller without a form when it unmounts,
  /// and the waste's is unmounted each time the line folds (its focus node reused dead breaks
  /// the focus tree).
  final _form = FormController();

  late final InputController qty;
  late final InputController waste;
  bool negotiable;

  /// Whether its waste is unfolded: always when it has one.
  bool more;
  String error = "";

  void dispose() {
    qty.dispose();
    waste.dispose();
    _form.dispose();
  }
}

/// A choice as it is being written ([RecipeChoice]): what it is called, how many are picked of
/// it per unit and its options, each one a line ([_LineDraft]: what ONE pick takes).
class _ChoiceDraft {
  _ChoiceDraft({this.id = "", String name = "", int choose = 1, List<_LineDraft>? options}) : options = options ?? [] {
    this.name = InputController(key: "CHOICE_NAME", form: _form, max: 60, initial: name.isEmpty ? null : name);
    this.choose = InputController(key: "CHOICE_CHOOSE", form: _form, pattern: "[0-9]", max: 2, initial: "$choose");
  }

  /// Kept on an edit: an open ticket names its picks by it.
  final String id;
  final List<_LineDraft> options;

  /// Owns [name] and [choose], like a line's form.
  final _form = FormController();
  late final InputController name;
  late final InputController choose;
  String error = "";

  /// How many are picked, when it reads as a number the backend takes.
  int? get picks {
    final value = int.tryParse(choose.text.trim());
    return value == null || value < 1 || value > kitchenMaxChoose ? null : value;
  }

  void dispose() {
    name.dispose();
    choose.dispose();
    _form.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

/// What a recipe being written saves: its mode, its lines, what the customer picks and the
/// names of everything in them (product id → name), so the answer of a write is named.
typedef RecipeDraft = ({
  RecipeMode mode,
  List<RecipeLineDraft> lines,
  List<RecipeChoiceDraft> choices,
  Map<String, String> names
});

/// What a product is made of, written: how it is made, its lines — how much ONE unit takes,
/// whether it can go without it, what is lost making it — and the ingredient search that adds
/// one.
///
/// How it is made follows what the product is (`cocina-frontend.md` §1): a made product is made
/// to order unless «Made by the batch» is on; a supply's preparation (the house sauce) is
/// always by the batch, so it asks nothing.
///
/// A line's quantity is written in a unit of its ingredient's measure (300 g of a meat counted
/// in kg) and travels in the ingredient's own, which is the only one the backend takes.
///
/// A product made to order may also have **choices** (`cocina-frontend.md` §3): what the
/// customer picks inside it and it can't go without, the family combo's 2 burgers among the
/// Cheese and the Classic in any mix. Each is a card under the lines: how many are picked, what
/// it is called and its options, each one written like a line (what ONE pick takes). A batch is
/// made before anybody picks, so a batch has none.
///
/// It checks here what the backend would refuse in the same terms (a quantity above zero, whole
/// on anything counted in units; waste from 0 to under 100; at least one line it can't go
/// without), so a mistake is said beside the line. The rules only the backend knows (a recipe
/// that contains itself, more than two levels made to order) come back as its refusal, shown as
/// it comes. [onSave] writes it, or hands it back: `false` keeps the editor open.
///
/// With [onChanged], every change hands what reads so far (a line with no valid quantity yet is
/// left out, silently): a made product's form costs it as it is written, and gives [cost] back,
/// drawn beside each line and as a total under them.
class RecipeEditor extends StatefulWidget {
  const RecipeEditor({
    super.key,
    required this.recipe,
    required this.supplies,
    required this.canEdit,
    required this.onSave,
    required this.onCancel,
    this.exclude = const {},
    this.saveLabel,
    this.units = const {},
    this.leading = const [],
    this.trailing = const [],
    this.validate,
    this.onChanged,
    this.cost
  });

  /// What it is made of now; `null` writes the first.
  final Recipe? recipe;

  /// A supply's preparation: always by the batch.
  final bool supplies;
  final bool canEdit;
  final Future<bool> Function(RecipeDraft draft) onSave;

  /// Leaves the editor without saving.
  final void Function() onCancel;

  /// Product ids not offered as ingredients: the product itself.
  final Set<String> exclude;
  final String? saveLabel;

  /// The unit each ingredient is counted in, by product id, for the saved lines (the backend
  /// answers them without one); a picked ingredient brings its own.
  final Map<String, String> units;

  /// What goes above how it is made: a made product's own fields.
  final List<Widget> leading;

  /// What goes under what it is made of, above the buttons: what a made product offers.
  final List<Widget> trailing;

  /// Checks what [leading] holds, beside the lines; `false` does not save.
  final bool Function()? validate;

  /// What reads so far, on every change of the lines or the mode, and once at the start.
  final void Function(RecipeDraft draft)? onChanged;

  /// What [onChanged]'s last draft costs: each line's share and the total. `null`: none drawn.
  final DishCost? cost;

  @override
  State<RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<RecipeEditor> {
  late bool _batch = widget.supplies || widget.recipe?.mode == RecipeMode.batch;

  late final List<_LineDraft> _lines = [
    for (final line in widget.recipe?.lines ?? const <RecipeLine>[]) _LineDraft(
      tableId: line.tableId,
      productId: line.productId,
      name: line.name,
      unit: widget.units[line.productId] ?? "",
      qty: line.qty,
      waste: line.waste,
      negotiable: line.negotiable
    )
  ];

  late final List<_ChoiceDraft> _choices = [
    for (final choice in widget.recipe?.choices ?? const <RecipeChoice>[]) _ChoiceDraft(
      id: choice.id,
      name: choice.name,
      choose: choice.choose,
      options: [
        for (final option in choice.options) _LineDraft(
          tableId: option.tableId,
          productId: option.productId,
          name: option.name,
          unit: widget.units[option.productId] ?? "",
          qty: option.qty,
          waste: option.waste
        )
      ]
    )
  ];

  final _saving = ValueNotifier(false);
  String _error = "";

  @override
  void initState() {
    super.initState();

    for (final line in _lines) {
      _watch(line);
    }
    for (final choice in _choices) {
      _watchChoice(choice);
    }
    _changed();
  }

  @override
  void dispose() {
    _saving.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    for (final choice in _choices) {
      choice.dispose();
    }
    super.dispose();
  }

  void _add(KitchenProduct product) {
    final line = _LineDraft(
      tableId: product.tableId,
      productId: product.id,
      name: product.label,
      supplies: product.supplies,
      unit: product.unit
    );

    setState(() => _lines.add(_watch(line)));
    _changed();
  }

  void _remove(_LineDraft line) {
    setState(() => _lines.remove(line));
    line.dispose();
    _changed();
  }

  /// A dish counts in whole units, so one pick of it is one; a supply's is typed.
  _LineDraft _option(KitchenProduct product) => _LineDraft(
    tableId: product.tableId,
    productId: product.id,
    name: product.label,
    supplies: product.supplies,
    unit: product.unit,
    qty: product.supplies ? null : 1
  );

  void _addChoice() {
    setState(() => _choices.add(_watchChoice(_ChoiceDraft())));
    _changed();
  }

  void _removeChoice(_ChoiceDraft choice) {
    setState(() => _choices.remove(choice));
    choice.dispose();
    _changed();
  }

  void _addOption(_ChoiceDraft choice, KitchenProduct product) {
    setState(() => choice.options.add(_watch(_option(product))));
    _changed();
  }

  void _removeOption(_ChoiceDraft choice, _LineDraft option) {
    setState(() => choice.options.remove(option));
    option.dispose();
    _changed();
  }

  /// A typed number of picks changes what the recipe costs, and the sentence under it.
  _ChoiceDraft _watchChoice(_ChoiceDraft choice) {
    choice.choose.textController.addListener(_picksChanged);
    for (final option in choice.options) {
      _watch(option);
    }
    return choice;
  }

  void _picksChanged() {
    if (mounted) setState(() {});
    _changed();
  }

  /// A typed quantity or waste changes what the recipe costs.
  _LineDraft _watch(_LineDraft line) {
    if (widget.onChanged != null) {
      line.qty.textController.addListener(_changed);
      line.waste.textController.addListener(_changed);
    }
    return line;
  }

  void _changed() {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;

    onChanged((
      mode: _mode,
      lines: [
        for (final line in _lines)
          if (_read(line) case (final double qty, final double waste) when qty > 0 && waste >= 0 && waste < 100)
            (tableId: line.tableId, productId: line.productId, qty: qty, negotiable: line.negotiable, waste: waste)
      ],
      choices: _batch ? const [] : [for (final choice in _choices) ?_costable(choice)],
      names: _names
    ));
  }

  RecipeMode get _mode => _batch ? RecipeMode.batch : RecipeMode.order;

  Map<String, String> get _names => {
    for (final line in _lines) line.productId: line.name,
    for (final choice in _choices)
      for (final option in choice.options) option.productId: option.name
  };

  /// A choice as it is costed: once it reads whole (its picks, and two options at least that
  /// read); `null` until then.
  static RecipeChoiceDraft? _costable(_ChoiceDraft choice) {
    final picks = choice.picks;
    if (picks == null) return null;

    final options = [
      for (final option in choice.options)
        if (_read(option) case (final double qty, final double waste) when qty > 0 && waste >= 0 && waste < 100)
          (tableId: option.tableId, productId: option.productId, qty: qty, waste: waste)
    ];

    return options.length < 2 ? null : (id: choice.id, name: choice.name.text, choose: picks, options: options);
  }

  /// A line's quantity in its ingredient's own unit, rounded where the backend rounds
  /// (millionths), and its waste; either `null` when it does not read as a number.
  static (double?, double?) _read(_LineDraft line) {
    final typed = kitchenParse(line.qty.text);
    final qty = typed == null ? null : double.parse((typed * line.shown.factor).toStringAsFixed(6));
    final waste = line.waste.text.trim().isEmpty ? 0.0 : kitchenParse(line.waste.text);

    return (qty, waste);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.leading,
        if (!widget.supplies) ...[
          TextMedium(s.supply_chain_mode_title, bold: true),
          SizedBox(height: AppSize.spaceXS),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final batch in [false, true]) ...[
              if (batch) SizedBox(width: AppSize.spaceS),
              Expanded(child: _ModeTile(
                title: batch ? s.supply_chain_mode_batch : s.supply_chain_mode_order,
                note: batch ? s.supply_chain_mode_batch_note : s.supply_chain_mode_order_note,
                selected: _batch == batch,
                action: widget.canEdit ? () {
                  setState(() => _batch = batch);
                  _changed();
                } : null
              ))
            ]
          ]),
          SizedBox(height: AppSize.spaceM)
        ],
        TextMedium(s.supply_chain_lines_title, bold: true),
        KitchenNote(text: s.supply_chain_lines_note),
        if (_lines.isEmpty && _choices.isEmpty && !widget.canEdit)
          KitchenNote(text: s.supply_chain_lines_empty, color: scheme.text.secondary)
        else if (_lines.isNotEmpty) Surface.over(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (index, line) in _lines.indexed) ...[
              if (index > 0) Separator.horizontal(),
              _LineRow(
                key: ObjectKey(line),
                line: line,
                cost: widget.cost?.lineOf(line.productId),
                enabled: widget.canEdit,
                onRemove: () => _remove(line),
                onNegotiable: (value) => setState(() => line.negotiable = value),
                onUnit: (unit) {
                  setState(() => line.shown = unit);
                  _changed();
                },
                onMore: () => setState(() => line.more = !line.more)
              )
            ],
            if (widget.cost != null) ...[
              Separator.horizontal(),
              _CostTotal(cost: widget.cost!)
            ]
          ])
        ),
        if (widget.canEdit) ...[
          SizedBox(height: AppSize.spaceXS),
          KitchenProductPicker(
            placeholder: s.supply_chain_lines_add,
            exclude: {...widget.exclude, for (final line in _lines) line.productId},
            onPick: _add
          )
        ],
        ..._choicesBlock(context),
        if (_error.isNotEmpty) KitchenNote(text: _error, color: scheme.snackBar.error),
        ...widget.trailing,
        if (widget.canEdit) ...[
          SizedBox(height: AppSize.spaceM),
          Row(children: [
            Expanded(child: Button(title: s.cancel, action: widget.onCancel)),
            SizedBox(width: AppSize.spaceS),
            Expanded(child: MainButton(title: widget.saveLabel ?? s.save, loading: _saving, action: _save))
          ])
        ]
      ]
    );
  }

  /// What the customer picks: on a product made to order only (a supply's preparation and a
  /// batch are made before anybody picks). A batch that still holds choices shows them, so its
  /// save can say why it is refused.
  List<Widget> _choicesBlock(BuildContext context) {
    final s = S.of(context);
    final offered = !widget.supplies && !_batch && widget.canEdit;

    if (widget.supplies || (_choices.isEmpty && !offered)) return const [];

    return [
      SizedBox(height: AppSize.spaceM),
      TextMedium(s.recipe_choices_title, bold: true),
      KitchenNote(text: s.recipe_choices_note),
      for (final (index, choice) in _choices.indexed) Padding(
        key: ObjectKey(choice),
        padding: EdgeInsets.only(bottom: AppSize.spaceXS),
        child: _ChoiceCard(
          choice: choice,
          enabled: widget.canEdit,
          cost: _costIndex(index) == null ? null : (widget.cost, _costIndex(index)!),
          exclude: widget.exclude,
          onRemove: () => _removeChoice(choice),
          onAdd: (product) => _addOption(choice, product),
          onRemoveOption: (option) => _removeOption(choice, option),
          onUnit: (option, unit) {
            setState(() => option.shown = unit);
            _changed();
          },
          onMore: (option) => setState(() => option.more = !option.more)
        )
      ),
      if (offered && _choices.length < kitchenMaxChoices) Align(
        alignment: Alignment.centerLeft,
        child: Button(
          title: s.recipe_choice_add,
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          action: _addChoice
        )
      )
    ];
  }

  /// Where the [index]th choice sits among the costed ones (the last draft leaves out those that
  /// don't read whole yet); `null`: it was not costed.
  int? _costIndex(int index) {
    if (_batch || _costable(_choices[index]) == null) return null;

    return _choices.take(index).where((choice) => _costable(choice) != null).length;
  }

  Future<void> _save() async {
    final s = S.of(context);
    final drafts = <RecipeLineDraft>[];
    var valid = widget.validate?.call() ?? true;

    for (final line in _lines) {
      final (qty, waste) = _read(line);

      line.error = _lineError(line);

      if (line.error.isNotEmpty) {
        valid = false;
        // A wrong waste is said where it is written.
        if (waste == null || waste < 0 || waste >= 100) line.more = true;
        continue;
      }

      drafts.add((tableId: line.tableId, productId: line.productId, qty: qty!, negotiable: line.negotiable, waste: waste!));
    }

    final choices = <RecipeChoiceDraft>[];

    for (final choice in _choices) {
      final options = <RecipeChoiceOptionDraft>[];

      for (final option in choice.options) {
        final (qty, waste) = _read(option);

        option.error = _lineError(option);

        if (option.error.isNotEmpty) {
          valid = false;
          if (waste == null || waste < 0 || waste >= 100) option.more = true;
          continue;
        }

        options.add((tableId: option.tableId, productId: option.productId, qty: qty!, waste: waste!));
      }

      choice.error = choice.picks == null
        ? s.recipe_choice_choose_invalid(kitchenMaxChoose)
        : choice.options.length < 2 ? s.recipe_choice_options_few : "";

      if (choice.error.isNotEmpty) valid = false;

      choices.add((id: choice.id, name: choice.name.text, choose: choice.picks ?? 1, options: options));
    }

    final splits = recipeSplits([for (final choice in choices) (choose: choice.choose, options: choice.options.length)]);

    // What the customer picks is never left out: with a choice, no line has to be essential.
    _error = _lines.isEmpty && _choices.isEmpty ? s.supply_chain_lines_empty
      : _batch && _choices.isNotEmpty ? s.recipe_choice_batch
      : splits > kitchenMaxSplits ? s.recipe_choice_too_many(splits, kitchenMaxSplits)
      : _choices.isEmpty && _lines.length == drafts.length && drafts.every((line) => line.negotiable) ? s.supply_chain_lines_essential
      : "";

    setState(() {});
    if (!valid || _error.isNotEmpty) return;

    _saving.value = true;

    await widget.onSave((mode: _mode, lines: drafts, choices: choices, names: _names));

    if (mounted) _saving.value = false;
  }

  /// What is wrong with a line's (or an option's) quantity or waste; empty when nothing.
  String _lineError(_LineDraft line) {
    final s = S.of(context);

    return switch (_read(line)) {
      (null, _) => s.supply_chain_line_qty_invalid,
      (final double value, _) when value <= 0 => s.supply_chain_line_qty_invalid,
      (final double value, _) when line.supplies == false && value != value.roundToDouble() => s.supply_chain_line_qty_whole,
      (_, null) => s.supply_chain_line_waste_invalid,
      (_, final double value) when value < 0 || value >= 100 => s.supply_chain_line_waste_invalid,
      _ => ""
    };
  }
}

/// One choice, read as a sentence: «Pick [2] [Burgers]», what that means under it, then its
/// options as lines (what ONE pick takes, with what it costs), the search that adds one, and
/// what is wrong with it.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.enabled,
    required this.cost,
    required this.exclude,
    required this.onRemove,
    required this.onAdd,
    required this.onRemoveOption,
    required this.onUnit,
    required this.onMore
  });

  final _ChoiceDraft choice;
  final bool enabled;

  /// The last costing and where this choice sits among its choices; `null`: not costed.
  final (DishCost?, int)? cost;
  final Set<String> exclude;
  final void Function() onRemove;
  final void Function(KitchenProduct product) onAdd;
  final void Function(_LineDraft option) onRemoveOption;
  final void Function(_LineDraft option, KitchenUnit unit) onUnit;
  final void Function(_LineDraft option) onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return Surface.over(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
          child: Row(children: [
            Icon(CI.list, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            TextSmall(s.recipe_choice_pick, bold: true),
            SizedBox(width: AppSize.gap),
            SizedBox(width: 56, child: Input(controller: choice.choose, placeholder: "1", buttonSpace: false)),
            SizedBox(width: AppSize.gap),
            Expanded(child: Input(controller: choice.name, placeholder: s.recipe_choice_name, buttonSpace: false)),
            if (enabled) FocusableWidget(
              action: onRemove,
              message: s.recipe_choice_remove,
              child: Padding(
                padding: EdgeInsets.all(AppSize.gap),
                child: Icon(CI.trash, size: AppSize.text, color: scheme.text.secondary)
              )
            )
          ])
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSize.spaceS, 0, AppSize.spaceS, AppSize.gap),
          child: TextSmall(s.recipe_choice_rule(choice.picks ?? 1), lines: 2, color: scheme.text.secondary)
        ),
        for (final option in choice.options) ...[
          Separator.horizontal(),
          _LineRow(
            key: ObjectKey(option),
            line: option,
            optional: false,
            cost: _costOf(option),
            enabled: enabled,
            onRemove: () => onRemoveOption(option),
            onNegotiable: (_) {},
            onUnit: (unit) => onUnit(option, unit),
            onMore: () => onMore(option)
          )
        ],
        if (enabled && choice.options.length < kitchenMaxOptions) Padding(
          padding: EdgeInsets.all(AppSize.gap),
          child: KitchenProductPicker(
            placeholder: s.recipe_choice_add_option,
            exclude: {...exclude, for (final option in choice.options) option.productId},
            onPick: onAdd
          )
        ),
        if (choice.error.isNotEmpty) Padding(
          padding: EdgeInsets.fromLTRB(AppSize.spaceS, 0, AppSize.spaceS, AppSize.gap),
          child: TextSmall(choice.error, color: scheme.snackBar.error)
        )
      ])
    );
  }

  /// What one pick of [option] costs, drawn like a line's share.
  DishCostLine? _costOf(_LineDraft option) {
    final (dish, index) = cost ?? (null, 0);
    final costed = dish?.optionOf(index, option.productId);
    if (costed == null) return null;

    return (productId: costed.productId, name: costed.name, qty: 0, unitCost: costed.cost, cost: costed.cost, source: null);
  }
}

/// One line, read as a recipe reads: how much first, then of what, then whether it can go
/// without it («Optional», a tap away: the garnish, the pickles). Its waste is folded under the
/// arrow (`cocina-frontend.md` §3: «Más opciones»); folded, it still shows beside the name, so a
/// line never hides what it carries.
class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.enabled,
    required this.onRemove,
    this.optional = true,
    this.cost,
    required this.onNegotiable,
    required this.onUnit,
    required this.onMore
  });

  final _LineDraft line;

  /// Whether it can be marked «Optional»: a choice's option never is (what is picked is spent).
  final bool optional;

  /// What it adds to the cost, as last costed; `null`: not costed.
  final DishCostLine? cost;
  final bool enabled;
  final void Function() onRemove;
  final void Function(bool value) onNegotiable;
  final void Function(KitchenUnit unit) onUnit;
  final void Function() onMore;

  /// The quantity's width, the waste's too: both columns line up down the list.
  static const double _qtyWidth = 96;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final waste = kitchenParse(line.waste.text) ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
            width: _qtyWidth,
            child: Input(controller: line.qty, placeholder: s.supply_chain_line_qty, buttonSpace: false)
          ),
          SizedBox(width: AppSize.gap),
          _UnitPicker(line: line, enabled: enabled, onUnit: onUnit),
          SizedBox(width: AppSize.spaceS),
          Icon(line.supplies == false ? CI.product : CI.warehouse, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          Expanded(child: Row(children: [
            Flexible(child: TextMedium(line.name, ellipsis: true, bold: true)),
            if (!line.more && waste > 0) ...[
              SizedBox(width: AppSize.gap),
              RecipeTag(text: s.supply_chain_line_waste_of(kitchenPercent(context, waste)), color: scheme.text.secondary)
            ]
          ])),
          if (cost != null) ...[
            SizedBox(width: AppSize.gap),
            _LineCost(line: cost!)
          ],
          if (optional) ...[
            SizedBox(width: AppSize.gap),
            _OptionalToggle(
              value: line.negotiable,
              onChanged: enabled ? () => onNegotiable(!line.negotiable) : null
            )
          ],
          FocusableWidget(
            action: onMore,
            message: s.supply_chain_line_more,
            child: Padding(
              padding: EdgeInsets.all(AppSize.gap),
              child: Icon(line.more ? CI.arrow_top : CI.arrow_down, size: AppSize.text, color: scheme.text.secondary)
            )
          ),
          if (enabled) FocusableWidget(
            action: onRemove,
            message: s.supply_chain_line_remove,
            child: Padding(
              padding: EdgeInsets.all(AppSize.gap),
              child: Icon(CI.trash, size: AppSize.text, color: scheme.text.secondary)
            )
          )
        ]),
        if (line.more) Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Row(children: [
            SizedBox(
              width: _qtyWidth,
              child: Input(controller: line.waste, placeholder: s.supply_chain_line_waste, buttonSpace: false)
            ),
            SizedBox(width: AppSize.gap),
            // The percent sits where the unit sits above it: the waste reads as «5 %», like «150 g».
            SizedBox(
              width: _UnitPicker.width,
              child: Center(child: TextSmall("%", color: scheme.text.secondary))
            ),
            SizedBox(width: AppSize.spaceS),
            Expanded(child: TextSmall(s.supply_chain_line_waste_note, lines: 2, color: scheme.text.secondary))
          ])
        ),
        if (line.error.isNotEmpty) Padding(
          padding: EdgeInsets.only(top: AppSize.gap / 2),
          child: TextSmall(line.error, color: scheme.snackBar.error)
        )
      ])
    );
  }
}

/// What a line adds to the cost, or that its supply has no price (and so is not counted).
class _LineCost extends StatelessWidget {
  const _LineCost({required this.line});

  final DishCostLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final cost = line.cost;

    if (cost == null) return TextSmall(S.of(context).made_product_line_no_price, multiplier: 0.9, color: scheme.snackBar.alert);

    return TextSmall(kitchenMoney(cost), color: scheme.text.secondary);
  }
}

/// What making one costs, summed under its lines like a receipt: with a supply without a price,
/// a floor, and which ones are missing and where a price comes from. With choices, the dearest
/// pick, and between what it moves.
class _CostTotal extends StatelessWidget {
  const _CostTotal({required this.cost});

  final DishCost cost;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final missing = [
      for (final line in cost.lines)
        if (line.unitCost == null) line.name.isEmpty ? line.productId : line.name
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: TextMedium(missing.isEmpty ? s.made_product_cost_total : s.made_product_cost_floor, bold: true)),
          TextMedium(kitchenMoney(cost.cost), bold: true)
        ]),
        if (cost.range case final range?) ...[
          SizedBox(height: AppSize.gap / 2),
          TextSmall(s.made_product_cost_range(kitchenMoney(range.min), kitchenMoney(range.max)), lines: 2, color: scheme.text.secondary)
        ],
        if (missing.isNotEmpty) ...[
          SizedBox(height: AppSize.gap / 2),
          TextSmall(s.made_product_profit_incomplete(missing.join(", ")), lines: 2, color: scheme.snackBar.alert),
          TextSmall(s.made_product_cost_where, lines: 3, color: scheme.text.secondary)
        ]
      ])
    );
  }
}

/// Whether a line can be left out: a tag that is outlined while it can't and filled once it can,
/// so a list of lines says at a glance which ones are the garnish.
class _OptionalToggle extends StatelessWidget {
  const _OptionalToggle({required this.value, required this.onChanged});

  final bool value;
  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner),
        border: Border.all(color: value ? scheme.accent : scheme.line)
      ),
      child: FeedbackButton(
        action: onChanged,
        message: s.supply_chain_line_negotiable_note,
        color: value ? scheme.accent.withValues(alpha: 0.14) : scheme.surface,
        radius: AppSize.corner,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(value ? CI.check : CI.plus, size: AppSize.text * 0.85, color: value ? scheme.accent : scheme.text.secondary),
          SizedBox(width: AppSize.gap / 2),
          TextSmall(s.supply_chain_line_negotiable, multiplier: 0.9, color: value ? scheme.accent : scheme.text.secondary, bold: value)
        ])
      )
    );
  }
}

/// One of the two ways a made product is made, side by side with the other: they exclude each
/// other, and each says what it means for the stock before it is picked.
class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.title, required this.note, required this.selected, required this.action});

  final String title;
  final String note;
  final bool selected;
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.corner),
        border: Border.all(color: selected ? scheme.primary : scheme.line, width: 1.5)
      ),
      child: FeedbackButton(
        action: action,
        color: selected ? scheme.surfaceOver : scheme.surface,
        radius: AppSize.corner,
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(selected ? CI.chack_circle : CI.circle, size: AppSize.text * 1.1, color: selected ? scheme.primary : scheme.text.secondary),
          SizedBox(width: AppSize.gap),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextSmall(title, bold: true),
            SizedBox(height: AppSize.gap / 2),
            TextSmall(note, lines: 4, color: scheme.text.secondary)
          ]))
        ])
      )
    );
  }
}

/// The unit a line's quantity is written in: a weight, a volume or a length opens the units of
/// its magnitude (450 ml of a soda counted in l, 10 oz of a meat in kg), two of them switch on
/// a tap; anything else only says its own, or «units».
class _UnitPicker extends StatelessWidget {
  const _UnitPicker({required this.line, required this.enabled, required this.onUnit});

  final _LineDraft line;
  final bool enabled;
  final void Function(KitchenUnit unit) onUnit;

  static const double width = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final label = line.shown.symbol.isEmpty ? s.supply_chain_line_units : line.shown.symbol;

    if (line.units.length < 2) {
      return SizedBox(
        width: width,
        child: Center(child: TextSmall(label, color: scheme.text.secondary, ellipsis: true))
      );
    }

    final next = line.units[(line.units.indexOf(line.shown) + 1) % line.units.length];
    final menu = line.units.length > 2;

    return Builder(builder: (anchor) => FeedbackButton(
      width: width,
      height: AppSize.action,
      message: menu ? s.supply_chain_line_unit_pick : s.supply_chain_line_unit_switch(next.symbol),
      action: !enabled ? null : menu ? () => _pick(anchor) : () => onUnit(next),
      color: scheme.surface,
      child: Center(child: TextSmall(label, bold: true))
    ));
  }

  Future<void> _pick(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: [
        for (final unit in line.units) SelectOption(value: unit.symbol, placeholder: unit.symbol)
      ],
      selected: line.shown.symbol,
      maxOptions: 6,
      dense: true
    );

    if (picked == null) return;

    final unit = line.units.where((unit) => unit.symbol == picked.value).firstOrNull;
    if (unit != null) onUnit(unit);
  }
}
