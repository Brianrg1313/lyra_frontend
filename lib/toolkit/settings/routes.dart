import 'package:core/navis/screen_route.dart';

// SCREENS
import 'package:app/screens/_splash/_splash.dart';
import 'package:app/screens/login/_login.dart';
import 'package:app/screens/home/_home.dart';

final List<ScreenRoute> routes = [
  ScreenRoute(
    url: "/",
    clearHistoryOnExit: true,
    page: (_) => const Splash()
  ),
  ScreenRoute(
    url: "/login",
    page: (_) => const Login()
  ),
  ScreenRoute(
    url: "/home",
    page: (_) => const Home()
  )
];
