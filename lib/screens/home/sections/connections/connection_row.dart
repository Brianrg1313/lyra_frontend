import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_lite_model.dart';
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:core/form.dart';

import 'connection_state_tag.dart';

/// Row of the connections list: the service's icon, the name the company gave
/// it with its current state and, below, which service the account belongs to
/// and how many bots are answering through it.
///
/// Tapping it opens its configuration (`/home/connections/:id`), which is the
/// only thing done with a connected account: reviewing or fixing its
/// credentials. On the right it carries the options button, from which it is
/// paused and disconnected without having to open it ([_OptionsButton]).
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
        _OptionsButton(connection: connection)
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

/// The options button of a connection, with the dropdown it opens.
///
/// It's a separate widget and not a method of the row because the dropdown
/// hangs off **it**: it anchors to the context of whoever opens it, and that has
/// to be the button and not the whole row, or it would open from the left edge.
///
/// The two things it offers are resolved here and not in the row: the row is
/// what gets tapped to enter the configuration, and those two don't belong in
/// it.
class _OptionsButton extends StatelessWidget {
  const _OptionsButton({required this.connection});

  final ConnectionLiteModel connection;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => _open(context),
    width: AppSize.action,
    height: AppSize.action,
    color: ThemeColor.of(context).surfaceOver,
    message: S.of(context).connection_options,
    child: Center(child: Icon(
      CI.dots_horizontal,
      size: AppSize.text * 1.2,
      color: ThemeColor.of(context).icon
    ))
  );

  /// Opens the dropdown anchored to the button. Without a search box and
  /// without a form's width ([dense]): they're two options, not a list.
  Future<void> _open(BuildContext context) async {
    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        SelectOption(
          value: "toggle",
          placeholder: connection.enabled
            ? S.of(context).connection_pause
            : S.of(context).connection_resume,
          icon: connection.enabled
            ? Icons.pause_circle_outline
            : Icons.play_circle_outline
        ),
        SelectOption(
          value: "delete",
          placeholder: S.of(context).delete_connection,
          icon: CI.trash
        )
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "toggle":
        await _toggle(context);
      case "delete":
        await _delete(context);
    }
  }

  /// Pauses or resumes the account. Nothing is asked: it's reversible with the
  /// same click and not a single piece of data is lost —neither the
  /// configuration nor the bots running on it—, they just stop answering.
  Future<void> _toggle(BuildContext context) async {
    // The notice is built beforehand: the service fixes the row on the spot
    // and this context may repaint while the change is in transit.
    final message = connection.enabled
      ? S.of(context).connection_paused
      : S.of(context).connection_resumed;

    final changed = await context.read<ConnectionsService>().toggle(
      context,
      connection
    );

    // If it failed, the service already put the row back as it was and showed
    // the error.
    if (!changed) return;

    FloatFlag.of().message(message);
  }

  /// Disconnects the account, with prior confirmation.
  ///
  /// It's asked here and not in the service because what deletion takes away
  /// doesn't fit in the list, and it's two things: **the credentials**, so
  /// reconnecting that same account means asking the service for its tokens all
  /// over again, and **the bots that were answering through it**, because a bot
  /// without an account has no way to answer. The second one is only named when
  /// there are some, and it's the reason pause exists: that leaves them quiet
  /// without deleting them.
  ///
  /// The notice names the account so confirmation isn't given on the wrong row.
  Future<void> _delete(BuildContext context) async {
    final message = StringBuffer(
      S.of(context).connection_delete_message(connection.name)
    );

    if (connection.bots > 0) {
      message
        ..write(" ")
        ..write(S.of(context).connection_delete_bots(connection.bots));
    }

    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).connection_delete_title,
      message: message.toString(),
      confirmText: S.of(context).delete_connection,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // The notice is built **before** the deletion: when it goes well, this row
    // will no longer exist —the list repaints without it— and its context won't
    // even be good for reading the text.
    final done = S.of(context).connection_deleted;

    final deleted = await context.read<ConnectionsService>().remove(
      context,
      connection
    );

    // If it failed, the error was already shown in the service and the account
    // stays in the list, which is what should happen: nothing was disconnected.
    if (!deleted) return;

    // No context: the row's came down with it. The floating flag hangs off the
    // browser, which is still there.
    FloatFlag.of().message(done);
  }
}
