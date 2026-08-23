import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:app/toolkit/toolkit.dart';

/// Muestra [url] a pantalla completa, encima de todo, y vuelve cuando se cierra.
///
/// No es un [showModal] y no puede serlo: un modal se mide contra el contenido
/// de la pantalla y deja el ancho a poco mas de la mitad, que para leer una
/// ficha esta bien y para mirar una foto no —lo que se quiere ahi es la foto lo
/// mas grande que entre—. Esto ocupa todo, oscurece lo de atras y no dibuja ni
/// un marco: la imagen es la pantalla.
///
/// Se cierra de las tres maneras que uno lo intenta: tocando el fondo, con la
/// cruz de la esquina o con Escape.
Future<void> showImageViewer(BuildContext context, {required String url}) {
  if (url.isEmpty) return Future.value();

  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black87,
    barrierDismissible: true,
    // El fondo ya lo pone la barrera: la ruta solo trae la imagen y su cruz.
    pageBuilder: (context, animation, secondary) => ImageViewer(url: url),
    transitionsBuilder: (context, animation, secondary, child) =>
      FadeTransition(opacity: animation, child: child),
    transitionDuration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 150)
  ));
}

/// La foto en grande y la cruz para volver.
///
/// Se puede acercar y arrastrar ([InteractiveViewer]): una foto de producto se
/// sube de hasta 1400 pixeles de lado y mirarle una etiqueta es la mitad de para
/// que se la abre en grande.
class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).maybePop();

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent()
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => close()
          )
        },
        child: Focus(
          autofocus: true,
          child: Stack(children: [
            // El fondo cierra: es lo que hace cualquier visor, y aca ademas es
            // casi toda la pantalla —una foto vertical deja los dos costados
            // libres—, asi que es lo mas facil de acertar.
            Positioned.fill(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: const SizedBox.expand()
            )),
            Positioned.fill(child: Padding(
              padding: EdgeInsets.all(AppSize.spaceL),
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  // Mientras baja se ve el cargando y no un hueco: la foto
                  // grande puede pesar, y esta pantalla es solo ella.
                  loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: Loading()),
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(
                      CI.image,
                      size: AppSize.picture,
                      color: Colors.white54
                    )
                  )
                )
              )
            )),
            Positioned(
              top: AppSize.spaceM,
              right: AppSize.spaceM,
              child: _close(context, close)
            )
          ])
        )
      )
    );
  }

  /// La cruz. Va sobre la foto, asi que lleva su propio fondo: sobre una imagen
  /// clara un icono blanco suelto no se ve.
  Widget _close(BuildContext context, VoidCallback action) => FeedbackButton(
    message: S.of(context).image_viewer_close,
    action: action,
    width: AppSize.action,
    height: AppSize.action,
    radius: AppSize.action,
    color: Colors.black45,
    child: Icon(Icons.close, size: AppSize.text, color: Colors.white)
  );
}
