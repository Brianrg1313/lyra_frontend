import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import 'package:core/form.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({
    required this.isExpanded,
    super.key
  });

  final bool isExpanded;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSize.padding),
    child: widget.isExpanded
    ? SearchInput(
        controller: InputController.search(),
        placeholder: S.of(context).search_in_app,
        fillColor: ThemeColor.of(context).surfaceFeedback,
        onSearch: (String value) {  }
      )
    : FeedbackButton(
        feedbackColor: ThemeColor.of(context).line,
        child: SizedBox(
          width: AppSize.action,
          height: AppSize.action,
          child: Center(child: Icon(CI.search))
        )
      )
  );
}
