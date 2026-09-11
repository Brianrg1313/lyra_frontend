import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_lite_model.dart';
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'connection_row.dart';

/// Connections: this is the content of the `connections` section of the home.
///
/// A connection is **an account from an outside service** —a WhatsApp number, a
/// Facebook page, an Instagram profile— authenticated against the platform. The
/// account is registered here and its credentials are loaded, and that's all
/// that is decided: the account doesn't attend to anything on its own.
///
/// What the account answers —direct messages, comments on a post, comments on an
/// ad— is a bot per job running on this same connection, and it's built
/// elsewhere. That's why the two things are separate: one Instagram login is
/// enough for four jobs without needing three more tokens, and each of those can
/// want a different person, other data, and other tools.
///
/// The screen is a wide list, shaped like the product tables: the bar with the
/// title and the action on top, and the rows below. It's not a narrow panel like
/// the channels one because there's nothing beside it: of an account you read
/// which service it belongs to, what it's called, whether it's ready and how
/// much is running on it, and all of that fits in a single row.
///
/// It's split into three so each part repaints on its own: the bar on top
/// listens to nothing and is drawn once, the body listens to the service (which
/// is what changes on load) and the list listens only to what was typed into the
/// search box. That's why the search text arrives as a [ValueListenable] and not
/// as screen state: with `setState` every keystroke would rebuild the bar and
/// its button too.
class ConnectionsSection extends StatefulWidget {
  const ConnectionsSection({super.key});

  @override
  State<ConnectionsSection> createState() => _ConnectionsSectionState();
}

class _ConnectionsSectionState extends State<ConnectionsSection> {
  /// What was typed into the header's search box, already normalized. The
  /// section doesn't have its own: the bar on top is the same for all sections
  /// and searches the one being viewed. Only the list listens to it.
  late final ValueListenable<String> _query;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery;

    // The loads notify their listeners; they're deferred to the first frame so
    // a rebuild isn't triggered while the tree is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _load();

      // The catalog is requested from here even though the form is what draws it:
      // the list needs each service's name and icon to paint its rows, and
      // besides, it's already there by the time "connect account" is tapped.
      context.read<ConnectionCatalogService>().load();
    });
  }

  /// Fetches the connections of the active company. The service caches per
  /// company, so this call doesn't hit the backend again if they're already
  /// loaded.
  void _load({bool force = false}) => context.read<ConnectionsService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding / 2),
    child: Column(children: [
      Row(children: [
        Expanded(child: TextMedium(
          S.of(context).connections,
          bold: true,
          ellipsis: true
        )),
        SizedBox(width: AppSize.gap),
        Button(
          width: null,
          title: S.of(context).create_connection,
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          action: _create
        )
      ]),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
      ),
      Expanded(child: _Body(
        query: _query,
        onCreate: _create,
        onRetry: () => _load(force: true)
      ))
    ])
  );

  /// Opens the creation page. It's a sub-page and not a modal: the form is a
  /// handful of credentials that get copied and pasted from the service's
  /// console, in another window, and a modal closes with a single click
  /// outside.
  void _create() => Navis.push(context, "/home/connections/new");
}

/// The body of the list: the only thing that listens to [ConnectionsService],
/// so loading, failing, or bringing the accounts doesn't rebuild the bar on
/// top.
class _Body extends StatelessWidget {
  const _Body({
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
      ConnectionsStatus.ready => _List(
        connections: service.connections,
        query: query
      )
    };
  }
}

/// The filtered list. It listens only to the search box: typing into it
/// touches neither the bar nor the service, it only re-filters these rows.
///
/// The filter looks at the name and the description: an account is searched by
/// what the company called it ("Main account"), which is what's remembered, and
/// not by the service's code.
class _List extends StatelessWidget {
  const _List({required this.connections, required this.query});

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
