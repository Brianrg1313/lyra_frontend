import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/supply_chain/modifiers/modifier_row.dart' show modifierRule;
import 'package:app/screens/pos/desktop/pos_currency.dart';

/// Asks what the customer chooses about [product] before it goes on the ticket
/// (`cocina-frontend.md` §6). Answers the picks, or null when closed: the product then isn't
/// rung up.
Future<List<PosModifierPick>?> showPosModifiers(
  BuildContext context, {
  required String product,
  required List<ModifierGroup> groups,
  required CurrencyModel currency
}) => showModal(
  context: context,
  title: product,
  builder: (context) => PosModifiersModal(groups: groups, currency: currency)
).then((value) => value is List<PosModifierPick> ? value : null);

/// The groups of a product, each with its rule («Choose one», «Up to 3») and its options.
///
/// An option with nothing left (`available: 0`, or paused) is greyed out and can't be picked;
/// one that spends nothing (`available: null`) always can. A group of one choice swaps it, the
/// rest toggle up to their `max`. The confirm stays off until every group has between `min`
/// and `max`: the backend would refuse the line (`invalid_modifiers`).
///
/// **Prices are said, never added**: what the line costs is the backend's answer (product +
/// options), so the ticket shows the price that comes back.
class PosModifiersModal extends StatefulWidget {
  const PosModifiersModal({super.key, required this.groups, required this.currency});

  final List<ModifierGroup> groups;
  final CurrencyModel currency;

  @override
  State<PosModifiersModal> createState() => _PosModifiersModalState();
}

class _PosModifiersModalState extends State<PosModifiersModal> {
  static const double _width = 440;

  /// The picked option ids, by group id.
  final Map<String, List<String>> _picked = {};

  bool _ready(ModifierGroup group) {
    final count = _picked[group.id]?.length ?? 0;
    final max = group.max;

    return count >= group.min && (max == null || count <= max);
  }

  bool get _complete => widget.groups.every(_ready);

  void _toggle(ModifierGroup group, ModifierOption option) => setState(() {
    final picked = _picked.putIfAbsent(group.id, () => []);

    if (picked.contains(option.id)) {
      picked.remove(option.id);
      return;
    }

    if (group.max == 1) picked.clear();
    if (group.max != null && picked.length >= group.max!) return;

    picked.add(option.id);
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Flexible(child: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final group in widget.groups) _group(context, group)]
      ))),
      SizedBox(height: AppSize.spaceS),
      IgnorePointer(
        ignoring: !_complete,
        child: Opacity(
          opacity: _complete ? 1 : 0.4,
          child: MainButton(title: S.of(context).pos_modifiers_add, action: _submit)
        )
      )
    ])
  );

  Widget _group(BuildContext context, ModifierGroup group) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceS),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextMedium(group.name, bold: true, ellipsis: true)),
          TextSmall(
            modifierRule(context, group),
            color: _ready(group) ? scheme.text.secondary : scheme.snackBar.error
          )
        ]),
        SizedBox(height: AppSize.gap),
        Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
          for (final option in group.options) _Option(
            option: option,
            price: option.price > 0 ? "+${posAmount(widget.currency, option.price)}" : "",
            selected: _picked[group.id]?.contains(option.id) ?? false,
            action: option.paused || option.available == 0 ? null : () => _toggle(group, option)
          )
        ])
      ])
    );
  }

  void _submit() => Navigator.pop(context, <PosModifierPick>[
    for (final group in widget.groups)
      for (final option in _picked[group.id] ?? const <String>[]) (group: group.id, option: option)
  ]);
}

/// One option: its name and what it adds, framed when picked, dimmed when there is none left.
class _Option extends StatelessWidget {
  const _Option({required this.option, required this.price, required this.selected, this.action});

  final ModifierOption option;
  final String price;
  final bool selected;

  /// Null when there is nothing left of it.
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final enabled = action != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: FeedbackButton(
        action: action,
        message: enabled ? null : S.of(context).pos_modifiers_none_left,
        radius: AppSize.corner,
        color: selected ? scheme.input.focus : scheme.surfaceOver,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected) ...[
            Icon(CI.check, size: AppSize.text, color: scheme.primary),
            SizedBox(width: AppSize.gap)
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: TextSmall(option.name, ellipsis: true)
          ),
          if (price.isNotEmpty) ...[
            SizedBox(width: AppSize.gap),
            TextSmall(price, color: scheme.text.secondary)
          ]
        ])
      )
    );
  }
}
