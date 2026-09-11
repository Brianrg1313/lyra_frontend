import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/import_source.dart';

/// A source from which the content of a table can be brought, in the list of
/// the import modal: its icon, what it is called and what it brings.
///
/// The one that does not exist yet ([ImportSource.ready] in `false`) is drawn
/// the same but dimmed —no action, grey text and the "coming soon" tag on the
/// right—, and it is not taken out of the list: what is being shown is where
/// the inventory is going to be able to come in, and a one-row list would not
/// say that.
class ImportSourceRow extends StatelessWidget {
  const ImportSourceRow({super.key, required this.source, required this.action});

  final ImportSource source;

  /// What to do with the chosen source. Only the ones that already work call
  /// it.
  final void Function(String value) action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = source.ready ? scheme.text.primary : scheme.text.secondary;

    return FeedbackButton(
      action: source.ready ? () => action(source.value) : null,
      // The hand cursor is the promise that something happens when touched: on
      // the one that is not, the arrow is left.
      mouseCursor: source.ready ? null : SystemMouseCursors.basic,
      color: scheme.surface,
      padding: EdgeInsets.all(AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.spaceS),
      message: source.label,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.5),
            child: Icon(
              source.icon,
              size: AppSize.text * 1.2,
              color: source.ready ? scheme.icon : scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                source.label,
                bold: true,
                ellipsis: true,
                color: color
              ),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                source.hint,
                lines: 2,
                color: scheme.text.secondary
              )
            ]
          )),
          if (!source.ready) ...[
            SizedBox(width: AppSize.spaceXS),
            Padding(
              padding: EdgeInsets.only(top: AppSize.gap * 0.5),
              child: const _SoonTag()
            )
          ]
        ]
      )
    );
  }
}

/// The tag of the source that is not there yet. It goes in the notice color
/// and not in a red: it is not an error, it is something that is missing.
class _SoonTag extends StatelessWidget {
  const _SoonTag();

  @override
  Widget build(BuildContext context) {
    final color = ThemeColor.of(context).accent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.gap,
        vertical: AppSize.gap * 0.4
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: TextSmall(S.of(context).import_source_soon, color: color)
    );
  }
}