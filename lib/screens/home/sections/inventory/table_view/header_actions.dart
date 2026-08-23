import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

/// El estado de la lectura de registros y de la busqueda, arriba a la derecha.
///
/// Va arriba y no debajo de la planilla porque la planilla ya no termina: se
/// sigue de largo bajando, asi que no hay un final donde apoyar una barra. Y
/// mientras se escribe conviene que lo de arriba no se mueva, cosa que el borde
/// de abajo no puede prometer.
///
/// No hay aca ningun boton de guardar: las filas escritas se guardan solas al
/// salir de ellas (ver `SheetController`), asi que no queda nada pendiente que
/// juntar en un boton.
///
/// Es lo unico de la pantalla que escucha el ir y venir de la lectura: los
/// tramos que entran y salen mueven este spinner, no la grilla.
class HeaderActions extends StatelessWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // El spinner cubre las dos esperas que no tapan la planilla: un tramo de
    // registros que esta entrando y una relectura de la estructura (un cambio de
    // columna). La segunda importa desde que la pantalla dejo de desmontarse
    // para releerla: sin esto, el unico aviso de que el cambio viaja seria el
    // titulo apagado de esa celda.
    final (loading, failed) = context.select<TableViewService, (bool, bool)>(
      (service) => (
        service.isLoadingRows || service.isReloading,
        service.status == TableViewStatus.error
      )
    );

    // Cuantas filas coinciden con lo que se busco, o `null` si no se esta
    // buscando nada. Es lo unico que dice que la planilla esta filtrada: sin
    // esto, una tabla de mil filas mostrando tres se leeria como una tabla de
    // tres filas.
    final matches = context.select<TableViewService, int?>(
      (service) => service.isSearching ? service.records : null
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mientras el tramo viaja no se dice nada: hasta que llegue la cuenta es
        // cero, y anunciar que no hay resultados para despues mostrarlos es
        // peor que no decir nada. El spinner de al lado ya explica la espera.
        if (matches != null && !loading) ...[
          TextSmall(
            S.of(context).product_table_view_search_count(matches),
            color: scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap)
        ],
        if (loading) ...[
          SizedBox(
            width: AppSize.text,
            height: AppSize.text,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.spaceS)
        ],
        if (failed) ...[
          TextSmall(
            S.of(context).product_table_view_error_title,
            color: scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap),
          _ActionButton(
            icon: Icons.refresh,
            message: S.of(context).product_tables_retry,
            action: context.read<TableViewService>().retry
          ),
          SizedBox(width: AppSize.spaceS)
        ]
      ]
    );
  }
}

/// Boton de icono de la barra superior. Apagado (gris, sin accion) cuando
/// [action] es nulo.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;
  final String message;
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      width: AppSize.action,
      height: AppSize.action,
      color: scheme.surfaceOver,
      message: message,
      child: Center(child: Icon(
        icon,
        color: action == null ? scheme.text.secondary : scheme.text.primary
      ))
    );
  }
}
