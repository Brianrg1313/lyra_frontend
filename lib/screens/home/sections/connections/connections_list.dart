import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connections/connection_lite_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './connection_row.dart';

/// The filtered list. It listens only to the search box: typing into it
/// touches neither the bar nor the service, it only re-filters these rows.
///
/// The filter looks at the name and the description: an account is searched by
/// what the company called it ("Main account"), which is what's remembered, and
/// not by the service's code.
class ConnectionsList extends StatelessWidget {
  const ConnectionsList({super.key, required this.connections, required this.query});

  final List<ConnectionLiteModel> connections;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: query,
    builder: (context, value, _) {
      final filtered = value.isEmpty
        ? connections
        : connections.where((connection) =>
            connection.name.toLowerCase().contains(value) ||
            connection.description.toLowerCase().contains(value)
          ).toList();

      if (filtered.isEmpty) {
        return SectionMessage(
          icon: CI.search,
          title: S.of(context).connections_search_empty
        );
      }

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
        itemBuilder: (context, index) => ConnectionListRow(
          connection: filtered[index]
        )
      );
    }
  );
}
