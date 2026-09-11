import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/screens/modals/channels/channel_detail/channel_account.dart';
import 'package:app/screens/modals/channels/channel_detail/channel_danger.dart';
import 'package:app/screens/modals/channels/channel_detail/channel_identity.dart';

/// The parts of the channel panel that do not need its read: who the channel
/// is, the two facts about it that are never written, and the two ways of
/// undoing it.
///
/// What is pinned is the one rule that is invisible in the code and easy to
/// break later: **unlinking is only offered for WhatsApp Personal**. Every
/// other network is linked by a token that is replaced by typing over it, so
/// an "unlink" there would be a button with nothing behind it — and next to
/// "disconnect channel", which does exist, it would read as the safe one of
/// the two.
///
/// The panel itself is not mounted here: it opens by reading the channel from
/// the backend, and no test may hit the network.
void main() {
  setUpAll(() {
    // Single-write: they cannot be set again in a `setUp`.
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  ChannelLiteModel row(String provider) => ChannelLiteModel(
    id: "c1",
    provider: provider,
    scope: "messages",
    scopeName: "Messages",
    ready: true
  );

  final detail = ChannelDetailModel.fromJson({
    "id": "c1",
    "provider": "whatsapp",
    "name": "",
    "role": "sales",
    "external_id": "1029384756",
    "settings": const {"data_source": "table"},
    "tables": const [],
    "ready": true
  });

  Widget wrap(ChannelLiteModel channel) => MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return ChangeNotifierProvider<ChannelCatalogService>(
        create: (_) => ChannelCatalogService(),
        child: Scaffold(body: SizedBox(
          // Roughly what the side panel gives its content.
          width: 480,
          child: ListView(children: [
            ChannelIdentity(channel: channel, label: "WhatsApp Business"),
            ChannelAccount(detail: detail),
            ChannelDanger(
              channel: channel,
              label: "WhatsApp Business",
              onUnlinked: () async {},
              onDeleted: () {}
            )
          ])
        ))
      );
    })
  );

  testWidgets('a Meta channel is disconnected, never unlinked',
    (tester) async {
      await tester.pumpWidget(wrap(row("whatsapp")));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text(S.current.delete_channel), findsOneWidget);
      expect(find.text(S.current.baileys_unlink_action), findsNothing);

      // The account the backend computed is shown; the channel's own id too.
      expect(find.text('1029384756'), findsOneWidget);
      expect(find.text('c1'), findsOneWidget);
    }
  );

  testWidgets('a WhatsApp Personal channel is offered both, and they are not '
    'the same thing', (tester) async {
      await tester.pumpWidget(
        wrap(row(ChannelProviderModel.whatsappPersonalCode))
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text(S.current.baileys_unlink_action), findsOneWidget);
      expect(find.text(S.current.delete_channel), findsOneWidget);
    }
  );
}
