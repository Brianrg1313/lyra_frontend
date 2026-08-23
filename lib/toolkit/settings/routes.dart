import 'package:core/navis/screen_route.dart';

// SCREENS
import 'package:app/screens/_splash/_splash.dart';
import 'package:app/screens/login/_login.dart';
import 'package:app/screens/login/code/_code.dart';
import 'package:app/screens/sign_up/_sign_up.dart';
import 'package:app/screens/sign_up/verify_code/_verify_code.dart';
import 'package:app/screens/home/_home.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/_business_detail.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/channels/form/_channel_form.dart';
import 'package:app/screens/home/sections/connections/form/_connection_form.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';

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
  // Paso del codigo del login: se llega solo cuando el backend resolvio que la
  // cuenta entra con codigo, nunca por si sola.
  ScreenRoute(
    key: "sign_in_code",
    url: "/login/code",
    parents: ["login"],
    page: (_) => const SignInCode()
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
  // Una empresa: sub-pagina de la seccion `business`. Comparte el shell del
  // home (misma pagina del Navigator) y declara `business` como parent para que
  // su opcion siga marcada en el side bar. La empresa se resuelve del segmento
  // `:id`; el shell no recibe args por constructor.
  //
  // Sin pestana: es el link de una empresa "a secas" y abre la pestana inicial.
  ScreenRoute(
    key: BusinessDetailSection.routeKey,
    url: "/home/business/:id",
    parents: ["business"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Cada pestana de una empresa es una ruta propia, por lo que se refleja en la
  // URL y se puede copiar el link de lo que se esta mirando
  // (`/home/business/:id/statistics`).
  //
  // Son rutas distintas y no una sola con un `:tab` como argumento porque el
  // shell se entera de la pantalla abierta por `Navis.currentKey`: con una key
  // para las cinco, cambiar de pestana cambiaria la URL sin repintar nada.
  //
  // La lista sale de [BusinessTab] y no se escribe aca: la pestana ya sabe su
  // segmento y su key (ver `BusinessTab.path`).
  ...BusinessTab.values.map((tab) => ScreenRoute(
    key: tab.routeKey,
    url: tab.path(":id"),
    parents: ["business"],
    shell: Home.shell,
    page: (_) => const Home()
  )),
  // Vista de una tabla y sus datos: sub-pagina de `inventory`, con el mismo
  // criterio que la pagina de una empresa. La tabla se resuelve del segmento
  // `:id`.
  //
  // Es la unica ruta que cuelga de una tabla: sus ajustes son un panel al
  // costado (`showTableSettings`) que se abre encima del listado o de la
  // planilla, asi que la URL sigue siendo la de lo que quedo debajo.
  ScreenRoute(
    key: TableViewSection.routeKey,
    url: "/home/inventory/:id",
    parents: ["inventory"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Alta de un canal. Va **antes** que la ruta del canal por id y ademas es un
  // segmento fijo, asi que `/home/channels/new` resuelve a esta y no se lee
  // como el id de un canal llamado "new".
  ScreenRoute(
    key: ChannelFormSection.createRouteKey,
    url: "/home/channels/new",
    parents: ["channels"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Configuracion de un canal ya conectado: la misma pantalla que el alta, con
  // el canal resuelto del segmento `:id`.
  ScreenRoute(
    key: ChannelFormSection.editRouteKey,
    url: "/home/channels/:id",
    parents: ["channels"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Alta de una conexion. Igual que la de un canal, va **antes** que la ruta por
  // id y es un segmento fijo, asi que `/home/connections/new` resuelve a esta y
  // no se lee como el id de una conexion llamada "new".
  ScreenRoute(
    key: ConnectionFormSection.createRouteKey,
    url: "/home/connections/new",
    parents: ["connections"],
    shell: Home.shell,
    page: (_) => const Home()
  ),
  // Credenciales de una cuenta ya conectada: la misma pantalla que el alta, con
  // la conexion resuelta del segmento `:id`.
  ScreenRoute(
    key: ConnectionFormSection.editRouteKey,
    url: "/home/connections/:id",
    parents: ["connections"],
    shell: Home.shell,
    page: (_) => const Home()
  )
];