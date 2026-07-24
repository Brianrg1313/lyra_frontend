import 'package:core/starter.dart';

import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'toolkit/theme/dark.dart';
import 'toolkit/theme/light.dart';
import 'toolkit/settings/routes.dart';
import 'toolkit/settings/precall.dart';
import 'toolkit/settings/translations.dart';
import 'toolkit/settings/initial_builder.dart';
import 'toolkit/settings/initial_validator.dart';

void main() => starter(
  devMode: true,
  title: "Lyra",
  routes: routes,
  preCall: preCall,
  darkScheme: darkScheme,
  builder: initialBuilder,
  lightScheme: lightScheme,
  translations: translations,
  initialValidator: initialValidator,
  supportedLocales: S.delegate.supportedLocales,
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ]
);
