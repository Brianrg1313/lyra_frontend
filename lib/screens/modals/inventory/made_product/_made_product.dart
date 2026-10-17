import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/modifiers/modifier_row.dart';
import 'package:app/screens/modals/supply_chain/modifier_group/_modifier_group.dart';
import 'package:app/screens/modals/supply_chain/recipe/recipe_editor.dart';

import './made_add_bar.dart';
import './made_groups.dart';
import './made_photo.dart';
import './made_profit.dart';

/// Opens the form of a made product: a new one ([product] `null`) or [product]. Answers whether
/// it was saved.
Future<bool> showMadeProduct(
  BuildContext context, {
  required MadeProductsService service,
  MadeProduct? product
}) async {
  final s = S.of(context);
  final name = product?.valueOf(service.fields.name) ?? "";
  var saved = false;

  await showSideModal(
    context: context,
    title: product == null ? s.made_product_new : name.isEmpty ? s.made_product_edit : name,
    builder: (context) => MadeProductForm(
      service: service,
      product: product,
      onSaved: () {
        saved = true;
        Navigator.pop(context);
      },
      onCancel: () => Navigator.pop(context)
    )
  );

  return saved;
}

/// A column to create with the product, as typed: its title and this product's value.
class _Detail {
  _Detail()
    : title = InputController(key: "DETAIL_TITLE_${identityHashCode(Object())}", max: 60),
      value = InputController(key: "DETAIL_VALUE_${identityHashCode(Object())}", max: 2000);

  final InputController title;
  final InputController value;

  void dispose() {
    title.dispose();
    value.dispose();
  }
}

/// A made product written as a form (`cocina-frontend.md` §2, §3, §6): its photo, its name and
/// price (with what it earns beside them), how it is made and what it consumes, always; and only
/// what is picked from the tags at its end — a description, what the customer chooses (the
/// dough) or may add (more pickles), the table's other columns and columns of its own. A section
/// that holds something opens with it; one taken off is emptied.
///
/// The record and its recipe are one write, all or nothing; the photo and the modifier groups
/// follow it ([MadeProductsService.save]). The consumption is [RecipeEditor]'s, with the
/// product's fields above it and what it offers under it, so one button saves everything.
class MadeProductForm extends StatefulWidget {
  const MadeProductForm({
    super.key,
    required this.service,
    required this.onSaved,
    required this.onCancel,
    this.product
  });

  final MadeProductsService service;
  final MadeProduct? product;
  final void Function() onSaved;
  final void Function() onCancel;

  @override
  State<MadeProductForm> createState() => _MadeProductFormState();
}

class _MadeProductFormState extends State<MadeProductForm> {
  final _form = FormController();

  MadeFields get _fields => widget.service.fields;
  MadeProduct? get _product => widget.product;

  late final _name = InputController(
    key: "NAME",
    form: _form,
    obligatory: true,
    max: 120,
    initial: _initial(_fields.name),
    customErrors: {
      InputError.empty: S.of(context).form_incomplete_ma(_nameTitle),
      InputError.incomplete: S.of(context).form_incomplete_ma(_nameTitle)
    }
  );

  late final _price = InputController(
    key: "PRICE",
    form: _form,
    obligatory: true,
    pattern: "[0-9.,]",
    max: 16,
    initial: _initial(_fields.price),
    customErrors: {
      InputError.empty: S.of(context).form_incomplete_ma(_priceTitle),
      InputError.incomplete: S.of(context).form_incomplete_ma(_priceTitle)
    }
  );

  late final _description = InputController(key: "DESCRIPTION", form: _form, max: 2000, initial: _initial(_fields.description));

  /// The other columns, by FIELD_ID.
  late final Map<String, InputController> _others = {
    for (final field in _fields.others) field.id: TableFieldType.from(field.type) == TableFieldType.options
      ? InputController.select(key: field.id, form: _form, initial: _initial(field))
      : InputController(key: field.id, form: _form, max: 2000, initial: _initial(field))
  };

