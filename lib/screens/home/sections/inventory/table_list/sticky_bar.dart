import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A bar of the inventory section that travels differently from the rest of the
/// scroll.
///
/// The whole section scrolls together —the action bar, the tables grid and the
/// stock summary, one behind the other— and these are the two rows that don't
/// leave it entirely:
///
/// * With [floating] the bar hides when scrolling down and **comes back as soon
///   as you scroll the other way**, without having to go all the way to the
///   top. It's what Android bars do: when reading downward the bar gets in the
///   way, and when looking for an action you want it right there and not at the
///   end of a trip.
/// * With [pinned] the bar stays stuck at the top while there's its own content
///   below. That's what a column list needs: the numbers of row forty mean
///   nothing without the title that says which is which.
///
/// Both take up space while they're seen, so **they stack instead of covering
/// each other**: with the action bar in view, the column header sticks below it
/// and not behind it.
///
/// Both cases need the same thing: **a height declared in advance**. A sliver
/// like this has to know how much it measures before measuring what it carries
/// —on that depend how much it moved and how much is left in view—, so [height]
/// is set by whoever uses it and the content fits itself to it.
///
/// The background is deliberately opaque: the bar stays above what scrolls, and
/// without it the content would be seen passing behind the letters.
class StickyBar extends StatefulWidget {
  const StickyBar({
    super.key,
    required this.height,
    required this.child,
    this.pinned = false,
    this.floating = false,
    this.color
  });

  /// How much the open bar measures. It's fixed: it doesn't shrink when
  /// scrolling.
  final double height;

  final Widget child;

  /// Stays at the top while the content that follows it lasts.
  final bool pinned;

  /// Hides when scrolling down and comes back when scrolling the other way.
  final bool floating;

  /// The background. By default the section's, which is what it rests on.
  final Color? color;

  @override
  State<StickyBar> createState() => _StickyBarState();
}

/// **Why the floating bar doesn't use the framework's `floating`.**
///
/// That one reveals the bar in proportion to any backward movement, however
/// small, and only finishes entering or leaving once the finger is released.
/// With a finger it works; with a wheel or a trackpad there's no finger to
/// release and the ticks come with micro-bounces of two or three pixels, so the
/// bar peeks out and hides in consecutive frames —and while at it shakes the
/// header that sticks below it—. It looks like a flicker.
///
/// Here the bar has no in-between states that depend on the finger: **it's
/// either there or it isn't**, and it goes from one to the other with its own
/// animation. What decides it is the direction of what accumulated since the
/// last direction change, against a threshold ([_threshold]) that a wheel
/// bounce doesn't reach.
class _StickyBarState extends State<StickyBar>
  with SingleTickerProviderStateMixin {

  /// How much you have to scroll in one direction for the bar to react.
  ///
  /// It falls between the two things to distinguish: the bounce the wheel and
  /// trackpad bring when braking is two or three pixels, and the shortest tick
  /// of a real wheel passes fifty. So a deliberate movement brings it back
  /// right away and an involuntary one doesn't move it.
  static const double _threshold = 20;

  /// 1 with the bar in view, 0 hidden. It's the height it occupies, so
  /// animating it also moves what's below it.
  late final AnimationController _visible = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 200)
  );

  /// The scroll the bar belongs to. It's listened to instead of receiving
  /// notices from above: the bar is the only one that needs to know it scrolled.
  ScrollPosition? _position;

  /// Where the scroll was the last time, to know which way it went.
  double _last = 0;

  /// How much has been scrolled in the current direction. It resets on
  /// direction change: what matters is the movement being made now, not the
  /// balance of the whole route.
  double _travel = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.floating) return;

    final position = Scrollable.of(context).position;
    if (position == _position) return;

    _position?.removeListener(_onScroll);
    _position = position..addListener(_onScroll);
    _last = position.hasPixels ? position.pixels : 0;
    _travel = 0;
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _visible.dispose();
    super.dispose();
  }

  /// The scroll moved: see if it's enough to hide the bar or to bring it back.
  void _onScroll() {
    final position = _position;
    if (position == null || !position.hasPixels) return;

    final delta = position.pixels - _last;
    _last = position.pixels;

    // While the bar is opening or closing it's already decided, and besides its
    // own height change moves the scroll: listening to itself would be fighting
    // its animation.
    if (delta == 0 || _visible.isAnimating) return;

    // At the very top the bar is always there. It's where the section starts
    // and where it's looked for: hiding it there would be hiding it while no one
    // has left it.
    if (position.pixels <= position.minScrollExtent) {
      _travel = 0;
      _visible.forward();
      return;
    }

    if (delta.isNegative != _travel.isNegative) _travel = 0;
    _travel += delta;

    if (_travel > _threshold) {
      _visible.reverse();
    } else if (_travel < -_threshold) {
      _visible.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? ThemeColor.of(context).surface;

    if (!widget.floating) {
      return SliverPersistentHeader(
        pinned: widget.pinned,
        delegate: _StickyBarDelegate(
          height: widget.height,
          color: color,
          child: widget.child
        )
      );
    }

    // Pinned also when it floats: what hides it isn't leaving with the content
    // but its height reaching zero. So the only thing that moves it is its
    // animation, and not every pixel scrolled.
    return AnimatedBuilder(
      animation: _visible,
      builder: (context, _) => SliverPersistentHeader(
        pinned: true,
        delegate: _StickyBarDelegate(
          height: widget.height * _visible.value,
          full: widget.height,
          color: color,
          child: widget.child
        )
      )
    );
  }
}

class _StickyBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyBarDelegate({
    required this.height,
    required this.color,
    required this.child,
    double? full
  }) : full = full ?? height;

  /// How much it occupies now. Hiding it's less than [full], and zero altogether.
  final double height;

  /// How much the content measures, which doesn't change: the bar doesn't
  /// shrink when hiding, it moves up and what still peeks out is what's seen.
  final double full;

  final Color color;
  final Widget child;

  /// The two are equal: the bar always measures the same while the scroll
  /// crosses it. Different would be a bar that shrinks when going up, which is
  /// another thing and not what's needed here.
  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  /// The content keeps its height and slides up: what's leftover stays outside
  /// the clip. Shrinking it instead would squish the buttons against the title
  /// before disappearing.
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
    ClipRect(child: OverflowBox(
      alignment: Alignment.bottomCenter,
      minHeight: full,
      maxHeight: full,
      child: ColoredBox(color: color, child: child)
    ));

  @override
  bool shouldRebuild(covariant _StickyBarDelegate old) =>
    old.height != height ||
    old.full != full ||
    old.color != color ||
    old.child != child;
}
