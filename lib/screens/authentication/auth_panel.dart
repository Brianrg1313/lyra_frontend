import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/images.dart';

/// Brand side of the auth entry: the brand gradient with the Lyra pin cut out
/// of it in the page's own background, oversized and bleeding off the bottom
/// left. The page seems to reach into the panel, and the gradient shows again
/// through the pin's eye (the asset's hole is transparent).
///
/// Its only motion is the pin dropping in once, like a marker set on a map;
/// skipped when the platform asks for reduced motion.
class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, this.drop = true});

  /// Off on the pages after the entry: the pin already landed there, and
  /// dropping it again would read as a new page instead of the next step.
  final bool drop;

  /// `l.png` proportions (467×534): the pin is sized by height.
  static const _ratio = 467 / 534;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSize.corner),
    child: LayoutBuilder(builder: (context, box) {
      final height = box.maxHeight * 0.8;
      final width = height * _ratio;

      return Stack(fit: StackFit.expand, children: [
        const ImageDynamic("gradient-1.png"),
        Positioned(
          left: -width * 0.16,
          bottom: -height * 0.2,
          width: width,
          height: height,
          child: _Drop(still: !drop, child: ImageDynamic(
            "l.png",
            fit: BoxFit.contain,
            color: ThemeColor.of(context).background
          ))
        )
      ]);
    })
  );
}

class _Drop extends StatelessWidget {
  const _Drop({required this.child, this.still = false});

  final Widget child;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final still = this.still || MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      // The overshoot is the landing: the pin sinks slightly past its spot
      // and settles back.
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * -AppSize.spaceL * 3),
          child: child
        )
      )
    );
  }
}
