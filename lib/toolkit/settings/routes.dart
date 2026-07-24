import 'package:core/navis/screen_route.dart';

// SCREENS
import 'package:app/screens/_splash/_splash.dart';
import 'package:app/screens/login/_login.dart';
import 'package:app/screens/sign_up/_sign_up.dart';
import 'package:app/screens/sign_up/verify_code/_verify_code.dart';
import 'package:app/screens/home/_home.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/business_profile.dart';
import 'package:app/screens/home/sections/products/table_view.dart';

final List<ScreenRoute> routes = [
  ScreenRoute(
    key: "splash",
    url: "/",
    clearHistoryOnExit: true,
    page: (_) => const Splash()
  ),
  ScreenRoute(
    key: "login",
    url: "/login",
    page: (_) => const Login()
  ),
  ScreenRoute(
    key: "sign_up",
    url: "/sign_up",
    page: (_) => const SignUp()
  ),
  ScreenRoute(
    key: "verify_code",
    url: "/verify_code",
    parents: ["sign_up"],
    page: (_) => const VerifyCode()
  ),
  // Cada seccion del home es una ruta propia: se refleja en la URL y se puede
  // abrir por deep link, reusando siempre el mismo shell (side bar).
  //
  // Entre si las secciones son hermanas, no anidadas: aunque sus URLs cuelguen
  // de `/home`, ninguna vive dentro de otra. Por eso no declaran parents; el
  // home es el shell que las contiene a todas y no una pantalla mas.
  // Las sub-paginas si declaran su seccion como parent (`business_detail` ->
  // `parents: ["business"]`), que es lo que mantiene marcada la opcion del
  // side bar mientras se navega dentro de ella.
  //
  // Todas comparten `shell`, por lo que ocupan una sola pagina del Navigator:
  // cambiar de seccion actualiza el arbol en vez de apilar un shell nuevo. Por
  // eso `Home` no recibe la seccion, la lee de `Navis.currentKey`.
  ...HomeSection.values.map((section) => ScreenRoute(
    key: section.key,
    url: section.path,
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // Perfil de una empresa: sub-pagina de la seccion `business`. Comparte el
  // shell del home (misma pagina del Navigator) y declara `business` como
  // parent para que su opcion siga marcada en el side bar. La empresa se
  // resuelve del segmento `:id`; el shell no recibe args por constructor.
  ScreenRoute(
    key: BusinessProfileSection.routeKey,
    url: "/home/business/:id",
    parents: ["business"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Vista de una tabla y sus datos: sub-pagina de `products`, con el mismo
  // criterio que el perfil de una empresa. La tabla se resuelve del segmento
  // `:id`.
  ScreenRoute(
    key: TableViewSection.routeKey,
    url: "/home/products/:id",
    parents: ["products"],
    shell: Home.shell,
    page: (_) => const Home()
  )
];