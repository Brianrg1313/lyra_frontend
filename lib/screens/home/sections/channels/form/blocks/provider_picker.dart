import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_provider_model.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// What network is connected: the form's first block, and the one that
/// decides everything that comes after —the credential fields come from the
/// chosen provider.
///
/// The list comes from the backend catalog, not from this app, but it is
/// filtered down to what can actually be created today: a provider needs both
/// its credential fields built here ([ChannelProviderModel.isSupported]) *and*
/// a single job ([ChannelProviderModel.hasSingleScope]) — `SCOPE` is required
/// on creation and a provider with several (Facebook, Instagram) has no picker
/// for it yet, so offering it would connect a channel for whichever job
/// happens to come first. The rest simply is not shown: unlike the data
/// source or the tools, there is no "coming soon" card for a network, because
/// the list is the backend's and grows on its own as networks are wired up.
///
/// [_WhatsAppPersonal] is the one exception — linking a personal number (no
/// Meta business account) through the local `baileys_server` sidecar
/// instead of the backend catalog. Shown first, always selectable on create:
/// unlike a catalog network it does not depend on `GET /channels/providers`
/// having loaded, since [ChannelProviderModel.whatsappPersonal] is built
/// locally.
///
/// **In an edit it cannot be changed.** The stored secrets were gathered for
/// one network, and pointing them at another would leave values that mean
/// nothing there; the backend rejects it and here it is simply not offered. In
/// its place it shows which one it is, disabled.
class ProviderPicker extends StatelessWidget {
  const ProviderPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ChannelCatalogService>();

    return FormBlock(
      title: S.of(context).channel_type_title,
      subtitle: controller.isEditing
        ? S.of(context).channel_type_locked
        : S.of(context).channel_type_subtitle,
      child: switch (catalog.status) {
        ChannelCatalogStatus.idle || ChannelCatalogStatus.loading =>
          const Center(child: Loading()),
        ChannelCatalogStatus.error => _Error(
          onRetry: () => catalog.load(force: true)
        ),
        ChannelCatalogStatus.ready => ValueListenableBuilder<String>(
          valueListenable: controller.provider,
          builder: (context, selected, _) => OptionGrid(children: [
            if (!controller.isEditing) _WhatsAppPersonal(
              selected: selected == ChannelProviderModel.whatsappPersonalCode,
              action: () => controller.provider.value =
                ChannelProviderModel.whatsappPersonalCode
            ),
            for (final provider in _visible(catalog, selected)) OptionCard(
              icon: provider.icon,
              title: provider.name,
              subtitle: _capabilities(context, provider),
              selected: provider.provider == selected,
              // While editing, the network is decided: the card is shown so it is known
              // which one it is, but it does not respond.
              enabled: !controller.isEditing,
              action: () => controller.provider.value = provider.provider
            )
          ])
        )
      }
    );
  }

  /// What networks to show.
  ///
  /// While editing, only the channel's: the rest is not an option and would
  /// take half a screen of cards that cannot be tapped. That one is shown
  /// whatever it is, even a provider that would no longer qualify today (say
  /// it lost its single scope in a later catalog): a channel already
  /// connected under it does not stop being editable.
  ///
  /// Creating, only what is actually connectable right now — see the class
  /// note for why the rest is left out instead of shown disabled.
  List<ChannelProviderModel> _visible(
    ChannelCatalogService catalog,
    String selected
  ) {
    if (controller.isEditing) {
      final current = catalog.byCode(selected);
      return current == null ? const [] : [current];
    }

    return [
      for (final provider in catalog.providers)
        if (provider.isSupported && provider.hasSingleScope) provider
    ];
  }

  /// What that network can do, in one line: messages, comments, posts.
  ///
  /// It comes from `capabilities` and not from a fixed text per network
  /// because it is what differentiates two similar entries: the Facebook page
  /// and Messenger are the same page, but one answers comments and the other
  /// messages.
  ///
  /// Returns `null` if the network declared none, so the card does not keep
  /// the place of a subtitle that does not exist.
  String? _capabilities(BuildContext context, ChannelProviderModel provider) {
    final labels = [
      for (final capability in provider.capabilities)
        switch (capability) {
          "messages" => S.of(context).channel_capability_messages,
          "comments" => S.of(context).channel_capability_comments,
          "posts" => S.of(context).channel_capability_posts,
          "mentions" => S.of(context).channel_capability_mentions,
          "calls" => S.of(context).channel_capability_calls,
          _ => ""
        }
    ]..removeWhere((label) => label.isEmpty);

    return labels.isEmpty ? null : labels.join(" · ");
  }
}

/// Linking a personal WhatsApp number, without a Meta business account behind
/// it — the way most small businesses actually run WhatsApp today.
///
/// Picking it does not draw the usual [CredentialsBlock]: there are no
/// tokens to paste, so that block shows a QR-pairing notice for this
/// provider instead (see its own doc). The actual pairing happens after the
/// channel is created, by turning on its switch in the list
/// (`BaileysChannelSwitch`), which is what starts `baileys_server` and
/// brings up the QR to scan.
class _WhatsAppPersonal extends StatelessWidget {
  const _WhatsAppPersonal({required this.selected, required this.action});

  final bool selected;
  final void Function() action;

  @override
  Widget build(BuildContext context) => OptionCard(
    icon: CI.whatsapp,
    title: S.of(context).channel_type_whatsapp_personal,
    subtitle: S.of(context).channel_type_whatsapp_personal_hint,
    selected: selected,
    action: action
  );
}

/// The catalog did not load. Without it there is no form to draw —the
/// credential fields come from there— so retrying is offered in place.
class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final void Function() onRetry;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(CI.info, size: AppSize.text * 1.2, color: ThemeColor.of(context).icon),
    SizedBox(width: AppSize.spaceS),
    Expanded(child: TextSmall(
      S.of(context).channel_catalog_error,
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
      child: TextSmall(S.of(context).channels_retry)
    )
  ]);
}
