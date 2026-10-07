import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';
import 'package:app/screens/home/sections/sales/stage/sale_stage_color.dart';
import 'package:app/screens/home/sections/sales/stage/sale_stage_dot.dart';

/// Where the sale stands, out of the states of the **open section**.
///
/// A tab must not be able to filter itself down to a state that belongs to the
/// other one, which is why the options are `SalesCatalogService.of(section)`
/// and not every stage there is.
///
/// Each option keeps its dot, so the list is read by colour the way the rows
/// are; the closed control carries the chosen one's, which is what says at a
/// glance that the board is narrowed and to what phase.
class SalesStageFilter extends StatelessWidget {
  const SalesStageFilter({super.key, required this.service, required this.catalog});

  final SalesService service;
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final stages = catalog.of(service.section);
    final current = catalog.stage(service.stage);

    return SectionMenuChip(
      emptyText: S.of(context).sales_select_empty,
      icon: current == null ? CI.task_list : null,
      // The stage's own colour, on the control as well as in the list: a
      // dropdown that painted the choice only while open would say a different
      // thing about the same value depending on whether somebody is looking.
      leading: current == null
        ? null
        : SaleStageDot(
            color: saleStageColor(context, current.stage, current.level)
          ),
      title: current?.name ?? S.of(context).sales_all_stages,
      isActive: service.stage.isNotEmpty,
      selected: service.stage,
      // Offered and empty rather than hidden while the catalog is missing: a
      // control that comes and goes as a read lands is harder to read than one
      // that says it has nothing.
      options: [
        SelectOption(
          value: "",
          placeholder: S.of(context).sales_all_stages
        ),
        for (final stage in stages) SelectOption(
          value: stage.stage,
          placeholder: stage.name,
          leading: SaleStageDot(
            color: saleStageColor(context, stage.stage, stage.level)
          )
        )
      ],
      // A section has around a dozen states and they are the classification
      // this screen is about: the list opens showing as many as fit rather
      // than five and a scroll.
      maxOptions: 10,
      onSelected: service.filterStage
    );
  }
}
