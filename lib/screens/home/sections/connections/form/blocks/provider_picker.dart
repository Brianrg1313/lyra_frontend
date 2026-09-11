import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_provider_model.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/connection_form_controller.dart';

/// Which service the account belongs to: the form's first block, and the one
/// that decides everything that comes after —the credential fields come from
/// the chosen provider.
///
/// The list comes from the backend's catalog, not from this app. The services
/// that can already be configured go on top and the rest is shown dimmed, with
/// its caption: integrations are enabled gradually (Meta's first) and hiding
/// the missing ones would make it seem like they'll never be there.
///
/// **It can't be changed in an edit.** The stored secrets were gathered for
/// one service, and pointing them at another would leave values that mean
/// nothing there; the backend rejects it and here it's simply not offered. In
/// its place, what it is is shown, dimmed.
class ProviderPicker extends StatelessWidget {
  const ProviderPicker({super.key, required this.controller});

  final ConnectionFormController controller;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ConnectionCatalogService>();

    return FormBlock(
      title: S.of(context).connection_provider_title,
      subtitle: controller.isEditing
        ? S.of(context).connection_provider_locked
        : S.of(context).connection_provider_subtitle,
      child: switch (catalog.status) {
        ConnectionCatalogStatus.idle || ConnectionCatalogStatus.loading =>
          const Center(child: Loading()),
        ConnectionCatalogStatus.error => _Error(
          onRetry: () => catalog.load(force: true)
        ),
        ConnectionCatalogStatus.ready => ValueListenableBuilder<String>(
          valueListenable: controller.provider,
          builder: (context, selected, _) => OptionGrid(children: [
            for (final provider in _visible(catalog, selected)) OptionCard(
              icon: provider.icon,
              title: provider.name,
              subtitle: _scopes(context, provider),
              selected: provider.provider == selected,
              // When editing, the service is decided: the card is shown to know
              // which one it is, but it doesn't respond.
              enabled: provider.isSupported && !controller.isEditing,
              badge: provider.isSupported
                ? null
                : S.of(context).connection_provider_soon,
              action: () => controller.provider.value = provider.provider
            )
          ])
        )
      }
    );
  }

  /// Which services to show. When editing, only the account's: the rest isn't
  /// an option and would take up half a screen of cards that can't be
  /// touched.
  List<ConnectionProviderModel> _visible(
    ConnectionCatalogService catalog,
    String selected
  ) {
    if (!controller.isEditing) return catalog.sorted;

    final current = catalog.byCode(selected);

    return current == null ? const [] : [current];
  }

  /// What the account will be able to be put on, in one line: direct
  /// messages, comments, ad comments.
  ///
  /// It's what tells two similar entries apart: the Facebook page and
  /// Messenger are the same page, but one answers comments and the other
  /// messages —and each one asks for its own credentials—. Besides, it's how
  /// many bots the account will be able to feed, which is what comes next.
  ///
  /// The known codes are translated here and the ones that aren't are shown
  /// with the name the backend sent: a new job in the catalog has to be
  /// readable from an old app, even if it's in the server's language.
  ///
  /// Returns `null` if the service didn't declare any, so the card doesn't
  /// reserve the place of a subtitle that doesn't exist.
  String? _scopes(BuildContext context, ConnectionProviderModel provider) {
    final labels = [
      for (final scope in provider.scopes)
        switch (scope.scope) {
          "messages" => S.of(context).connection_scope_messages,
          "comments" => S.of(context).connection_scope_comments,
          "ad_comments" => S.of(context).connection_scope_ad_comments,
          "mentions" => S.of(context).connection_scope_mentions,
          "posts" => S.of(context).connection_scope_posts,
          "calls" => S.of(context).connection_scope_calls,
          _ => scope.name
        }
    ]..removeWhere((label) => label.isEmpty);

    return labels.isEmpty ? null : labels.join(" · ");
  }
}

/// The catalog didn't load. Without it there's no form to draw —the
/// credential fields come from there— so retrying is offered in place.
class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final void Function() onRetry;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(CI.info, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextSmall(
      S.of(context).connection_catalog_error,
      lines: 2,
      ellipsis: true,
      color: ThemeColor.of(context).text.secondary
    )),
    SizedBox(width: AppSize.spaceS),
    FeedbackButton(
      action: onRetry,
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.spaceS,
        vertical: AppSize.gap
      ),
      color: ThemeColor.of(context).surfaceOver,
      child: TextSmall(S.of(context).connections_retry)
    )
  ]);
}
