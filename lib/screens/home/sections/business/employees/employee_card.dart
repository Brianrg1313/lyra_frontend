import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

import './employee_format.dart';

/// The shapes the detail panel is drawn with: a titled section, a grid of
/// data tiles, a dated event, a note and the header's quick actions.
///
/// The panel reads as a personnel file: each group of data is one sheet
/// ([EmployeeFacts]) and its data are cells of it, not a card each. A cell
/// only lights up under the pointer, and says what a click does (edit, copy,
/// unfold) only then: thirty pencils at rest are noise. The one cell that
/// stands out is the one being edited ([EmployeeFactFrame.accent]).

/// Copies [value] and says which datum went to the clipboard.
Future<void> employeeCopy(BuildContext context, String value, String label) async {
  await Clipboard.setData(ClipboardData(text: value));

  if (!context.mounted) return;

  FloatFlag.of(context).message(S.of(context).employee_copied(label));
}

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

/// Tiles two by two, one per row when the panel is too narrow for two values
/// to be read. A [EmployeeTile.wide] one takes the whole row: an address cut in
/// half says nothing.
class EmployeeFacts extends StatelessWidget {
  const EmployeeFacts({super.key, required this.facts});

  /// Tiles: [EmployeeFact] or the editable ones (`employee_edit.dart`).
  final List<Widget> facts;

  @override
  Widget build(BuildContext context) {
    final search = EmployeeSearch.of(context);
    final shown = search.isEmpty ? facts : facts.where(search.tile).toList();
    final gap = AppSize.gap * 0.5;

    // One sheet for the group; the cells inside are only lit under the pointer.
    return Surface(
      color: ThemeColor.of(context).surface,
      radius: EmployeeFactFrame.sheetRadius,
      padding: EdgeInsets.all(gap),
      child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < AppSize.action * 8 ? 1 : 2;
        final half = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            // Keyed by what the tile is: a search drops tiles in between, and a
            // tile being edited must keep its own slot.
            for (final fact in shown) _Slot(
              key: fact.key ?? (fact is EmployeeTile ? ValueKey((fact as EmployeeTile).label) : null),
              width: fact is EmployeeTile && (fact as EmployeeTile).wide ? constraints.maxWidth : half,
              full: constraints.maxWidth,
              child: fact
            )
          ]
        );
      })
    );
  }
}

/// Sent up by a tile whose field needs the whole row while it is edited (a
/// phone's code and number, a day's three parts): half a row cannot hold them.
class EmployeeWiden extends Notification {
  const EmployeeWiden(this.wide);

  final bool wide;
}

/// One tile's room in [EmployeeFacts], widened on an [EmployeeWiden].
class _Slot extends StatefulWidget {
  const _Slot({super.key, required this.width, required this.full, required this.child});

  final double width;
  final double full;
  final Widget child;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> {
  bool _wide = false;

  @override
  Widget build(BuildContext context) => NotificationListener<EmployeeWiden>(
    onNotification: (notice) {
      if (notice.wide != _wide) setState(() => _wide = notice.wide);
      return true;
    },
    child: SizedBox(width: _wide ? widget.full : widget.width, child: widget.child)
  );
}

/// A tile of [EmployeeFacts], read-only or editable.
abstract interface class EmployeeTile {
  /// Takes the whole row.
  bool get wide;

  /// What the datum is called and what it reads: what [EmployeeSearch] finds.
  String get label;
  String get value;
}

/// What the detail's search box holds, for the sections and tiles below it.
///
/// A tile is found by its name ("phone") or by what it says ("Caracas"); a
/// section by its title, which then shows whole. Case and accents are
/// ignored: "direccion" finds "Dirección".
class EmployeeSearch extends InheritedWidget {
  EmployeeSearch({super.key, required String query, required super.child})
    : query = _plain(query);

  /// Already plain (lowercase, no accents, trimmed).
  final String query;

