import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// What the section puts in its bar whatever the view: the table selector (cut before
/// anything else when a long name doesn't fit), the controls beside it (the
/// summary/cells switch) and its actions at the right end (the table's options, import,
/// create).
class InventoryBarParts {
  const InventoryBarParts({
    required this.selector,
    required this.controls,
    this.actions = const []
  });

  final Widget selector;
  final List<Widget> controls;
  final List<Widget> actions;
}

/// The inventory section's top bar, drawn by each view of the open table (the summary
/// and the sheet) because part of it is theirs: [status] is what the view is doing (a
/// read, a count, an import) and [actions] what it offers, and both need the view's own
/// services, which live below the section. The view's actions go before the section's,
/// so create stays last whatever the view.
///
/// The whole width is the bar's: the actions against the right edge at their own width,
/// [status] in the middle of the bar (not of what is left between the sides), and the
/// selector with what remains to its left. See [_BarLayout].
class InventoryBar extends StatelessWidget {
  const InventoryBar({
    super.key,
    required this.parts,
    this.status = const [],
    this.actions = const []
  });

  final InventoryBarParts parts;
  final List<Widget> status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.gap),
    child: SizedBox(
      height: AppSize.button,
      child: CustomMultiChildLayout(
        delegate: _BarLayout(gap: AppSize.spaceS),
        children: [
          LayoutId(id: _Slot.actions, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, action) in [...actions, ...parts.actions].indexed) ...[
                if (index > 0) SizedBox(width: AppSize.gap),
                action
              ]
            ]
          )),
          if (status.isNotEmpty) LayoutId(id: _Slot.status, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, widget) in status.indexed) Flexible(child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : AppSize.gap),
                child: widget
              ))
            ]
          )),
          LayoutId(id: _Slot.leading, child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: parts.selector),
              for (final control in parts.controls) ...[
                SizedBox(width: AppSize.gap),
                control
              ]
            ]
          ))
        ]
      )
    )
  );
}

enum _Slot { leading, status, actions }

/// Lays the bar out in the order that decides who gives way: the actions first, at their
/// own width; then the status, centred on the bar and only as wide as the actions leave
/// on both sides of the middle; the selector last, with whatever is left before the
/// status (or the actions). A long table name is what gets cut.
class _BarLayout extends MultiChildLayoutDelegate {
  _BarLayout({required this.gap});

  /// Between the three parts.
  final double gap;

  @override
  void performLayout(Size size) {
    final actions = layoutChild(_Slot.actions, BoxConstraints.loose(size));
    final actionsLeft = size.width - actions.width;
    positionChild(_Slot.actions, Offset(actionsLeft, (size.height - actions.height) / 2));

    var leadingEnd = actionsLeft - (actions.width > 0 ? gap : 0);

    if (hasChild(_Slot.status)) {
      final room = (size.width / 2 - actions.width - gap) * 2;
      final status = layoutChild(
        _Slot.status,
        BoxConstraints(maxWidth: room.clamp(0, size.width), maxHeight: size.height)
      );
      final statusLeft = (size.width - status.width) / 2;
      positionChild(_Slot.status, Offset(statusLeft, (size.height - status.height) / 2));

      if (status.width > 0) leadingEnd = statusLeft - gap;
    }

    final leading = layoutChild(
      _Slot.leading,
      BoxConstraints(maxWidth: leadingEnd.clamp(0, size.width), maxHeight: size.height)
    );
    positionChild(_Slot.leading, Offset(0, (size.height - leading.height) / 2));
  }

  @override
  bool shouldRelayout(_BarLayout oldDelegate) => gap != oldDelegate.gap;
}
