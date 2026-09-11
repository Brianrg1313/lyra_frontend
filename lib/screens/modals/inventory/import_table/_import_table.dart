import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/import_source.dart';

// WIDGETS
import 'package:core/form.dart';

import 'source_row.dart';

/// Where to bring the content of a table from. It opens from the import button
/// of the list ([InventorySection]) and **does not import anything on its
/// own**: it closes returning the chosen [ImportSource.value], and the flow
/// that corresponds is opened by whoever called it. It returns `null` if it
/// was closed without choosing.
///
/// It is a list and not a form because each source is a different path:
/// uploading a spreadsheet opens the system dialog, a store is going to ask to
/// connect the account. The only common thing is the choice, and that is what
/// this modal does.
///
/// Today the only one that works is [ImportSource.spreadsheet]; the rest are
/// shown dimmed with their "coming soon" tag (see [ImportSourceRow]) and turn
/// on one by one.
class ImportTableModal extends StatefulWidget {
  const ImportTableModal({super.key});

  @override
  State<ImportTableModal> createState() => _ImportTableModalState();
}

class _ImportTableModalState extends State<ImportTableModal> {
  /// What the modal measures on desktop, where it is measured against its
  /// content: the width of a comfortable row and the height of what fits
  /// without covering the window. On a phone the sheet takes the screen and
  /// rules: the window height overrides [_maxHeight] and the width the
  /// [SizedBox].
  static double get _width => AppSize.action * 9;
  static double get _maxHeight => AppSize.action * 10;

  final _form = FormController();

  late final _search = InputController.search(form: _form);

  /// What was written in the search box, lowercased and without spaces on the
  /// borders. Empty is the whole list.
  ///
  /// It is a [ValueNotifier] and not screen state so that writing rebuilds
  /// only the list, and not also the field in which it is being written.
  final _query = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();

    // The text is listened and not the field's `onSearch`: that one waits
    // until typing stops because it is meant to search against the backend,
    // and here there is nothing to ask for —the sources are a dozen and are
    // already in memory—, so the list is filtered keystroke by keystroke.
    _search.textController.addListener(_write);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_write);
    _form.dispose();
    _query.dispose();
    super.dispose();
  }

  void _write() => _query.value = _search.text.trim().toLowerCase();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _width,
    // The height cap is not only aesthetic: it is what gives a bounded height
    // to the column, and without it the list could not go in a [Flexible]. On
    // desktop the modal is measured against its content and arrives with no
    // height to share, so a flexible child there would throw in the build.
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: _maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(
            S.of(context).import_source_subtitle,
            lines: 2,
            color: ThemeColor.of(context).text.secondary
          ),
          SizedBox(height: AppSize.spaceXS),
          SearchInput(
            controller: _search,
            placeholder: S.of(context).import_source_search,
            radius: AppSize.cornerInset(AppSize.gap),
            // The filtering goes through [_write], which runs on each key.
            // This one stays the same for Enter, which has no reason to do
            // nothing.
            onSearch: (_) => _write()
          ),
          SizedBox(height: AppSize.spaceS),
          Flexible(child: ValueListenableBuilder<String>(
            valueListenable: _query,
            builder: (context, query, _) => _List(query: query)
          ))
        ]
      )
    )
  );
}

/// The sources that fit the search, grouped like in the catalog. It is the
/// only thing that repaints when typing.
class _List extends StatelessWidget {
  const _List({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final group in ImportSource.groups(context))
        ?group.search(query)
    ];

    // It is not just any empty: there are sources, but none is called that.
    // It is said and the search box is left where it is to be able to correct
    // what was written.
    if (groups.isEmpty) {
      return Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
        child: TextMedium(
          S.of(context).import_source_search_empty,
          lines: 2,
          textAlign: TextAlign.center,
          color: ThemeColor.of(context).text.secondary
        )
      ));
    }

    return ScrollableWidget(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < groups.length; i++) ...[
          if (i > 0) SizedBox(height: AppSize.spaceS),
          _Group(group: groups[i])
        ]
      ]
    );
  }
}

/// A group of sources with its title: where the file comes from, from which
/// application it is brought, and —at the end— the loose formats.
class _Group extends StatelessWidget {
  const _Group({required this.group});

  final ImportSourceGroup group;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap),
        child: TextSmall(
          group.label,
          color: ThemeColor.of(context).text.secondary
        )
      ),
      for (int i = 0; i < group.sources.length; i++) ...[
        if (i > 0) SizedBox(height: AppSize.gap),
        ImportSourceRow(
          source: group.sources[i],
          // The modal only answers that something was chosen: whoever opened
          // it knows what to do with that and is the one that stays on screen
          // when this box is no longer there.
          action: (value) => Navigator.pop(context, value)
        )
      ]
    ]
  );
}