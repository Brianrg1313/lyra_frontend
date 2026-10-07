import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/inventory/table_templates_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/widgets/inventory_blank_card.dart';
import 'package:app/screens/home/sections/inventory/table_list/widgets/inventory_template_card.dart';

import './import_button.dart';

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
          builder: (context, creating, _) => InventoryTemplateCard(
            template: template,
            loading: creating == template.id,
            action: creating == null ? () => _create(template) : null
          )
        ),
      InventoryBlankCard(action: widget.onBlank)
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
