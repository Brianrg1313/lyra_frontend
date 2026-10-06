import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_language.dart';
import 'package:app/services/preferences/preferences_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Language and appearance, and how inventory tables open. Language and appearance are this
/// device's (`PreferencesService`), not the account's: the same person may want a dark till and a
/// light office. The inventory view is the account's on this device, the same choice as the
/// inventory section's cells switch. Work in every mode.
class OwnPreferences extends StatelessWidget {
  const OwnPreferences({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return SettingsList(rows: [
      SettingsRow(
        icon: CI.globe_shopping,
        label: s.account_language,
        child: SettingsSelect(
          label: BusinessLanguage.label(language),
          open: (anchor) => _pickLanguage(anchor, language)
        )
      ),
      SettingsRow(
        icon: CI.brightness,
        label: s.account_theme,
        child: ValueListenableBuilder<ThemeMode?>(
          valueListenable: AppController().theme,
          builder: (context, _, _) => SettingsSelect(
            label: _themeLabel(context, PreferencesService().theme),
            open: _pickTheme
          )
        )
      ),
      SettingsRow(
        icon: CI.documents_excel,
        label: s.account_inventory_view,
        child: ValueListenableBuilder<InventoryView>(
          valueListenable: PreferencesService().inventoryView,
          builder: (context, view, _) => SettingsSelect(
            label: _viewLabel(context, view),
            open: (anchor) => _pickView(anchor, view)
          )
        )
      )
    ]);
  }

  Future<void> _pickLanguage(BuildContext anchor, String current) async {
    final picked = await showSelectMenu(
      context: anchor,
      selected: current,
      dense: true,
      options: [
        for (final locale in S.delegate.supportedLocales)
          SelectOption(value: locale.languageCode, placeholder: BusinessLanguage.label(locale.languageCode))
      ]
    );

    if (picked == null || picked.value == current) return;

    PreferencesService().locale = Locale(picked.value);
  }

  Future<void> _pickTheme(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      selected: PreferencesService().theme.name,
      dense: true,
      options: [
        for (final mode in ThemeMode.values)
          SelectOption(value: mode.name, placeholder: _themeLabel(anchor, mode))
      ]
    );

    if (picked == null) return;

    PreferencesService().theme = ThemeMode.values.byName(picked.value);
  }

  Future<void> _pickView(BuildContext anchor, InventoryView current) async {
    final picked = await showSelectMenu(
      context: anchor,
      selected: current.name,
      dense: true,
      options: [
        for (final view in InventoryView.values)
          SelectOption(value: view.name, placeholder: _viewLabel(anchor, view))
      ]
    );

    if (picked == null) return;

    PreferencesService().useInventoryView(InventoryView.values.byName(picked.value));
  }

  static String _viewLabel(BuildContext context, InventoryView view) => switch (view) {
    InventoryView.summary => S.of(context).account_inventory_view_summary,
    InventoryView.sheet => S.of(context).account_inventory_view_sheet
  };

  static String _themeLabel(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => S.of(context).account_theme_system,
    ThemeMode.light => S.of(context).account_theme_light,
    ThemeMode.dark => S.of(context).account_theme_dark
  };
}
