import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channel_table_model.dart';
import 'package:app/screens/home/sections/channels/channel_list/channel_card.dart';

/// What a channel's card says about the data it answers from.
///
/// The rule being pinned is that it **names** the table instead of counting
/// it: a channel carries no name of its own, so the table is the only word on
/// the card written by the company, and "1 table" told two cards of the same
/// network on the same job apart not at all. The count came off the list
/// endpoint as `sources`; the names come off the same read now, as `tables`.
///
/// The height is pinned with it because the two are the same change: the card
/// measures a fixed [ChannelCard.height] so every row of the grid lines up,
/// and the surfaces the names sit in are taller than the line of text they
/// replaced.
void main() {
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

      // The catalog is left empty on purpose: without it the card falls back
      // to the raw provider code, which is a state it has to survive, and the
      // sources line does not depend on it at all.
      return ChangeNotifierProvider<ChannelCatalogService>(
        create: (_) => ChannelCatalogService(),
        child: Scaffold(body: Center(child: SizedBox(
          width: ChannelCard.maxWidth,
          height: ChannelCard.height,
          child: ChannelCard(channel: channel)
        )))
      );
    })
  );

  // `ThemeColor.dark`/`.light` are single-write: setting them per test throws
  // on the second one.
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('names the table it answers from instead of counting it',
    (tester) async {
      await tester.pumpWidget(wrap(const ChannelLiteModel(
        id: "a1",
        provider: "whatsapp",
        scope: "messages",
        scopeName: "Messages",
        sources: 1,
        ready: true,
        tables: [ChannelTableModel(id: "t1", name: "Winter catalogue")]
      )));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Winter catalogue'), findsOneWidget);

      // The count is gone, not merely hidden behind the name.
      expect(find.text('1 table'), findsNothing);
    }
  );

  testWidgets('a channel with no source says so, which is the point of the row',
    (tester) async {
      await tester.pumpWidget(wrap(const ChannelLiteModel(
        id: "a2",
        provider: "whatsapp",
        scope: "messages",
        scopeName: "Messages",
        ready: true
      )));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(S.current.channel_source_none), findsOneWidget);
    }
  );

  testWidgets('the named source still fits the card its grid row measures',
    (tester) async {
      // A pending channel is the tallest case: it carries the state tag as
      // well, which a ready one does not draw.
      await tester.pumpWidget(wrap(const ChannelLiteModel(
        id: "a3",
        provider: "whatsapp",
        scope: "messages",
        scopeName: "Messages",
        sources: 1,
        tables: [ChannelTableModel(id: "t1", name: "Winter catalogue")]
      )));

      await tester.pumpAndSettle();

      // An overflow is reported as an exception by the test binding, so this
      // is the assertion — there is no measurement to compare against.
      expect(tester.takeException(), isNull);
    }
  );
}