  bool get isEmpty => query.isEmpty;
  bool get isNotEmpty => query.isNotEmpty;

  bool matches(String text) => query.isEmpty || _plain(text).contains(query);

  /// Whether a tile of [EmployeeFacts] answers the query; anything that is
  /// not a tile never does.
  bool tile(Widget fact) =>
    query.isEmpty || fact is EmployeeTile && (matches((fact as EmployeeTile).label) || matches((fact as EmployeeTile).value));

  /// No search above it: everything shows.
  static EmployeeSearch of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<EmployeeSearch>() ??
      EmployeeSearch(query: "", child: const SizedBox.shrink());

  static String _plain(String text) {
    const from = "áàäâãéèëêíìïîóòöôõúùüûñç";
    const to = "aaaaaeeeeiiiiooooouuuunc";

    final lower = text.trim().toLowerCase();
    final out = StringBuffer();

    for (final char in lower.split("")) {
      final index = from.indexOf(char);
      out.write(index < 0 ? char : to[index]);
    }

    return out.toString();
  }

  @override
  bool updateShouldNotify(EmployeeSearch old) => old.query != query;
}

/// The inside of every tile: the datum's icon, what the datum is called, its
/// [child] (the value, or the field that edits it) and an optional [trailing]
/// hint of what a tap does.
class EmployeeFactFrame extends StatelessWidget {
  const EmployeeFactFrame({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.accent
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  /// Tints the icon and the label: the tile being edited.
  final Color? accent;

  /// Box every tile is padded with.
  static EdgeInsets get padding => EdgeInsets.all(AppSize.spaceXS);

  /// Corner of a group's sheet ([EmployeeFacts]).
  static double get sheetRadius => AppSize.cornerInset(AppSize.gap);

  /// Corner of a cell, nested in its sheet.
  static double get radius => AppSize.cornerInset(AppSize.gap * 0.5, sheetRadius);

  /// The datum's icon. The text size itself read lost in its box.
  static double get iconSize => AppSize.text * 1.35;

  /// The small hints at a tile's end (edit, copy, unfold).
  static double get hintSize => AppSize.text * 1.15;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      // No box behind it: the cell is already one, and a box per datum is
      // what made the panel a grid of cards. The slot keeps labels aligned.
      SizedBox(
        width: AppSize.text * 2.5,
        child: Icon(icon, size: iconSize, color: accent ?? scheme.text.secondary)
      ),
      SizedBox(width: AppSize.gap * 0.5),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextSmall(label, ellipsis: true, color: accent ?? scheme.text.secondary),
          SizedBox(height: AppSize.gap * 0.25),
          child
        ]
      )),
      if (trailing != null) ...[
        SizedBox(width: AppSize.gap),
        trailing!
      ]
    ]);
  }
}

/// Tells its [builder] whether the pointer is over it, for the hints a cell
/// shows only then ([EmployeeHint]). With no mouse at all (a touch screen)
/// it always says yes: there is no hover to wait for.
class EmployeeHover extends StatefulWidget {
  const EmployeeHover({super.key, required this.builder});

  final Widget Function(BuildContext context, bool hover) builder;

  @override
  State<EmployeeHover> createState() => _EmployeeHoverState();
}

class _EmployeeHoverState extends State<EmployeeHover> {
  bool _over = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _over = true),
    onExit: (_) => setState(() => _over = false),
    child: widget.builder(context, _over || !RendererBinding.instance.mouseTracker.mouseIsConnected)
  );
}

/// A hint that keeps its room while hidden, so the value beside it does not
/// jump, and takes no click while it cannot be seen.
class EmployeeHint extends StatelessWidget {
  const EmployeeHint({super.key, required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !shown,
    child: AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: child
    )
  );
}

/// A value as every tile says it: an empty one in words and in grey, like
/// every empty value of the panel.
class EmployeeFactValue extends StatelessWidget {
  const EmployeeFactValue({super.key, required this.value, this.empty, this.lines = 1});

