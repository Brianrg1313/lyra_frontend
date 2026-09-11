import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The strip of categories at the top of the central panel: the top half of
/// section 3, which measures what its content needs.
///
/// It is **two fixed rows that grow sideways**: chips fill the first column top
/// to bottom, then the next, and the strip scrolls horizontally once they run
/// past the panel. Two rows instead of one because a catalog carries more
/// categories than a single line holds at any window width, and instead of
/// wrapping into an ever taller block because this strip sits above the
/// products —the height it takes is height they lose— so it is capped by
/// design and the overflow goes into the scroll.
///
/// Every chip is the same width for the same reason a grid exists at all: the
/// column below has to line up with the one above it, so labels are ellipsized
/// rather than measured. The full text stays reachable as the button's tooltip.
///
/// The first chip is "all" and is not a category: it is how you undo the
/// filter. Without it, once one is picked there would be no way back to the
/// whole catalog.
///
/// It does not store what is selected nor does it know what is filtered by it:
/// it receives [selected] and notifies through [onCategory]. The one in charge
/// is [PosCenterPanel], which is what holds the panel together.
class PosCategoryBar extends StatelessWidget {
  const PosCategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onCategory
  });

  /// Labels to draw, in the order the backend sends them.
  final List<String> categories;

  /// Marked category, or `null` for the whole catalog.
  final String? selected;

  /// Another category was picked. `null` is "all".
  final void Function(String? category) onCategory;

  /// Rows the grid keeps, whatever the number of categories.
  static const int rows = 2;

  /// Width of a chip. A horizontal grid has no intrinsic main-axis extent, so
  /// this is what makes the columns exist at all.
  static double get chipWidth => 250;

  /// What the strip asks the panel for: the two rows, the gap between them and
  /// the padding around the lot. A horizontally scrolling grid grows without
  /// bound on the cross axis, so this height is given and not measured.
  static double get height =>
    (70 * rows) + (AppSize.gap * (rows + 1));

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: GridView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(AppSize.gap),
      itemCount: categories.length + 1,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: rows,
        mainAxisSpacing: AppSize.gap,
        crossAxisSpacing: AppSize.gap,
        mainAxisExtent: chipWidth
      ),
      itemBuilder: (context, index) {
        // Index zero is "all", so every category sits one slot further on.
        final category = index == 0 ? null : categories[index - 1];

        return _Chip(
          label: category ?? S.of(context).pos_category_all,
          isActive: category == selected,
          action: () => onCategory(category)
        );
      }
    )
  );
}

/// A chip of the strip.
///
/// The active one takes `surfaceOver` and the inactive one the surface it rests
/// on. Both are opaque for the same reason as the business tabs: [FeedbackButton]
/// animates the color on hover, and starting from a translucent one makes the
/// transition pass through half-alpha values.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.action
  });

  final String label;
  final bool isActive;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: label,
      padding: EdgeInsets.symmetric(horizontal: AppSize.padding),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.surfaceOver : scheme.surface,
      feedbackColor: scheme.lineOver,
      child: Center(child: TextMedium(
        label,
        bold: isActive,
        multiplier: 0.95,
        ellipsis: true,
        color: isActive ? scheme.text.primary : scheme.text.secondary
      ))
    );
  }
}
