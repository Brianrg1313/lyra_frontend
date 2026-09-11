import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_method_model.dart';

/// One of the company's accounts, as a block over the body's sheet.
///
/// What is written on it is what a customer is actually told —who the account
/// is under, at which institution, and the number— because that is what the row
/// exists for: it is the answer to "como te pago". The rail's own name is the
/// small line above, since two rows of the same rail are told apart by the name
/// the company gave them and not by the rail.
///
/// **What is on it is what the rail asks for**, and each line is called what
/// that rail calls it ([fields]): under a Pago Movil the bank is "Banco" and
/// the number is "Telefono", and there is no holder because a Pago Movil has
/// none. Labelling the four columns of the table instead —"institution",
/// "account"— would be writing the database's vocabulary on the one card that
/// exists to be read out loud to a customer.
///
/// The card carries its own two actions rather than a menu: there are only two,
/// and one of them is destructive enough to be worth seeing before it is
/// needed.
class MoneyMethodCard extends StatelessWidget {
  const MoneyMethodCard({
    super.key,
    required this.method,
    required this.fields,
    required this.onEdit,
    required this.onRemove
  });

  final MoneyMethod method;

  /// The rail's requirement sheet: which lines this account has, and what each
  /// one is called. Empty for a rail nothing is known about —one withdrawn
  /// after the row was created, or a catalog that did not arrive— and then the
  /// card falls back to the four generic names, which is the reading it had
  /// before any sheet existed.
  final List<MoneyMethodField> fields;

  final void Function() onEdit;
  final void Function() onRemove;

  /// Wide enough for a bank account number without wrapping it, which is the
  /// one string on this card that must be readable in one piece.
  static const double _width = 320;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: _width,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: TextSmall(
                // The rail's name as the catalog writes it, and its code when
                // the catalog has no name for it: an empty line here would make
                // two accounts of different rails look like the same one.
                method.name.isNotEmpty ? method.name : method.code,
                color: scheme.text.secondary,
                ellipsis: true
              )),
              FocusableWidget(
                action: onEdit,
                message: S.of(context).edit,
                child: Icon(
                  CI.edit,
                  size: AppSize.text * 1.1,
                  color: scheme.text.secondary
                )
              ),
              SizedBox(width: AppSize.spaceXS),
              FocusableWidget(
                action: onRemove,
                message: S.of(context).finance_method_remove,
                child: Icon(
                  CI.trash,
                  size: AppSize.text * 1.1,
                  color: scheme.snackBar.error
                )
              )
            ]),
            SizedBox(height: AppSize.gap),
            TextMedium(method.title, bold: true, ellipsis: true),
            ..._lines(context),
            if (method.instructions.isNotEmpty) ...[
              SizedBox(height: AppSize.gap),
              TextSmall(
                method.instructions,
                color: scheme.text.secondary,
                multiplier: 0.9,
                lines: 3
              )
            ]
          ]
        )
      )
    );
  }

  /// The account, line by line: what the rail asks for, in the order it asks
  /// for it, and only what the company actually filled in — an optional field
  /// left empty is not a blank row, it is a line this account does not have.
  List<Widget> _lines(BuildContext context) {
    final sheet = fields.isNotEmpty ? fields : _fallback(context);

    final lines = [
      for (final field in sheet)
        if (method.field(field.field).isNotEmpty) _Field(
          label: field.label,
          value: method.field(field.field),
          // The number is the one thing on this card somebody copies out of it
          // to paste into a chat.
          selectable: field.field == "account"
        )
    ];

    return lines.isEmpty ? const [] : [SizedBox(height: AppSize.gap), ...lines];
  }

  /// What the four columns are called when no sheet says otherwise. It is the
  /// generic reading and the honest one: a rail nobody can ask about is one
  /// whose bank this app cannot claim to know is a bank.
  List<MoneyMethodField> _fallback(BuildContext context) => [
    MoneyMethodField(
      field: "holder",
      label: S.of(context).finance_method_holder
    ),
    MoneyMethodField(
      field: "document",
      label: S.of(context).finance_method_document
    ),
    MoneyMethodField(
      field: "institution",
      label: S.of(context).finance_method_institution
    ),
    MoneyMethodField(
      field: "account",
      label: S.of(context).finance_method_account
    )
  ];
}

/// A line of the card: what it is, and what the company wrote.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.selectable = false
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSize.action * 1.8,
            child: TextSmall(
              label,
              color: scheme.text.secondary,
              multiplier: 0.9,
              ellipsis: true
            )
          ),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            value,
            selectable: selectable,
            ellipsis: !selectable,
            multiplier: 0.9
          ))
        ]
      )
    );
  }
}
