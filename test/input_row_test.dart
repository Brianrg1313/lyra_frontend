import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/screens/modals/business/create_business/_create_business.dart';

/// `InputRow` fills its width without a `LayoutBuilder`: `showImageModal` measures its content
/// through an `IntrinsicWidth`, and a `LayoutBuilder` can't answer that. The welcome's create
/// company on a master (whose currency and language share a row) failed its layout: only the
/// barrier showed, and every mouse event after it tripped the mouse tracker.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  tearDown(() => Deployment.use(DeploymentMode.cloud));

  testWidgets("a master's create company lays out inside the image modal", (tester) async {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(builder: (context) {
        AppSize.instance(context);

        return Material(child: Center(child: ModalImage(
          image: const SizedBox(),
          imageHeight: 160,
          title: "Create",
          builder: (_) => const CreateBusinessModal()
        )));
      })
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.lan_master_currency), findsWidgets);
    expect(tester.getSize(find.byType(InputRow)).width, greaterThan(0));
  });
}