  /// Whether the description is shown: when it holds one, or once added.
  late bool _describing = _initial(_fields.description) != null;

  /// The other columns shown, by FIELD_ID: those that hold something, and those added.
  late final Set<String> _shown = {
    for (final field in _fields.others) if (_initial(field) != null) field.id
  };

  final List<_Detail> _details = [];

  MadePhoto _photo = const MadePhoto.keep();

  /// The groups it offers, each without itself among their products (see [MadeGroupChoice]).
  late List<MadeGroupChoice> _groups = [
    if (_product != null)
      for (final group in widget.service.groupsOf(_product!.id)) (group: _without(group, _product!.id), edited: false)
  ];

  bool _groupsTouched = false;

  DishCost? _cost;

  bool get _canEditGroups => PermissionsService().can("supply_chain.modifiers.edit");

  String get _nameTitle => _fields.name?.name ?? S.of(context).made_product_name;

  String get _priceTitle {
    final field = _fields.price;
    if (field == null) return S.of(context).made_product_price;

    return field.unit.isEmpty ? field.name : "${field.name} (${field.unit})";
  }

  String? _initial(TableFieldModel? field) {
    final value = _product?.valueOf(field) ?? "";
    return value.isEmpty ? null : value;
  }

  static ModifierGroup _without(ModifierGroup group, String productId) => ModifierGroup(
    id: group.id,
    name: group.name,
    min: group.min,
    max: group.max,
    position: group.position,
    products: [for (final product in group.products) if (product.productId != productId) product],
    options: group.options
  );

  @override
  void initState() {
    super.initState();

    final product = _product;
    if (product != null) {
      widget.service.costOf(product.id).then((cost) {
        if (mounted) setState(() => _cost = cost);
      });
    }
  }

