import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './_employee_facts.dart';
import './employee_search.dart';

/// A group of the panel: its title straight on the panel and its content
/// below, with no card of its own — the tiles inside are the cards.
class EmployeeSection extends StatelessWidget {
  const EmployeeSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final search = EmployeeSearch.of(context);

    // Searching, a section named like the query shows whole; any other keeps
    // only the tiles that match, and goes away when none does.
    if (search.isNotEmpty && !search.matches(title)) {
      final hits = [
        for (final child in children)
          if (child is EmployeeFacts && child.facts.any(search.tile)) child
      ];

      if (hits.isEmpty) return const SizedBox.shrink();

      return _body(context, hits);
    }

    return EmployeeSearch(query: "", child: Builder(builder: (context) => _body(context, children)));
  }

  Widget _body(BuildContext context, List<Widget> children) => Padding(
    padding: EdgeInsets.only(bottom: AppSize.spaceS),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 0.5),
          // Inter, like the person's name above: the section titles are the
          // panel's second level under it.
          child: TextInter(title, bold: true, multiplier: 1.1, ellipsis: true)
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppSize.gap * 0.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 0.5),
            child: TextSmall(subtitle!, lines: 3, ellipsis: true, color: ThemeColor.of(context).text.secondary)
          )
        ],
        SizedBox(height: AppSize.gap),
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: AppSize.gap),
          children[i]
        ]
      ]
    )
  );
}
