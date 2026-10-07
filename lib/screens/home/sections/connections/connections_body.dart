import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './connections_list.dart';

/// The body of the list: the only thing that listens to [ConnectionsService],
/// so loading, failing, or bringing the accounts doesn't rebuild the bar on
/// top.
class ConnectionsBody extends StatelessWidget {
  const ConnectionsBody({
    super.key,
    required this.query,
    required this.onCreate,
    required this.onRetry
  });

  final ValueListenable<String> query;
  final void Function() onCreate;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConnectionsService>();

    return switch (service.status) {
      ConnectionsStatus.loading || ConnectionsStatus.idle =>
        const Center(child: Loading()),
      ConnectionsStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).connections_error_title,
        subtitle: S.of(context).connections_error_subtitle,
        action: onRetry,
        actionLabel: S.of(context).connections_retry
      ),
      ConnectionsStatus.empty => SectionMessage(
        icon: CI.cloud_disconected,
        title: S.of(context).connections_empty_title,
        subtitle: S.of(context).connections_empty_subtitle,
        action: onCreate,
        actionLabel: S.of(context).create_connection,
        actionIcon: CI.plus
      ),
      ConnectionsStatus.ready => ConnectionsList(
        connections: service.connections,
        query: query
      )
    };
  }
}
