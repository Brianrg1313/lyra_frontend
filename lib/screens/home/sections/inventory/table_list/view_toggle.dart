import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/preferences/preferences_service.dart';

/// The cells switch: on, the open table shows every cell (the sheet); off, its stock
/// summary. The choice is the account's (`PreferencesService`): the next table, and the
/// next time, open the same way.
///
/// Given [sheet] and [onSwitch], it is the opener's instead (the production line's supplies,
/// whose other view is its own list and not the inventory's summary).
class InventoryViewToggle extends StatelessWidget {
  const InventoryViewToggle({super.key, this.sheet, this.onSwitch});

  final bool? sheet;
  final ValueChanged<bool>? onSwitch;

  @override
  Widget build(BuildContext context) {
    final sheet = this.sheet;
    final onSwitch = this.onSwitch;

    if (sheet != null && onSwitch != null) return _button(context, sheet, onSwitch);

    return ValueListenableBuilder<InventoryView>(
      valueListenable: PreferencesService().inventoryView,
      builder: (context, view, _) => _button(
        context,
        view == InventoryView.sheet,
        (on) => PreferencesService().useInventoryView(on ? InventoryView.sheet : InventoryView.summary)
      )
    );
  }

  Widget _button(BuildContext context, bool on, ValueChanged<bool> onSwitch) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: () => onSwitch(!on),
      width: AppSize.button,
      height: AppSize.button,
      color: on ? scheme.primary : scheme.input.fill,
      radius: AppSize.cornerInset(AppSize.gap),
      message: on
        ? S.of(context).inventory_view_summary
        : S.of(context).inventory_view_sheet,
      child: Center(child: Icon(
        CI.documents_excel,
        size: AppSize.text * 1.2,
        color: on ? scheme.button.text : scheme.icon
      ))
    );
  }
}