  final String value;
  final String? empty;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final blank = value.trim().isEmpty;

    return TextMedium(
      blank ? (empty ?? "") : value,
      lines: lines,
      ellipsis: true,
      color: blank ? ThemeColor.of(context).text.secondary : null
    );
  }
}

/// One datum that is only read: its icon, what it is called, and its value.
///
/// With [copy], a tile holding a value copies it on a tap: it is what is taken
/// out of the app (a phone, a document number).
class EmployeeFact extends StatelessWidget implements EmployeeTile {
  const EmployeeFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.empty,
    this.copy = false,
    this.wide = false,
    this.lines = 1
  });

  final IconData icon;
  @override
  final String label;
  @override
  final String value;
  final String? empty;
  final bool copy;
  @override
  final bool wide;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final copyable = copy && value.trim().isNotEmpty;

    if (!copyable) {
      return Surface(
        color: scheme.surface,
        radius: EmployeeFactFrame.radius,
        padding: EmployeeFactFrame.padding,
        child: EmployeeFactFrame(
          icon: icon,
          label: label,
          child: EmployeeFactValue(value: value, empty: empty, lines: lines)
        )
      );
    }

    return EmployeeHover(builder: (context, hover) => FeedbackButton(
      action: () => employeeCopy(context, value, label),
      message: S.of(context).employee_copy,
      color: scheme.surface,
      feedbackColor: scheme.line,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: icon,
        label: label,
        trailing: EmployeeHint(
          shown: hover,
          child: Icon(CI.copy, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary)
        ),
        child: EmployeeFactValue(value: value, empty: empty, lines: lines)
      )
    ));
  }
}

/// A dated entry (an absence, the last day): a calendar leaf with the month
/// and the day, what it is, and how long.
class EmployeeEvent extends StatelessWidget {
  const EmployeeEvent({
    super.key,
    required this.date,
    required this.title,
    this.subtitle = "",
    this.color
  });

  final DateTime? date;
  final String title;
  final String subtitle;

  /// Tint of the leaf, for an entry that matters today.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final leaf = employeeCalendarLeaf(context, date);
    final tint = color ?? scheme.text.primary;

    return Surface(
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.all(AppSize.gap),
      child: Row(children: [
        Container(
          width: AppSize.text * 3,
          padding: EdgeInsets.symmetric(vertical: AppSize.gap * 0.5),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap, AppSize.gap * 1.5))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextSmall(leaf.month, multiplier: 0.8, color: color ?? scheme.text.secondary),
              TextMedium(leaf.day, bold: true, multiplier: 1.2, color: color)
            ]
          )
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextMedium(title, bold: true, ellipsis: true),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: AppSize.gap * 0.25),
              TextSmall(subtitle, lines: 2, ellipsis: true, color: scheme.text.secondary)
            ]
          ]
        ))
      ])
    );
  }
}

/// Free text over a tile: notes, the "about", a reason a block is empty.
class EmployeeNote extends StatelessWidget {
  const EmployeeNote({super.key, required this.text, this.title, this.lines = 12});

  final String? title;
  final String text;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            TextMedium(title!, bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5)
          ],
          TextSmall(text, lines: lines, ellipsis: true, selectable: true, color: scheme.text.secondary)
        ]
      )
    );
  }
}

/// A square icon button of the header: copies a way to reach the person.
class EmployeeQuickAction extends StatelessWidget {
  const EmployeeQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.value
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 2.2;

    return FeedbackButton(
      action: () => employeeCopy(context, value, label),
      message: "$label · $value",
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap, AppSize.gap * 1.5),
      color: scheme.surface.withValues(alpha: 0.6),
      feedbackColor: scheme.line,
      child: Center(child: Icon(icon, size: EmployeeFactFrame.iconSize, color: scheme.text.primary))
    );
  }
}
