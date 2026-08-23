import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

/// Avisa a una pantalla del home que se activo otra empresa.
///
/// Todo lo que se ve dentro del home es de una empresa —las tablas, los
/// productos, los reportes—, asi que elegir otra en el selector del side bar
/// deja vieja a la pantalla que se este mirando. El caso general lo resuelve el
/// shell montando la seccion de nuevo (ver `Home`): cada seccion vuelve a pedir
/// sus datos en su `initState` sin escuchar nada por su cuenta.
///
/// Este mixin es para lo que un montaje nuevo no arregla: las **sub-paginas
/// atadas a un id** (`/home/inventory/:id`, `/home/business/:id`). Ese id es de
/// la empresa anterior —una tabla que la empresa nueva no tiene—, asi que
/// volver a montarlas con el mismo id pediria algo que ya no existe. Lo que
/// corresponde ahi es irse a donde la empresa nueva si tiene algo que mostrar.
///
/// ```dart
/// class _State extends State<Screen> with BusinessListener<Screen> {
///   @override
///   void onBusinessChanged(String businessId) =>
///     Navis.push(context, "/home/inventory");
/// }
/// ```
mixin BusinessListener<T extends StatefulWidget> on State<T> {
  BusinessService? _service;

  /// Ultima empresa vista. Es contra la que se compara cada notificacion: el
  /// servicio avisa por todo (un alta, la carga del detalle) y lo unico que
  /// interesa aca es que haya cambiado la activa.
  String? _businessId;

  /// Se acaba de activar [businessId], que no es la empresa que estaba activa.
  ///
  /// Corre fuera del `build`, sincronicamente con el cambio, asi que desde aca
  /// se puede navegar o pedir datos.
  void onBusinessChanged(String businessId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Se lee con `read` y no con `watch`: la suscripcion es a mano porque lo que
    // se quiere es una llamada al cambiar de empresa, no un rebuild por cada
    // notificacion del servicio.
    final service = context.read<BusinessService>();
    if (identical(service, _service)) return;

    _service?.removeListener(_onNotified);
    _service = service..addListener(_onNotified);
    _businessId = service.activeId;
  }

  @override
  void dispose() {
    _service?.removeListener(_onNotified);
    super.dispose();
  }

  void _onNotified() {
    final id = _service?.activeId;
    if (id == _businessId) return;

    _businessId = id;

    // Quedarse sin empresa no es cambiar de empresa: es el cierre de sesion, y
    // de esa navegacion se encarga quien lo dispara. Avisarlo mandaria a la
    // pantalla a moverse hacia algo que la sesion esta por dejar atras.
    if (id == null || !mounted) return;

    onBusinessChanged(id);
  }
}
