import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';

/// Eliminar la empresa: lo ultimo de la ficha, y lo unico que no se deshace.
///
/// Va al final y no arriba con el resto de las acciones por lo mismo que se
/// escribe al final de una carta lo que no se quiere leer primero: no es un
/// dato que se corrige, es el final de todo lo demas. Quien entra a cambiar el
/// telefono no se lo cruza.
///
/// El aviso va **arriba** del boton, no en el modal que confirma: lo que se
/// pierde y cuanto tarda en perderse es lo que hace decidir, y en el modal
/// llegaria cuando ya se decidio. El modal solo vuelve a preguntar.
///
/// Solo lo ve el dueño. Es lo unico de la ficha que se muestra segun quien
/// mira: el resto se lee igual desde cualquier rango, pero una empresa la borra
/// quien la creo.
class BusinessProfileDanger extends StatelessWidget {
  const BusinessProfileDanger({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final danger = scheme.snackBar.error;

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextSmall(
            S.of(context).business_delete_section,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: AppSize.gap),
                child: Icon(CI.info, size: AppSize.text, color: danger)
              ),
              SizedBox(width: AppSize.spaceXS),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Que se lleva puesto y cuando: son las dos preguntas que se
                  // hace quien esta por tocar el boton, y en ese orden.
                  TextMedium(S.of(context).business_delete_warning, lines: 4),
                  SizedBox(height: AppSize.gap),
                  TextSmall(
                    S.of(context).business_delete_schedule,
                    lines: 4,
                    color: scheme.text.secondary
                  ),
                  SizedBox(height: AppSize.spaceS),
                  _button(context, scheme, danger)
                ]
              ))
            ]
          )
        ]
      )
    );
  }

  /// El boton no se pinta entero de rojo: en una ficha que es para leer, un
  /// bloque de color se lleva la vista antes que cualquier dato. El rojo esta
  /// donde tiene que estar —el texto y el icono— y el fondo se enciende recien
  /// al apuntarlo.
  Widget _button(BuildContext context, SchemeColor scheme, Color danger) =>
    Align(alignment: Alignment.centerLeft, child: FeedbackButton(
      action: () => _confirm(context),
      height: AppSize.button,
      message: S.of(context).business_delete_action,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: danger.withValues(alpha: 0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.trash, size: AppSize.text, color: danger),
          SizedBox(width: AppSize.gap),
          TextSmall(S.of(context).business_delete_action, color: danger)
        ]
      )
    ));

  /// Vuelve a preguntar, con el nombre de la empresa adentro: es lo unico que
  /// distingue a esta de las otras del cliente, y lo que hay que reconocer
  /// antes de aceptar.
  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).business_delete_confirm_title,
      message: S.of(context).business_delete_confirm_message(profile.name),
      confirmText: S.of(context).business_delete_action,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // El backend todavia no tiene con que: no hay endpoint de baja de empresas
    // ni, por lo tanto, los dos plazos que promete el aviso —los pone el
    // proceso de baja, no esta pantalla—. Se avisa en vez de dejar el boton
    // mudo, como los paneles que faltan en la barra de arriba, y cuando exista
    // lo unico que cambia aca es esta linea por la llamada al servicio.
    FloatFlag.of(context).message(S.of(context).coming_soon);
  }
}
