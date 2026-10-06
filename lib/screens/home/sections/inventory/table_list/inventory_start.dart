import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/capabilities/capability_service.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/inventory/table_templates_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'import_button.dart';
import 'table_selector.dart';

/// What the inventory section shows a company with no table: the starting tables
/// offered to its activity (`GET .../builder/templates/`), a blank one, and the import.
///
/// It owns the templates and is only mounted while there is no table, so a company that
/// already has one never asks for them. Creating one answers its id ([onCreated]) and the
/// section opens it.
class InventoryStart extends StatefulWidget {
  const InventoryStart({
    super.key,
    required this.onCreated,
    required this.onBlank,
    this.onImport,
    this.importing,
    this.templates
  });

  final void Function(String tableId) onCreated;

  /// Opens the create modal (a name, a description).
  final void Function() onBlank;

  /// Null where importing isn't offered (`inventory.import`).
  final void Function()? onImport;
  final ValueListenable<bool>? importing;

  /// The templates' service; null creates (and owns) one. A seam for tests.
  final TableTemplatesService? templates;

  @override
  State<InventoryStart> createState() => _InventoryStartState();
}

class _InventoryStartState extends State<InventoryStart> {
  late final _templates = widget.templates ?? TableTemplatesService();

  /// The template being created, so its card waits and the others don't answer: two
  /// taps would make two tables.
  final _creating = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    // Templates are the cloud's catalogue (`inventory.templates`): elsewhere the blank
    // table and the import are the whole offer.
    if (!CapabilityService().shows("inventory.templates")) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _templates.load();
    });
  }

  @override
  void dispose() {
    if (widget.templates == null) _templates.dispose();
    _creating.dispose();
    super.dispose();
  }

  Future<void> _create(TableTemplateModel template) async {
    if (_creating.value != null) return;
    _creating.value = template.id;

    try {
      final id = await context.read<TablesService>().create(context, createTableRequest(
        title: template.name,
        description: template.description,
        color: template.color.isEmpty ? _fallbackColor : template.color,
        template: template.id
      ));

      if (mounted) widget.onCreated(id);
    } catch (_) {
      // The service already showed why.
    } finally {
      if (mounted) _creating.value = null;
    }
  }

  /// The create request asks for a colour; a template without one takes the blank form's.
  static const _fallbackColor = "0xFFF87171";

  @override
  Widget build(BuildContext context) => Surface(
    child: ListenableBuilder(
      listenable: _templates,
      builder: (context, _) => SingleChildScrollView(
        padding: EdgeInsets.all(AppSize.padding),
        child: Center(child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppSize.action * 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSize.spaceL),
              TextLarge(
                S.of(context).inventory_start_title,
                textAlign: TextAlign.center
              ),
              SizedBox(height: AppSize.gap),
              TextMedium(
                S.of(context).inventory_start_subtitle,
                color: ThemeColor.of(context).text.secondary,
                textAlign: TextAlign.center
              ),
              SizedBox(height: AppSize.spaceL),
              _grid(context)
            ]
          )
        ))
      )
    )
  );

  Widget _grid(BuildContext context) {
    final status = _templates.status;

    final cards = <Widget>[
      if (status == TableTemplatesStatus.ready)
        for (final template in _templates.templates) ValueListenableBuilder<String?>(
          valueListenable: _creating,
          builder: (context, creating, _) => _TemplateCard(
            template: template,
            loading: creating == template.id,
            action: creating == null ? () => _create(template) : null
          )
        ),
      _BlankCard(action: widget.onBlank)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == TableTemplatesStatus.loading)
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceM),
            child: const Center(child: Loading())
          ),
        if (status == TableTemplatesStatus.error) Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: TextSmall(
                S.of(context).inventory_templates_error,
                color: ThemeColor.of(context).text.secondary
              )),
              SizedBox(width: AppSize.gap),
              FeedbackButton(
                action: _templates.load,
                color: ThemeColor.of(context).surfaceOver,
                height: AppSize.button,
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
                child: Center(child: TextSmall(S.of(context).product_tables_retry))
              )
            ]
          )
        ),
        LayoutBuilder(builder: (context, constraints) {
          // As many columns as fit at a card's minimum width, all the same width.
          final columns = (constraints.maxWidth / (AppSize.action * 6.5)).floor().clamp(1, 3);
          final width = (constraints.maxWidth - AppSize.spaceS * (columns - 1)) / columns;

          return Wrap(
            spacing: AppSize.spaceS,
            runSpacing: AppSize.spaceS,
            children: [for (final card in cards) SizedBox(width: width, child: card)]
          );
        }),
        if (widget.onImport != null && widget.importing != null) ...[
          SizedBox(height: AppSize.spaceM),
          Center(child: ImportButton(action: widget.onImport!, loading: widget.importing!))
        ]
      ]
    );
  }
}

/// One starting table: its colour, name, what it's for, and the columns it comes with.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.loading, required this.action});

  final TableTemplateModel template;
  final bool loading;
  final void Function()? action;

  /// How many columns the card names before "and N more".
  static const _shown = 5;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final names = template.fields.map((field) => field.name).toList();
    final extra = names.length - _shown;

    return _Card(
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            TableDot(color: template.color),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(template.name, bold: true, ellipsis: true)),
            if (loading) SizedBox(
              width: AppSize.text,
              height: AppSize.text,
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.text.secondary)
            )
          ]),
          if (template.description.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(template.description, color: scheme.text.secondary, lines: 2, ellipsis: true)
          ],
          if (names.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceS),
            TextSmall(
              extra > 0
                ? S.of(context).inventory_template_columns_more(names.take(_shown).join(" · "), extra)
                : names.join(" · "),
              lines: 2,
              ellipsis: true
            )
          ]
        ]
      )
    );
  }
}

/// A table with no columns, named in the create modal.
class _BlankCard extends StatelessWidget {
  const _BlankCard({required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return _Card(
      action: action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(CI.plus, size: AppSize.text, color: scheme.icon),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(S.of(context).inventory_start_blank, bold: true, ellipsis: true))
          ]),
          SizedBox(height: AppSize.gap),
          TextSmall(S.of(context).inventory_start_blank_hint, color: scheme.text.secondary, lines: 2, ellipsis: true)
        ]
      )
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.action, required this.child});

  final void Function()? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    color: ThemeColor.of(context).surfaceOver,
    radius: AppSize.corner,
    padding: EdgeInsets.all(AppSize.spaceS),
    child: SizedBox(
      height: AppSize.action * 2.4,
      child: Align(alignment: Alignment.topLeft, child: child)
    )
  );
}
