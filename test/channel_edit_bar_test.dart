import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/modals/channels/channel_detail/edit_bar.dart';

/// That the channel panel offers to confirm or cancel **only once there is
/// something to confirm**.
///
/// A save button parked under an untouched form means nothing when it is
/// pressed and, worse, invites being pressed before closing just in case. So
/// the pair appearing is itself the message that a change is pending, which
/// only works if it is genuinely absent the rest of the time.
void main() {
  setUpAll(() {
    // Single-write: they cannot be set again in a `setUp`.
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Widget wrap(ChannelFormController controller) => MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: ChannelEditBar(
        controller: controller,
        onCancel: () {},
        onSave: () {}
      ));
    })
  );

  ChannelFormController seeded() {
    final controller = ChannelFormController(channelId: "c1")
      ..apply(ChannelDetailModel.fromJson({
        "id": "c1",
        "provider": "whatsapp",
        "name": "",
        "role": "sales",
        "settings": const {"data_source": "table"},
        "tables": const [],
        "ready": true
      }));

    return controller;
  }

  testWidgets('an untouched channel shows neither button', (tester) async {
    final controller = seeded();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.save), findsNothing);
    expect(find.text(S.current.cancel), findsNothing);
  });

  testWidgets('touching a field brings up confirm and cancel', (tester) async {
    final controller = seeded();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller));
    await tester.pumpAndSettle();

    controller.role.value = ChannelAgentRole.support;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.save), findsOneWidget);
    expect(find.text(S.current.cancel), findsOneWidget);

    // And they go away again on their own when the change is undone by hand,
    // without anybody pressing cancel.
    controller.role.value = ChannelAgentRole.seller;
    await tester.pumpAndSettle();

    expect(find.text(S.current.save), findsNothing);
  });
}
