import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sales_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_menu_chip.dart';

/// Where the sale came in through, out of the same closed vocabulary the
/// checkout's own picker is drawn from.
class SalesChannelFilter extends StatelessWidget {
  const SalesChannelFilter({super.key, required this.service, required this.catalog});

  final SalesService service;
  final SalesCatalogService catalog;

  @override
  Widget build(BuildContext context) {
    final current = service.channel;

    return SectionMenuChip(
      emptyText: S.of(context).sales_select_empty,
      icon: CI.cloud_connected,
      title: current.isEmpty
        ? S.of(context).sales_channel
        : catalog.channelName(current),
      isActive: current.isNotEmpty,
      selected: current,
      options: [
        SelectOption(
          value: "",
          placeholder: S.of(context).sales_any_channel
        ),
        for (final channel in catalog.channels) SelectOption(
          value: channel.channel,
          placeholder: channel.name
        )
      ],
      onSelected: service.filterChannel
    );
  }
}
