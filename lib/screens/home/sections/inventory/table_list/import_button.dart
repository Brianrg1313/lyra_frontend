import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Accion secundaria de la barra del listado: importar una tabla ya existente.
///
/// Es un [FeedbackButton] y no un [Button] para que no compita visualmente con
/// la accion principal, que es crear.
///
/// Mientras [loading] este en `true` el icono se cambia por un spinner y el
/// boton no responde: subir el archivo puede tardar, y sin este aviso el unico
/// rastro de que algo esta pasando seria que la tabla aparece un rato despues.
/// Escucha ese valor y no lo recibe como `bool` para que empezar y terminar la
/// subida no vuelva a construir la barra entera, igual que el buscador de al
/// lado.
///
/// Se apaga en cuanto la tabla existe, no cuando la importacion termina: lo que
/// sigue (los tipos de las columnas y las filas) tarda medio minuto largo, pasa
/// con la tabla ya en el listado y se muestra en su fila. Dejar el boton
/// apagado todo ese rato impediria importar la segunda planilla mientras la
/// primera se acomoda.
class ImportButton extends StatelessWidget {
  const ImportButton({super.key, required this.action, required this.loading});

  final void Function() action;
  final ValueListenable<bool> loading;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: loading,
    builder: (context, busy, _) => FeedbackButton(
      // Sin accion mientras sube: una segunda importacion en paralelo crearia
      // otra tabla con el mismo archivo.
      action: busy ? null : action,
      mouseCursor: busy ? SystemMouseCursors.wait : null,
      height: AppSize.button,
      color: ThemeColor.of(context).surfaceOver,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      message: S.of(context).import_table,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSize.text * 1.2,
            height: AppSize.button * 1.2,
            child: busy
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ThemeColor.of(context).icon
                )
              : Icon(
                  Icons.file_upload_outlined,
                  size: AppSize.text * 1.2,
                  color: ThemeColor.of(context).icon
                )
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(S.of(context).import_table)
        ]
      )
    )
  );
}
