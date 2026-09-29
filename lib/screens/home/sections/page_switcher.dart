import 'package:flutter/material.dart';

/// Swaps the pages of one section —its sub-pages and its tabs— with a short
/// fade-through instead of a cut.
///
/// It is a *fade-through* and not a cross-fade: the outgoing page is gone in
/// about a hundred milliseconds and only then does the incoming one rise and
/// grow into place. Two dense pages (tables, forms) overlapped at half opacity
/// read as noise, while a brief empty frame reads as "this changed". The whole
/// swap stays around 300 ms: long enough to be seen, short enough that the page
/// is usable before the user reaches for it.
///
/// A change is detected by [id], not by the child: a tab whose body is the
/// same widget type would otherwise be updated in place and never animate. The
/// first page mounts without animation, and the system's "reduce motion"
/// setting turns the swap back into a plain cut.
///
/// Switching **sections** is not animated here: the shell keys this widget by
/// section (see `homeContent`), so a new section mounts a new switcher, and a
/// fresh switcher shows its first page as is.
class PageSwitcher extends StatelessWidget {
  const PageSwitcher({
    super.key,
    required this.id,
    required this.child
  });

  /// Identity of the page shown: a new value animates the swap.
  final Object id;

  final Widget child;

  static const Duration _duration = Duration(milliseconds: 320);

  /// The outgoing page leaves faster than the incoming one arrives: see
  /// [_curve], it is fully gone within the incoming page's hidden lead.
  static const Duration _reverseDuration = Duration(milliseconds: 120);

  /// The incoming page stays hidden for the first 30 %, which is the time the
  /// outgoing one takes to fade: that is the fade-through.
  static const Curve _curve = Interval(0.3, 1, curve: Curves.easeOutCubic);

  /// How far below its place the incoming page starts, in logical pixels.
  /// Enough to feel a direction without reading as a slide.
  static const double _rise = 24;

  /// Scale the incoming page starts at. With [_rise] it reads as the page
  /// settling into place; the outgoing one shrinks back by the same amount.
  static const double _scale = 0.97;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : _duration,
      reverseDuration: reduceMotion ? Duration.zero : _reverseDuration,
      layoutBuilder: _layout,
      transitionBuilder: _transition,
      child: KeyedSubtree(key: ValueKey(id), child: child)
    );
  }

  /// Every page fills the space, as it did before being wrapped: the default
  /// layout centers loosely and would shrink pages that expect to be stretched.
  static Widget _layout(Widget? current, List<Widget> previous) => Stack(
    fit: StackFit.expand,
    children: [...previous, ?current]
  );

  /// The outgoing page stops taking input as soon as it starts leaving: a click
  /// during those few frames must reach the page being opened, not the one
  /// underneath it.
  static Widget _transition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: _curve);

    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => IgnorePointer(
          ignoring: animation.status == AnimationStatus.reverse,
          child: Transform.translate(
            offset: Offset(0, _rise * (1 - curved.value)),
            child: Transform.scale(
              scale: _scale + (1 - _scale) * curved.value,
              child: child
            )
          )
        )
      )
    );
  }
}
