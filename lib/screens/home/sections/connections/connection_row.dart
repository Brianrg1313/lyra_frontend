import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_lite_model.dart';

import './connection_options_button.dart';
import './connection_state_tag.dart';

/// Row of the connections list: the service's icon, the name the company gave
/// it with its current state and, below, which service the account belongs to
/// and how many bots are answering through it.
///
/// Tapping it opens its configuration (`/home/connections/:id`), which is the
/// only thing done with a connected account: reviewing or fixing its
/// credentials. On the right it carries the options button, from which it is
/// paused and disconnected without having to open it ([ConnectionOptionsButton]).
///
/// From the catalog it takes **only the already-resolved name and icon** and
/// not the whole provider: the catalog loads once and doesn't change, so this
/// stops listening to it as soon as it arrives.
class ConnectionListRow extends StatelessWidget {
  const ConnectionListRow({super.key, required this.connection});

  final ConnectionLiteModel connection;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, icon) = context
      .select<ConnectionCatalogService, (String, IconData)>((catalog) {
        final provider = catalog.byCode(connection.provider);

        // Without the catalog (still loading, or it failed) the raw code is shown:
        // "whatsapp" says less than "WhatsApp Business" but much more than a
        // hole, and the row doesn't depend on that reading to exist.
        return (provider?.name ?? connection.provider, provider?.icon ?? CI.link);
      });

    return FeedbackButton(
      action: () => Navis.push(context, "/home/connections/${connection.id}"),
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: scheme.surfaceOver,
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Center(child: Icon(
            icon,
            size: AppSize.text * 1.2,
            // A paused account looks dimmed in its icon too: it's the first thing
            // you look at in the row.
            color: connection.enabled ? scheme.icon : scheme.text.secondary
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextMedium(
                connection.name,
                ellipsis: true,
                bold: true
              )),
              SizedBox(width: AppSize.spaceS),
              ConnectionStateTag(connection: connection)
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(
              _subtitle(context, label),
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        )),
        SizedBox(width: AppSize.spaceS),
        ConnectionOptionsButton(connection: connection)
      ])
    );
  }

  /// Which service it is, how much is running on it and, if it has one, the
  /// description the company gave it, all in a single line.
  ///
  /// The service goes first because it's what identifies the account —two rows
  /// can be named similarly— and the bots immediately after: it's what makes the
  /// row useful, and what deletion takes away with it.
  String _subtitle(BuildContext context, String label) => [
    label,
    S.of(context).connection_bot_count(connection.bots),
    if (connection.description.isNotEmpty) connection.description
  ].join(" · ");
}
