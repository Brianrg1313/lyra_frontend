import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';

import './filter_chip.dart';

/// A chip that opens its list anchored to itself.
///
/// It is [showSelectMenu] and not a [SelectInput] on purpose: an input would
/// need a controller of its own —created, rebuilt when the options change and
/// disposed— to hold a value the filter bar already reads off its service.
class SectionMenuChip extends StatelessWidget {
  const SectionMenuChip({
    super.key,
    required this.title,
    required this.isActive,
    required this.selected,
    required this.options,
    required this.onSelected,
    required this.emptyText,
    this.icon,
    this.leading,
    this.maxOptions = 5
  });

  final IconData? icon;

  /// Drawn instead of [icon] when the chosen value has a mark of its own — a
  /// state's dot (the sales board's stage filter).
  final Widget? leading;

  final String title;
  final bool isActive;

  /// The value currently on, so the open list shows its tick.
  final String selected;

  final List<SelectOption> options;

  /// How many options the list shows before it scrolls.
  final int maxOptions;

  final void Function(String value) onSelected;

  /// What the open list says when nothing matches what was typed in it.
  final String emptyText;

  @override
  Widget build(BuildContext context) => SectionFilterChip(
    icon: icon,
    leading: leading,
    title: title,
    isActive: isActive,
    trailing: CI.arrow_down,
    action: () async {
      final option = await showSelectMenu(
        context: context,
        options: options,
        selected: selected,
        maxOptions: maxOptions,
        emptyText: emptyText
      );

      if (option != null) onSelected(option.value);
    }
  );
}
