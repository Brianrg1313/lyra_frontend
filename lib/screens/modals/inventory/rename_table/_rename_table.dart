import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Changes the name of a product table, and nothing else.
///
/// It is a single-field form because the title is the only thing in the header
/// that is corrected looking at the list: it is what is read from the table
/// when one has not entered it yet. The rest of what can be changed —the
/// description, the column types, how much the model sees— is changed in the
/// table settings, which is the other option of the same menu
/// ([TableOptionsButton]).
///
/// It is the difference with [EditTableDetailsModal], the single-field form of
/// those settings: that one writes against `PUT /inventory/products/builder/details/` the data point that was
/// touched in the card, and this one writes the title against the structure
/// ([TablesService.edit]), which is where the list comes from.
///
/// The description travels the same even though it is not shown: the structure
/// endpoint rewrites the whole header, so sending it empty would erase it (see
/// `editTableRequest`).
///
/// It closes returning `true` when the change went through, so whoever opened
/// it knows that there was one. The list row does not need to do anything with
/// that: the service already corrected it.
class RenameTableModal extends StatefulWidget {
  const RenameTableModal({super.key, required this.table});

  final TableLiteModel table;

  @override
  State<RenameTableModal> createState() => _RenameTableModalState();
}

class _RenameTableModalState extends State<RenameTableModal> {
  final _form = FormController();

  /// The same character set the create accepts: it is the same table name,
  /// written at another time.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]";

  /// Width of the form. Fixed and not a maximum, same as the card one: the
  /// modal adjusts to what its content measures, and a short title would leave
  /// it narrower than its own button. In a small window the dialog clips it on
  /// its own.
  static const double _width = 400;

  late final _title = InputController(
    key: "TITLE",
    form: _form,
    initial: widget.table.title,
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

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextMedium(S.of(context).rename_table_subtitle)
        ),
        Input(
          title: S.of(context).table_title_input,
          placeholder: S.of(context).table_title_placeholder,
          controller: _title,
          leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
          autofocus: true,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    // Nothing to save: it closes without writing. A write to leave the title
    // as it was is a trip to the backend that changes nothing.
    if (_title.value.trim() == widget.table.title.trim()) {
      Navigator.pop(context);
      return;
    }

    _form.loading.value = true;

    final saved = await context.read<TablesService>().edit(
      context,
      widget.table,
      title: _title.value,
      description: widget.table.description
    );

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown in the service: the modal
    // stays open with what was written to correct it or close it by hand.
    if (!saved) return;

    FloatFlag.of(context).message(S.of(context).table_renamed);
    Navigator.pop(context, true);
  }
}