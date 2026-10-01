import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:app/toolkit/toolkit.dart';
import 'package:app/toolkit/lan_image.dart';

/// Shows [url] full screen, above everything, and goes back when it closes.
///
/// It is not a [showModal] and cannot be: a modal is measured against the
/// content of the screen and leaves the width at a little more than half,
/// which is fine for reading a card and not for looking at a photo —what is
/// wanted there is the photo as big as it fits—. This takes up everything,
/// darkens what is behind and does not draw even a frame: the image is the
/// screen.
///
/// It closes in the three ways one tries it: touching the background, with the
/// corner cross or with Escape.
Future<void> showImageViewer(BuildContext context, {required String url}) {
  if (url.isEmpty) return Future.value();

  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black87,
    barrierDismissible: true,
    // The background is already put by the barrier: the route only brings the
    // image and its cross.
    pageBuilder: (context, animation, secondary) => ImageViewer(url: url),
    transitionsBuilder: (context, animation, secondary, child) =>
      FadeTransition(opacity: animation, child: child),
    transitionDuration: MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 150)
  ));
}

/// The photo big and the cross to go back.
///
/// It can be zoomed and dragged ([InteractiveViewer]): a product photo is
/// uploaded up to 1400 pixels per side and looking at a label is half of why
/// it is opened big.
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
            // The background closes: that is what any viewer does, and here it
            // is also almost the whole screen —a vertical photo leaves the two
            // sides free—, so it is the easiest thing to hit.
            Positioned.fill(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: const SizedBox.expand()
            )),
            Positioned.fill(child: Padding(
              padding: EdgeInsets.all(AppSize.spaceL),
              child: InteractiveViewer(
                maxScale: 5,
                child: Image(
                  image: mediaImage(url),
                  fit: BoxFit.contain,
                  // While it downloads, the loading is seen and not a hole: the
                  // big photo can weigh a lot, and this screen is only it.
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

  /// The cross. It goes over the photo, so it carries its own background:
  /// over a bright image a loose white icon is not seen.
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