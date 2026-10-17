import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/modals/supply_chain/recipe/recipe_editor.dart';

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

/// A made product written as a form (`cocina-frontend.md` §2, §3): its name, its price, the
/// table's other columns that are typed in a field, how it is made and what it consumes, all
/// saved together (the record and its recipe are one write, all or nothing).
///
/// The consumption is [RecipeEditor]'s, with the product's fields above it, so one button saves
/// everything; a line's quantity is written in its supply's unit (300 g of a meat counted in kg).
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

  /// The other columns, by FIELD_ID.
  late final Map<String, InputController> _others = {
    for (final field in _fields.others) field.id: TableFieldType.from(field.type) == TableFieldType.options
      ? InputController.select(key: field.id, form: _form, initial: _initial(field))
      : InputController(key: field.id, form: _form, max: 2000, initial: _initial(field))
  };

  String get _nameTitle => _fields.name?.name ?? S.of(context).made_product_name;

  String get _priceTitle {
    final field = _fields.price;
    if (field == null) return S.of(context).made_product_price;

    return field.unit.isEmpty ? field.name : "${field.name} (${field.unit})";
  }

  String? _initial(TableFieldModel? field) {
    final value = widget.product?.valueOf(field) ?? "";
    return value.isEmpty ? null : value;
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final consumes = widget.product?.consumes;

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
            exclude: {if (widget.product != null) widget.product!.id},
            units: widget.service.units,
            saveLabel: widget.product == null ? s.made_product_create : s.made_product_save,
            leading: _leading(context),
            validate: _form.validate,
            onSave: _save,
            onCancel: widget.onCancel
          )
        ]
      )
    );
  }

  List<Widget> _leading(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    // The name and the price are what the product is: one line, the name taking what the price
    // leaves.
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Input(
          title: _nameTitle,
          placeholder: s.made_product_name_placeholder,
          controller: _name,
          leftIcon: Icon(CI.product, color: scheme.icon),
          next: _price.focus
        )),
        SizedBox(width: AppSize.spaceS),
        SizedBox(width: 180, child: Input(
          title: _priceTitle,
          placeholder: s.made_product_price_placeholder,
          controller: _price,
          leftIcon: Icon(CI.wallet, color: scheme.icon)
        ))
      ]),
      for (final field in _fields.others) _field(context, field),
      SizedBox(height: AppSize.spaceM)
    ];
  }

  Widget _field(BuildContext context, TableFieldModel field) {
    final type = TableFieldType.from(field.type);
    final controller = _others[field.id]!;

    if (type == TableFieldType.options) {
      return SelectInput(
        title: field.name,
        placeholder: field.name,
        emptyText: S.of(context).made_product_options_empty,
        controller: controller,
        options: [for (final option in field.options) SelectOption(value: option, placeholder: option)]
      );
    }

    return Input(
      title: field.unit.isEmpty ? field.name : "${field.name} (${field.unit})",
      placeholder: field.name,
      controller: controller,
      lines: type == TableFieldType.textarea || type == TableFieldType.description ? 3 : 1
    );
  }

  Future<bool> _save(RecipeDraft draft) async {
    final s = S.of(context);
    final price = kitchenParse(_price.text);

    final done = await widget.service.save(
      context,
      product: widget.product,
      nameTitle: s.made_product_name,
      priceTitle: s.made_product_price,
      draft: (
        name: _name.text,
        price: price == null ? _price.text : kitchenField(price),
        values: {
          for (final MapEntry(:key, value: controller) in _others.entries)
            key: controller.value.trim()
        },
        mode: draft.mode,
        lines: draft.lines
      )
    );

    if (!done || !mounted) return false;

    FloatFlag.of(context).message(widget.product == null ? s.made_product_created : s.made_product_saved);
    widget.onSaved();

    return true;
  }
}
