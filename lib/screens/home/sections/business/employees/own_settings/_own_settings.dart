import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:core/form.dart';

import './own_header.dart';
import './own_section.dart';
import './own_soon.dart';

/// The person's own settings, from the settings action of their own card: what is theirs and no
/// administrator manages — how they sign in, where they are signed in, this device's language
/// and look, their work history, their notices and their privacy.
///
/// It is an index: whose account it is, a search, and one row per [OwnSection], each opening its
/// own panel over this one. The search looks through every row of every subsection, so a
/// setting is found by its name without knowing where it lives.
///
/// It owns its services: they are the account's, read when the panel opens and dropped with it.
class OwnSettings extends StatefulWidget {
  const OwnSettings({super.key});

  @override
  State<OwnSettings> createState() => _OwnSettingsState();
}

class _OwnSettingsState extends State<OwnSettings> {
  final _security = AccountSecurityService();
  final _history = AccountHistoryService();

  final _form = FormController();
  late final _search = InputController.search(form: _form);

  /// What was typed. A notifier, so typing rebuilds the list and not the field.
  final _query = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();

    final capabilities = CapabilityService();
    if (capabilities.shows("account.security")) _security.load();
    if (capabilities.shows("account.history")) _history.load();

    // Listened to, not `onSearch`: that one waits for typing to stop, meant for a query that
    // travels, and the settings are all here.
    _search.textController.addListener(_write);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_write);
    _form.dispose();
    _query.dispose();
    _security.dispose();
    _history.dispose();
    super.dispose();
  }

  void _write() => _query.value = _search.text.trim();

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _security),
      ChangeNotifierProvider.value(value: _history)
    ],
    child: ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OwnHeader(),
        SearchInput(
          controller: _search,
          placeholder: S.of(context).account_search,
          radius: AppSize.cornerInset(AppSize.gap),
          onSearch: (_) => _write()
        ),
        SizedBox(height: AppSize.spaceS),
        ValueListenableBuilder<String>(
          valueListenable: _query,
          builder: (context, query, _) => query.isEmpty ? const _Index() : _Results(query: query)
        )
      ]
    )
  );
}

/// Every subsection: what works first, the ones with nothing working yet apart and last.
class _Index extends StatelessWidget {
  const _Index();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Group(rows: [
        for (final section in OwnSection.values.where((section) => !section.soon)) _SectionRow(section: section)
      ]),
      SizedBox(height: AppSize.spaceS),
      _Group(rows: [
        for (final section in OwnSection.values.where((section) => section.soon)) _SectionRow(section: section)
      ])
    ]
  );
}

/// What the search found: the subsections it names, then the rows inside them, each with the
/// subsection it opens.
class _Results extends StatelessWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final words = OwnSetting.fold(query).split(" ").where((word) => word.isNotEmpty).toList();

    final sections = [
      for (final section in OwnSection.values)
        if (words.every(OwnSetting.fold("${section.title(s)} ${section.subtitle(s)}").contains)) section
    ];
    final settings = [
      for (final section in OwnSection.values)
        for (final setting in section.settings(s))
          if (setting.matches(words, section.title(s))) setting
    ];

    if (sections.isEmpty && settings.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
        child: TextSmall(
          s.account_search_empty(query),
          lines: 3,
          textAlign: TextAlign.center,
          color: ThemeColor.of(context).text.secondary
        )
      );
    }

    return _Group(rows: [
      for (final section in sections) _SectionRow(section: section),
      for (final setting in settings) _SettingRow(setting: setting)
    ]);
  }
}

/// Rows over one surface, a line between each.
class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Surface.over(
    padding: EdgeInsets.all(AppSize.gap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) Separator.horizontal(margin: EdgeInsets.symmetric(horizontal: AppSize.spaceXS)),
          rows[i]
        ]
      ]
    )
  );
}

/// A subsection of the index: its icon, its name and what it is for, and where it leads.
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.section});

  final OwnSection section;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final tint = section.soon ? scheme.text.secondary : scheme.primary;
    final box = AppSize.action * 0.85;

    return _Tap(
      label: section.title(s),
      action: () => section.open(context),
      child: Row(children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
          ),
          child: Icon(section.icon, size: AppSize.text * 1.15, color: tint)
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(section.title(s), bold: true, ellipsis: true, color: section.soon ? scheme.text.secondary : null),
            TextSmall(section.subtitle(s), lines: 2, ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        SizedBox(width: AppSize.spaceXS),
        section.soon ? const OwnSoonTag() : const _Arrow()
      ])
    );
  }
}

/// A row inside a subsection, as a search result: its name and the subsection that holds it.
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.setting});

  final OwnSetting setting;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final section = setting.section;

    return _Tap(
      label: setting.label,
      action: () => section.open(context),
      child: Row(children: [
        SizedBox(
          width: AppSize.action * 0.85,
          child: Icon(setting.icon, size: AppSize.text * 1.1, color: scheme.text.secondary)
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(setting.label, ellipsis: true),
            TextSmall(section.title(s), ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        SizedBox(width: AppSize.spaceXS),
        section.soon ? const OwnSoonTag() : const _Arrow()
      ])
    );
  }
}

class _Tap extends StatelessWidget {
  const _Tap({required this.label, required this.action, required this.child});

  final String label;
  final void Function() action;
  final Widget child;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    message: label,
    radius: AppSize.cornerInset(AppSize.gap),
    color: Colors.transparent,
    feedbackColor: ThemeColor.of(context).surfaceFeedback,
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: child
  );
}

/// That the row opens a panel of its own.
class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) =>
    Icon(CI.arrow_right, size: AppSize.text * 0.9, color: ThemeColor.of(context).text.secondary);
}
