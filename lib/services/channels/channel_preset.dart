import 'package:flutter/material.dart';

import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channel_tools.dart';

/// Whether a [ChannelPreset] is offered, given the catalog as it stands.
enum ChannelPresetOffer {
  /// Can be created now.
  ready,

  /// In the catalog, not configurable from this app yet: shown, disabled.
  soon,

  /// Not in the catalog (or the catalog has not loaded): not shown.
  hidden
}

/// A ready-made channel: a network, the job it does there and what the agent
/// handles, so a company with no channel connects one by pasting its tokens
/// (or scanning a QR) instead of walking through every block of the form.
///
/// It only **fills** the create modal (`showCreateChannel`'s `preset`), which
/// then opens past the network step; every step is still there, so anything
/// here can be changed before saving. The network itself comes from the backend catalog like always —
/// a preset names a provider code, it does not describe one.
///
/// Every preset sells: it is what a channel is connected for the first time
/// ([ChannelAgentRole.initial]), and the support/general roles read from a
/// knowledge base that cannot be chosen as a source yet.
enum ChannelPreset {
  whatsappPersonal(
    ChannelProviderModel.whatsappPersonalCode,
    tools: {ChannelTool.voice, ChannelTool.images}
  ),
  whatsappBusiness(
    "whatsapp",
    tools: {ChannelTool.voice, ChannelTool.images}
  ),

  /// Instagram connects once per job and the panel has no scope picker yet:
  /// the preset is what says this one is for direct messages.
  instagram("instagram", scope: "messages", tools: {ChannelTool.images}),
  messenger("messenger", tools: {ChannelTool.images}),
  telegram("telegram", tools: {ChannelTool.voice, ChannelTool.images});

  const ChannelPreset(
    this.provider, {
    this.scope = "",
    this.tools = const {}
  });

  /// Provider code sent as `PROVIDER`.
  final String provider;

  /// `SCOPE` to send, or empty to take the provider's only one.
  final String scope;

  /// Every preset sells: see the class note.
  ChannelAgentRole get role => ChannelAgentRole.seller;

  final Set<ChannelTool> tools;

  /// Whether it can be offered, against [catalog]. WhatsApp Personal is built
  /// locally ([ChannelProviderModel.whatsappPersonal]) and never waits for it.
  ChannelPresetOffer offerIn(ChannelCatalogService catalog) {
    if (provider == ChannelProviderModel.whatsappPersonalCode) {
      return ChannelPresetOffer.ready;
    }

    if (catalog.status != ChannelCatalogStatus.ready) {
      return ChannelPresetOffer.hidden;
    }

    final schema = catalog.byCode(provider);
    if (schema == null) return ChannelPresetOffer.hidden;

    if (!schema.isSupported) return ChannelPresetOffer.soon;

    final fits = scope.isEmpty
      ? schema.hasSingleScope
      : schema.scopes.any((item) => item.scope == scope);

    return fits ? ChannelPresetOffer.ready : ChannelPresetOffer.hidden;
  }

  IconData get icon => switch (this) {
    whatsappPersonal || whatsappBusiness => CI.whatsapp,
    instagram => CI.instagram,
    messenger => CI.chat,
    telegram => CI.telegram
  };

  String title(BuildContext context) => switch (this) {
    whatsappPersonal => S.of(context).channel_preset_whatsapp_personal,
    whatsappBusiness => S.of(context).channel_preset_whatsapp_business,
    instagram => S.of(context).channel_preset_instagram,
    messenger => S.of(context).channel_preset_messenger,
    telegram => S.of(context).channel_preset_telegram
  };

  /// What connecting it takes, which is what tells the presets apart.
  String needs(BuildContext context) => switch (this) {
    whatsappPersonal => S.of(context).channel_preset_whatsapp_personal_needs,
    whatsappBusiness => S.of(context).channel_preset_whatsapp_business_needs,
    instagram => S.of(context).channel_preset_instagram_needs,
    messenger => S.of(context).channel_preset_messenger_needs,
    telegram => S.of(context).channel_preset_telegram_needs
  };

  /// A customer's message typical of that network, and the agent's answer.
  (String, String) sample(BuildContext context) => switch (this) {
    whatsappPersonal => (
      S.of(context).channel_preset_whatsapp_personal_ask,
      S.of(context).channel_preset_whatsapp_personal_answer
    ),
    whatsappBusiness => (
      S.of(context).channel_preset_whatsapp_business_ask,
      S.of(context).channel_preset_whatsapp_business_answer
    ),
    instagram => (
      S.of(context).channel_preset_instagram_ask,
      S.of(context).channel_preset_instagram_answer
    ),
    messenger => (
      S.of(context).channel_preset_messenger_ask,
      S.of(context).channel_preset_messenger_answer
    ),
    telegram => (
      S.of(context).channel_preset_telegram_ask,
      S.of(context).channel_preset_telegram_answer
    )
  };
}
