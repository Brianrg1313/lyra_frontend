import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

/// Every profile picture is core's `ProfilePicture`: without an image it draws its kind's icon,
/// never initials; a photo that fails falls back to the same icon; a photo is decoded at a
/// bounded size, not the original's.
Widget _app(Widget child) => MaterialApp(home: Builder(builder: (context) {
  AppSize.instance(context);
  return Center(child: child);
}));

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets("without an image each kind draws its icon and no letters", (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      ProfilePicture(kind: ProfileKind.employee, size: 40, label: "Ana Pérez"),
      ProfilePicture(kind: ProfileKind.business, size: 40, url: "", label: "Acme"),
      ProfilePicture(kind: ProfileKind.customer, size: 40, label: "Juan")
    ])));

    expect(find.byIcon(CI.employee), findsOneWidget);
    expect(find.byIcon(CI.store), findsOneWidget);
    expect(find.byIcon(CI.user), findsOneWidget);
    expect(find.text("AP"), findsNothing);
    expect(find.text("A"), findsNothing);
    expect(find.bySemanticsLabel("Ana Pérez"), findsOneWidget);
  });

  testWidgets("a photo is decoded at a bounded size and falls back to the icon when it fails", (tester) async {
    await tester.pumpWidget(_app(const ProfilePicture(
      kind: ProfileKind.user,
      size: 40,
      url: "https://example.com/face.png"
    )));

    final image = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    final pixels = (40 * tester.view.devicePixelRatio * 2).round();
    expect(image.width, pixels);
    expect(image.height, pixels);
    expect((image.imageProvider as NetworkImage).url, "https://example.com/face.png");

    // The test binding answers every http request with 400: the download fails.
    await tester.pumpAndSettle();
    expect(find.byIcon(CI.user), findsOneWidget);
  });
}
