import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';

import './employee_fact.dart';
import './employee_search.dart';

/// The shapes the detail panel is drawn with: a titled section, a grid of
/// data tiles, a dated event, a note and the header's quick actions.
///
/// The panel reads as a personnel file: each group of data is one sheet
/// ([EmployeeFacts]) and its data are cells of it, not a card each. A cell
/// only lights up under the pointer, and says what a click does (edit, copy,
/// unfold) only then: thirty pencils at rest are noise. The one cell that
/// stands out is the one being edited ([EmployeeFactFrame.accent]).

/// Tiles two by two, one per row when the panel is too narrow for two values
/// to be read. A [EmployeeTile.wide] one takes the whole row: an address cut in
/// half says nothing.
class EmployeeFacts extends StatelessWidget {
  const EmployeeFacts({super.key, required this.facts});

  /// Tiles: [EmployeeFact] or the editable ones ([EmployeeTextFact], [EmployeeSelectFact], ...).
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
