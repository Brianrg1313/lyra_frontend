import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_preset.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/services/channels/channel_tools.dart';
import 'package:app/services/channels/channels_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/messages/start/_start.dart';

/// The ready-made channels the messages section offers a company with none.
///
/// A preset only fills the create form: its network, role and tools, and —
/// the one thing the form has no picker for — the scope of a network with
/// several jobs (Instagram's direct messages). That scope travels only while
/// that network stays chosen, or switching networks in the panel would send
/// a job the new one may not have. Which presets show follows the catalog: a
/// network it lacks is not offered, one this app can't configure yet is
/// shown disabled ("Soon"), and WhatsApp Personal never waits for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  ChannelProviderModel provider(String code, List<String> scopes) => ChannelProviderModel(
    provider: code,
    name: code,
    capabilities: const ["messages"],
    scopes: [for (final scope in scopes) ChannelProviderScope(scope: scope, name: scope)]
  );

  final catalogue = [
    provider("whatsapp", ["messages"]),
    provider("messenger", ["messages"]),
    provider("instagram", ["messages", "comments", "ad_comments", "mentions"]),
    provider("telegram", ["messages"])
  ];

  test('a preset fills network, role and tools, and fixes the scope', () {
    final controller = ChannelFormController(channelId: "");
    addTearDown(controller.dispose);

    controller.applyPreset(ChannelPreset.instagram);

    expect(controller.provider.value, "instagram");
    expect(controller.role.value, ChannelAgentRole.seller);
    expect(controller.tools.value, {ChannelTool.images});
    expect(controller.payload(catalogue[2])["SCOPE"], "messages");
  });

  test('the fixed scope goes away with its network', () {
    final controller = ChannelFormController(channelId: "");
    addTearDown(controller.dispose);

    controller.applyPreset(ChannelPreset.instagram);
    controller.provider.value = "whatsapp";

    expect(controller.fixesScope("whatsapp"), isFalse);
    expect(controller.payload(catalogue[0])["SCOPE"], "messages");
  });

  test('which presets show follows the catalog', () {
    final catalog = ChannelCatalogService();
    addTearDown(catalog.dispose);

    // Not loaded: only the one built locally.
    expect(ChannelPreset.whatsappPersonal.offerIn(catalog), ChannelPresetOffer.ready);
    expect(ChannelPreset.instagram.offerIn(catalog), ChannelPresetOffer.hidden);

    catalog.seed(catalogue);

    expect(ChannelPreset.whatsappBusiness.offerIn(catalog), ChannelPresetOffer.ready);
    expect(ChannelPreset.instagram.offerIn(catalog), ChannelPresetOffer.ready);
    expect(ChannelPreset.telegram.offerIn(catalog), ChannelPresetOffer.soon);

    catalog.seed([provider("instagram", ["comments"])]);

    expect(ChannelPreset.instagram.offerIn(catalog), ChannelPresetOffer.hidden);
    expect(ChannelPreset.messenger.offerIn(catalog), ChannelPresetOffer.hidden);
  });

  for (final width in [1280.0, 420.0]) {
    testWidgets('the start lists every preset at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final catalog = ChannelCatalogService()..seed(catalogue);
      final channels = ChannelsService();
      addTearDown(catalog.dispose);
      addTearDown(channels.dispose);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Builder(builder: (context) {
          AppSize.instance(context);
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: catalog),
              ChangeNotifierProvider.value(value: channels)
            ],
            child: const Material(child: MessagesStart())
          );
        })
      ));
      await tester.pump();

      for (final title in [
        S.current.channel_preset_whatsapp_personal,
        S.current.channel_preset_whatsapp_business,
        S.current.channel_preset_instagram,
        S.current.channel_preset_messenger,
        S.current.channel_preset_telegram,
        S.current.channel_preset_blank
      ]) {
        // The picked one is named again in its preview.
        expect(find.text(title), findsWidgets);
      }

      expect(find.text(S.current.channel_preset_soon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
