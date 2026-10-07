import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';

// WIDGETS
import 'package:core/button.dart';

import './knowledge_actions.dart';
import './knowledge_body.dart';

/// The section's frame, under its providers: the bar on top, which listens to
/// nothing, and the body, the only part that listens to the questions.
///
/// The search is the header's, shared by every section, and reaches the list
/// as a [ValueListenable] so a keystroke re-filters the rows and nothing else.
class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  late final ValueListenable<String> _query = context.read<HomeService>().searchQuery;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      padding: EdgeInsets.all(AppSize.padding / 2),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextMedium(S.of(context).knowledge, bold: true, ellipsis: true),
              TextSmall(
                S.of(context).knowledge_subtitle,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          )),
          SizedBox(width: AppSize.gap),
          Button(
            width: null,
            title: S.of(context).knowledge_create,
            leftIcon: Icon(CI.plus, color: scheme.button.text),
            action: () => openKnowledgeForm(context)
          )
        ]),
        Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
        ),
        Expanded(child: KnowledgeBody(query: _query))
      ])
    );
  }
}
