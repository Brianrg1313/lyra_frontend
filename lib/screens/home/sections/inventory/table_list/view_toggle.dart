import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/preferences/preferences_service.dart';

/// The cells switch: on, the open table shows every cell (the sheet); off, its stock
/// summary. The choice is the account's (`PreferencesService`): the next table, and the
/// next time, open the same way.
class InventoryViewToggle extends StatelessWidget {
  const InventoryViewToggle({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<InventoryView>(
    valueListenable: PreferencesService().inventoryView,
    builder: (context, view, _) {
      final scheme = ThemeColor.of(context);
      final on = view == InventoryView.sheet;

      return FeedbackButton(
        action: () => PreferencesService().useInventoryView(
          on ? InventoryView.summary : InventoryView.sheet
        ),
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
  );
}