  @override
  void dispose() {
    _form.dispose();
    for (final detail in _details) {
      detail.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final consumes = _product?.consumes;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 620, maxWidth: 620),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecipeEditor(
            recipe: consumes?.recipe,
            supplies: false,
            canEdit: PermissionsService().can("supply_chain.recipes.edit"),
            exclude: {if (_product != null) _product!.id},
            units: widget.service.units,
            saveLabel: _product == null ? s.made_product_create : s.made_product_save,
            leading: _leading(context),
            validate: _validate,
            onSave: _save,
            onCancel: widget.onCancel
          )
        ]
      )
    );
  }

  /// What the product is (its photo beside its name, its price and what that price earns), then
  /// the tags of what it can still be given, then what was added to it: the tags come first so
  /// what a product can hold is seen before its recipe, and a picked section opens right under them.
  List<Widget> _leading(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.only(top: AppSize.spaceXS),
          child: MadePhotoTile(
            cover: _product?.cover,
            photo: _photo,
            enabled: _fields.image != null || _product == null,
            onChanged: (photo) => setState(() => _photo = photo)
          )
        ),
        SizedBox(width: AppSize.spaceM),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Input(
            title: _nameTitle,
            placeholder: s.made_product_name_placeholder,
            controller: _name,
            leftIcon: Icon(CI.product, color: scheme.icon),
            next: _price.focus
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 168, child: Input(
              title: _priceTitle,
              placeholder: s.made_product_price_placeholder,
              controller: _price,
              leftIcon: Icon(CI.wallet, color: scheme.icon)
            )),
            SizedBox(width: AppSize.spaceS),
            // Lined up with the price's box, under its title.
            Expanded(child: Padding(
              padding: EdgeInsets.only(top: AppSize.text * 1.6),
              child: MadeProfit(price: _price.textController, cost: _cost, saved: _product != null)
            ))
          ])
        ]))
      ]),
      _addBar(context),
      if (_describing) MadeSection(
        title: _fields.description?.name ?? s.made_product_description,
        onRemove: () => setState(() {
          _describing = false;
          _description.textController.clear();
        }),
        child: Input(
          placeholder: s.made_product_description_placeholder,
          controller: _description,
          lines: 3,
          buttonSpace: false
        )
      ),
      ..._added(context),
      SizedBox(height: AppSize.spaceM)
    ];
  }

  /// What it offers and the columns added to it.
  List<Widget> _added(BuildContext context) {
    final s = S.of(context);
    final choices = [for (final choice in _groups) if (choice.group.required) choice];
    final extras = [for (final choice in _groups) if (!choice.group.required) choice];

    return [
      if (choices.isNotEmpty) MadeGroupsBlock(
        title: s.made_product_choices_title,
        note: s.made_product_choices_note,
        choices: choices,
        enabled: _canEditGroups,
        onOpen: _editGroup,
        onDetach: _detach
      ),
      if (extras.isNotEmpty) MadeGroupsBlock(
        title: s.made_product_extras_title,
        note: s.made_product_extras_note,
        choices: extras,
        enabled: _canEditGroups,
        onOpen: _editGroup,
        onDetach: _detach
      ),
      for (final field in _fields.others)
        if (_shown.contains(field.id)) MadeSection(
          title: field.unit.isEmpty ? field.name : "${field.name} (${field.unit})",
          onRemove: () => setState(() {
            _shown.remove(field.id);
            _others[field.id]!.textController.clear();
          }),
          child: _field(context, field)
        ),
      for (final detail in _details) MadeSection(
        key: ObjectKey(detail),
        title: s.made_product_add_detail,
        onRemove: () => setState(() {
          _details.remove(detail);
          detail.dispose();
        }),
        child: Row(children: [
          SizedBox(width: 200, child: Input(controller: detail.title, placeholder: s.made_product_detail_name, buttonSpace: false)),
          SizedBox(width: AppSize.gap),
          Expanded(child: Input(controller: detail.value, placeholder: s.made_product_detail_value, buttonSpace: false))
        ])
      )
    ];
  }

  /// The tags of what the product can still be given.
  Widget _addBar(BuildContext context) {
    final s = S.of(context);

    return MadeAddBar(title: s.made_product_add_title, items: [
        if (!_describing) (
          icon: CI.documents,
          label: _fields.description?.name ?? s.made_product_description,
          note: s.made_product_add_description_note,
          action: (_) => setState(() => _describing = true)
        ),
        if (_canEditGroups) ...[
          (icon: CI.list, label: s.made_product_add_choice, note: s.made_product_add_choice_note, action: (anchor) => _addGroup(anchor, required: true)),
          (icon: CI.shopping_add, label: s.made_product_add_extras, note: s.made_product_add_extras_note, action: (anchor) => _addGroup(anchor, required: false))
        ],
        for (final field in _fields.others)
          if (!_shown.contains(field.id)) (
            icon: CI.tables,
            label: field.name,
            note: s.made_product_add_field_note,
            action: (_) => setState(() => _shown.add(field.id))
          ),
        (icon: CI.edit, label: s.made_product_add_detail, note: s.made_product_add_detail_note, action: (_) => setState(() => _details.add(_Detail())))
      ]);
  }

  Widget _field(BuildContext context, TableFieldModel field) {
    final type = TableFieldType.from(field.type);
    final controller = _others[field.id]!;

    if (type == TableFieldType.options) {
      return SelectInput(
        placeholder: field.name,
        emptyText: S.of(context).made_product_options_empty,
        controller: controller,
        options: [for (final option in field.options) SelectOption(value: option, placeholder: option)]
      );
    }

    return Input(
      placeholder: field.name,
      controller: controller,
      buttonSpace: false,
      lines: type == TableFieldType.textarea ? 3 : 1
    );
  }

  /// A choice (one at least, the dough) or extras (none needed, more pickles): one the company
  /// already has, offered here too, or a new one. With none of that kind, straight to a new one.
  Future<void> _addGroup(BuildContext anchor, {required bool required}) async {
    final s = S.of(anchor);
    final offered = {for (final choice in _groups) choice.group.id};
    final known = [
      for (final group in widget.service.groups)
        if (group.required == required && !offered.contains(group.id)) group
    ];

    ModifierGroup? existing;

    if (known.isNotEmpty) {
      final picked = await showSelectMenu(
        context: anchor,
        options: [
          SelectOption(
            value: "",
            placeholder: required ? s.made_product_group_new_choice : s.made_product_group_new_extras,
            subtitle: s.made_product_group_new_note,
            icon: CI.plus
          ),
          for (final group in known) SelectOption(
            value: group.id,
            placeholder: group.name,
            subtitle: s.made_product_group_use_note(modifierRule(anchor, group), group.options.length)
          )
        ]
      );

      if (picked == null || !mounted) return;

      existing = known.where((group) => group.id == picked.value).firstOrNull;
    }

    if (existing != null) {
      final group = _product == null ? existing : _without(existing, _product!.id);
      return setState(() {
        _groups = [..._groups, (group: group, edited: false)];
        _groupsTouched = true;
      });
    }

    if (!mounted) return;

    final draft = await showModifierGroupForm(
      context,
      pinned: _pinned,
      deletable: false,
      min: required ? 1 : 0,
      max: required ? 1 : null,
      title: required ? s.made_product_group_new_choice : s.made_product_group_new_extras
    );

    if (draft == null || !mounted) return;

    setState(() {
      _groups = [..._groups, (group: _group(draft), edited: true)];
      _groupsTouched = true;
    });
  }

  Future<void> _editGroup(MadeGroupChoice choice) async {
    final draft = await showModifierGroupForm(
      context,
      group: choice.group,
      canEdit: _canEditGroups,
      pinned: _pinned,
      deletable: false
    );

    if (draft == null || !mounted) return;

    setState(() {
      _groups = [
        for (final known in _groups)
          if (identical(known, choice)) (group: _group(draft, id: choice.group.id, position: choice.group.position), edited: true) else known
      ];
      _groupsTouched = true;
    });
  }

  void _detach(MadeGroupChoice choice) => setState(() {
    _groups = [for (final known in _groups) if (!identical(known, choice)) known];
    _groupsTouched = true;
  });

  /// This product as the group form names it: its name as typed.
  String get _pinned {
    final name = _name.text.trim();
    return name.isEmpty ? S.of(context).made_product_new : name;
  }

  static ModifierGroup _group(ModifierGroupDraft draft, {String id = "", int position = 0}) => ModifierGroup(
    id: id,
    name: draft.name,
    min: draft.min,
    max: draft.max,
    position: position,
    products: draft.products,
    options: draft.options
  );

  /// The product's own fields, beside the recipe's lines; an added column needs its title.
  bool _validate() {
    var valid = _form.validate();

    for (final detail in _details) {
      if (detail.value.text.trim().isNotEmpty && detail.title.text.trim().isEmpty) valid = false;
    }

    return valid;
  }

  Future<bool> _save(RecipeDraft draft) async {
    final s = S.of(context);
    final price = kitchenParse(_price.text);

    final done = await widget.service.save(
      context,
      product: _product,
      nameTitle: s.made_product_name,
      priceTitle: s.made_product_price,
      descriptionTitle: s.made_product_description,
      draft: (
        name: _name.text,
        price: price == null ? _price.text : kitchenField(price),
        description: _description.text,
        values: {
          for (final MapEntry(:key, value: controller) in _others.entries)
            key: controller.value.trim()
        },
        added: {
          for (final detail in _details)
            if (detail.title.text.trim().isNotEmpty && detail.value.text.trim().isNotEmpty)
              detail.title.text.trim(): detail.value.text.trim()
        },
        photo: _photo,
        mode: draft.mode,
        lines: draft.lines,
        groups: _groupsTouched ? _groups : null
      )
    );

    if (!done || !mounted) return false;

    FloatFlag.of(context).message(_product == null ? s.made_product_created : s.made_product_saved);
    widget.onSaved();

    return true;
  }
}
