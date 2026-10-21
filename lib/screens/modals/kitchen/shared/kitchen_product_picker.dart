import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_product_search.dart';

// WIDGETS
import 'package:core/form.dart';

/// A search over every table that hands back the product picked: a recipe's ingredient, an
/// option's extra, a product that offers a group. [exclude] are not offered (already there).
///
/// The answers drop under the box like a select's options, each named by its title alone: the
/// table it comes from, its stock, its SKU are not what a person picks it by, and a list
/// growing inside the panel pushed everything under it down on every keystroke.
///
/// The search lives as long as the picker (a panel, above the section's providers).
class KitchenProductPicker extends StatefulWidget {
  const KitchenProductPicker({
    super.key,
    required this.placeholder,
    required this.onPick,
    this.exclude = const {},
    this.supplies = true,
    this.catalog = true
  });

  final String placeholder;
  final void Function(KitchenProduct product) onPick;

  /// Product ids not offered.
  final Set<String> exclude;
  final bool supplies;
  final bool catalog;

  @override
  State<KitchenProductPicker> createState() => _KitchenProductPickerState();
}

class _KitchenProductPickerState extends State<KitchenProductPicker> {
  late final _search = KitchenProductSearch(supplies: widget.supplies, catalog: widget.catalog);

  /// Owned by its input, which disposes it.
  final _query = InputController.search(key: "KITCHEN_PRODUCT_PICK");

  /// Glues the dropdown to the box: the panel scrolls under it.
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _portal = OverlayPortalController();

  /// The option under the pointer, so the dropdown answers the mouse like a select's.
  int _highlighted = -1;

  @override
  void initState() {
    super.initState();
    _search.addListener(_answered);
  }

  @override
  void dispose() {
    _search.removeListener(_answered);
    _search.dispose();
    super.dispose();
  }

  /// The dropdown follows the search: open while there is something to say about what was
  /// typed, closed once the box is empty again (which is also how a pick closes it).
  void _answered() {
    if (!mounted) return;

    final open = _search.status != KitchenProductSearchStatus.idle;

    setState(() => _highlighted = -1);

    if (open == _portal.isShowing) return;

    open ? _portal.show() : _portal.hide();
  }

  /// Hands [product] over and empties the search, ready for the next one: it is picked like an
  /// autocomplete, one after the other.
  void _pick(KitchenProduct product) {
    widget.onPick(product);
    _query.textController.clear();
    _search.search("");
    _query.focus.requestFocus();
  }

  List<KitchenProduct> get _offered =>
    [for (final product in _search.results) if (!widget.exclude.contains(product.id)) product];

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: _dropdown,
    child: CompositedTransformTarget(
      link: _link,
      child: KeyedSubtree(
        key: _anchor,
        child: SearchInput(controller: _query, placeholder: widget.placeholder, onSearch: _search.search)
      )
    )
  );

  /// The answers, hanging from the box. Touching anywhere else closes them and lets the touch
  /// through (`translucent`): going straight from the list to another field gets that field.
  Widget _dropdown(BuildContext context) {
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;

    if (box == null || !box.hasSize) return const SizedBox.shrink();

    return Stack(children: [
      Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _portal.hide)),
      CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, AppSize.gap),
        child: SizedBox(
          width: box.size.width,
          child: Surface.line(
            color: ThemeColor.of(context).modal,
            borderColor: ThemeColor.of(context).line,
            radius: AppSize.corner,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _room(box)),
              child: _answer(context)
            )
          )
        )
      )
    ]);
  }

  Widget _answer(BuildContext context) {
    final s = S.of(context);

    switch (_search.status) {
      case KitchenProductSearchStatus.idle:
        return const SizedBox.shrink();
      case KitchenProductSearchStatus.loading:
        return SizedBox(height: AppSize.action, child: const Center(child: Loading()));
      case KitchenProductSearchStatus.error:
        return _line(s.kitchen_pick_error);
      case KitchenProductSearchStatus.ready:
        final offered = _offered;

        if (offered.isEmpty) return _line(s.kitchen_pick_empty);

        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: AppSize.gap),
          itemCount: offered.length,
          itemBuilder: (context, index) {
            final product = offered[index];

            return SelectOptionTile(
              option: SelectOption(
                value: product.id,
                placeholder: product.label,
                icon: product.supplies ? CI.warehouse : CI.product
              ),
              selected: false,
              highlighted: index == _highlighted,
              onHover: () => setState(() => _highlighted = index),
              onTap: () => _pick(product)
            );
          }
        );
    }
  }

  Widget _line(String text) => KitchenNote(
    text: text,
    padding: EdgeInsets.symmetric(horizontal: AppSize.padding, vertical: AppSize.spaceS)
  );

  /// How tall the dropdown may be: what is left under the box, never the whole screen.
  double _room(RenderBox box) {
    final media = MediaQuery.of(context);
    final bottom = box.localToGlobal(Offset.zero).dy + box.size.height;
    final left = media.size.height - media.viewInsets.bottom - bottom - AppSize.gap - AppSize.spaceXS;

    return math.max(left, AppSize.action);
  }
}

/// A secondary line of help or of what went wrong, in the kitchen's panels.
class KitchenNote extends StatelessWidget {
  const KitchenNote({super.key, required this.text, this.color, this.padding});

  final String text;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? EdgeInsets.symmetric(vertical: AppSize.gap),
    child: TextSmall(text, lines: 4, color: color ?? ThemeColor.of(context).text.secondary)
  );
}
