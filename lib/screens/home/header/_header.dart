import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business_listener.dart';

import './business_selector.dart';

/// Barra superior del home: el buscador de la app, la empresa activa y los
/// accesos que no son de ninguna seccion en particular (notificaciones y bandeja
/// de entrada).
///
/// Es fija igual que el side bar: se construye una sola vez en el shell y no se
/// vuelve a montar al cambiar de seccion, asi que conserva su estado (lo que se
/// escribio, el foco del campo) mientras se navega. Por eso el buscador es uno
/// solo para todo el home en vez de uno por seccion.
///
/// Lo que se escribe no se guarda aca sino en [HomeService.searchQuery]: el
/// header esta afuera de la seccion abierta, y ese es el punto donde las dos
/// partes se encuentran. Cada seccion decide que hacer con el texto y las que
/// todavia no buscan nada simplemente no lo leen. Los listados (las tablas, las
/// conexiones) filtran las filas que ya tienen por el nombre o la descripcion;
/// una planilla abierta se lo manda al backend y vuelve a leer sus filas ya
/// filtradas, porque de una tabla de cientos de miles de registros lo que tiene
/// es un puñado de tramos y buscar en ellos no seria buscar en la tabla.
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  /// Ancho maximo del buscador. Se corta antes del borde porque un campo de
  /// texto tan ancho como la pantalla es incomodo de leer, y porque el resto de
  /// la barra queda libre para lo que se agregue mas adelante.
  static const double _searchWidth = 320;

  /// Techo del selector de empresa. No mide su ancho —el selector se mide por
  /// el nombre de la empresa activa—, solo evita que uno largo empuje al
  /// buscador contra el borde.
  static double get _businessMaxWidth => AppSize.action * 4.5;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

/// Escucha el cambio de empresa con el mismo mixin que las sub-paginas: la
/// suscripcion al servicio se arma en `didChangeDependencies` y se suelta en
/// `dispose` contra la referencia guardada, no contra el `context`. Un header
/// que se desmonta —cambiar de disposicion al redimensionar la ventana— ya no
/// tiene arbol arriba desde donde volver a buscar el servicio.
class _HomeHeaderState extends State<HomeHeader>
    with BusinessListener<HomeHeader> {
  /// El buscador vive lo que vive el header, asi que el controlador es de esta
  /// pantalla y no del input que lo dibuja.
  ///
  /// Por eso se crea con un form propio: sin el, `InputController.search()` arma
  /// uno marcado como `controlledByInput` y entonces [SearchInput] se toma por
  /// dueno y lo libera al desmontarse. Como el header sigue vivo y guarda el
  /// mismo controlador, cualquier remontaje del input —un cambio de disposicion,
  /// un hot reload que mueva el arbol— lo dejaria dibujando un campo con el
  /// `FocusNode` ya desechado: "A FocusNode was used after being disposed".
  final _form = FormController();
  late final _search = InputController.search(form: _form);

  @override
  void initState() {
    super.initState();

    // La busqueda se vacia al cambiar de pantalla, no al cambiar de seccion: una
    // sub-pagina (el perfil de una empresa, una planilla) tampoco busca lo mismo
    // que el listado del que se entro.
    Navis.currentKey.addListener(_screenChanged);
  }

  /// Y tambien al cambiar de empresa, por lo mismo que el shell vuelve a montar
  /// la seccion entera: lo que se escribio era sobre la empresa anterior.
  @override
  void onBusinessChanged(String businessId) => _clear();

  @override
  void dispose() {
    Navis.currentKey.removeListener(_screenChanged);

    // El form libera a sus inputs, el buscador entre ellos. Va despues de los
    // listeners y antes de `super.dispose()`: el input ya se desmonto (los hijos
    // se desmontan primero) y por lo tanto ya se solto de todo lo del form.
    _form.dispose();
    super.dispose();
  }

  void _screenChanged() => _clear();

  /// Vacia el buscador: el campo y el texto que leen las secciones.
  ///
  /// Se limpia el `textController` en vez de reconstruir el input para no perder
  /// el controlador: el campo es el mismo de siempre, lo unico que se va es lo
  /// que decia.
  void _clear() {
    if (!mounted) return;
    if (_search.text.isNotEmpty) _search.textController.clear();
    context.read<HomeService>().clearSearch();
  }

  /// Todo lo de la derecha mide lo que mide y el buscador se queda con el resto:
  /// es lo unico que no se rompe por ser mas angosto.
  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.gap),
    child: Row(children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: HomeHeader._businessMaxWidth),
        child: const BusinessSelector()
      ),
      Expanded(child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: HomeHeader._searchWidth),
          child: SearchInput(
            controller: _search,
            placeholder: S.of(context).search_in_app,
            // [SearchInput] ya espera a que se deje de escribir, asi que esto
            // corre por busqueda y no por tecla.
            onSearch: (value) => context.read<HomeService>().search(value)
          )
        )
      )),
      _HeaderAction(
        icon: CI.notification,
        message: S.of(context).notifications,
        action: _soon
      ),
      _HeaderAction(
        icon: CI.mail,
        message: S.of(context).inbox,
        action: _soon
      )
    ])
  );

  // Ninguno de los dos paneles existe todavia. Se avisa en vez de dejar el boton
  // mudo: un boton que no hace nada al tocarlo se lee como que la app fallo.
  void _soon() => FloatFlag.of(context).message(S.of(context).coming_soon);
}

/// Boton de icono de la barra: mismo alto que el buscador para que la fila
/// quede pareja.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;

  /// Que es el boton. Es su tooltip, y lo unico que lo nombra: el boton es solo
  /// el icono.
  final String message;

  final void Function() action;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    message: message,
    radius: AppSize.cornerInset(AppSize.gap),
    color: ThemeColor.of(context).surface,
    feedbackColor: ThemeColor.of(context).line,
    child: SizedBox(
      width: AppSize.action,
      height: AppSize.action,
      child: Center(child: Icon(
        icon,
        size: AppSize.text * 1.4,
        color: ThemeColor.of(context).icon
      ))
    )
  );
}
