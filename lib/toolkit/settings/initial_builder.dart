import 'package:flutter/widgets.dart';

// Wraps the whole app before it is handed to MaterialApp.
//
// Register global ChangeNotifier services here as the app grows, e.g.:
//
//   import 'package:provider/provider.dart';
//   import 'package:app/services/home/home_service.dart';
//
//   Widget initialBuilder(Widget app) => MultiProvider(
//     providers: [
//       ChangeNotifierProvider(create: (_) => HomeService()),
//     ],
//     child: app,
//   );
Widget initialBuilder(Widget app) => app;
