import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/business/business_places_service.dart';

// WIDGETS
import 'package:core/form.dart';

/// The address search at the top of the location panel: the company writes
/// where it is, picks the place from the list that drops under the box, and the
/// fields underneath are filled in.
///
/// **The answers are a dropdown and not a list in the form.** They are drawn
/// with [SelectOptionTile], the same option row a [SelectInput] uses, hanging
/// from the search box the way a select hangs from its field: picking a place
/// is picking an option, and it reads like one. It floats instead of sitting in
/// the column because these answers come and go while somebody types, and a
/// list in the form would push the address fields down and pull them back up on
/// every keystroke.
///
/// It is **not** a [SelectInput], though it looks like its dropdown: that field
/// filters a list it was given, and this one asks Google on every search. Its
/// options arrive whole and already ranked, filtering them again against the
/// typed text would drop the good ones ("Sambil" does not contain "sambil
/// chacao"), and its field rewrites itself to the chosen option's label
/// whenever the options change — over here that would erase what is being
/// typed, one answer after another.
///
/// **It takes itself away when there is nothing behind it.** An installation
/// with no Places key answers `available: false` and this draws nothing, which
/// is why the panel below it is a whole form and not a set of boxes waiting to
/// be filled: the search is a shortcut to writing the address, never the only
/// way to state it. The same holds while Google is unreachable — the dropdown
/// says so and points at the fields.
///
/// Nothing here writes: a pick is handed to [onPicked] and the panel decides
/// what to do with it, as every modal in this app does with what it collects.
class PlaceSearch extends StatefulWidget {
  const PlaceSearch({
    super.key,
    required this.controller,
    required this.places,
    required this.onPicked
  });

  /// The search field's own controller. It belongs to a form of its own, apart
  /// from the address form: what is typed here is not a field of the location
  /// and must never be validated as one.
  final InputController controller;

  final BusinessPlacesService places;

  final void Function(PlaceSuggestion suggestion) onPicked;

  @override
  State<PlaceSearch> createState() => _PlaceSearchState();
}

class _PlaceSearchState extends State<PlaceSearch> {
  /// Glues the dropdown to the box: the panel scrolls, and a list that stayed
  /// where it was drawn would end up over another field.
  final _link = LayerLink();

  final _anchor = GlobalKey();
  final _portal = OverlayPortalController();

  /// The option under the pointer, so the dropdown answers the mouse like the
  /// one a select opens.
  int _highlighted = -1;

  @override
  void initState() {
    super.initState();
    widget.places.addListener(_answered);
  }

  @override
  void dispose() {
    widget.places.removeListener(_answered);
    super.dispose();
  }

  /// The dropdown follows the search, not the taps: it opens when there is
  /// something to say about what was typed and closes when there is not —
  /// which is also how it goes away after a pick, since the panel empties the
  /// list as soon as it has read the place.
  void _answered() {
    final open = switch (widget.places.status) {
      BusinessPlacesStatus.searching ||
      BusinessPlacesStatus.ready ||
      BusinessPlacesStatus.empty ||
      BusinessPlacesStatus.error => true,
      _ => false
    };

    if (!mounted) return;

    setState(() => _highlighted = -1);

    if (open == _portal.isShowing) return;

    open ? _portal.show() : _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.places.isAvailable) return const SizedBox.shrink();

    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextMedium(S.of(context).business_location_search, bold: true),
        SizedBox(height: AppSize.gap),
        OverlayPortal(
          controller: _portal,
          overlayChildBuilder: _dropdown,
          child: CompositedTransformTarget(
            link: _link,
            child: Container(
              key: _anchor,
              child: SearchInput(
                controller: widget.controller,
                placeholder: S.of(context).business_location_search_hint,
                // The field already waits for typing to stop, so what arrives
                // at the service is a finished search and not one per key —
                // which is also what Places charges for.
                onSearch: widget.places.search
              )
            )
          )
        ),
        SizedBox(height: AppSize.gap),
        TextSmall(
          S.of(context).business_location_search_note,
          lines: 3,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        Separator.horizontal(color: scheme.line),
        SizedBox(height: AppSize.spaceS)
      ]
    );
  }

  /// The list itself, hanging from the box.
  ///
  /// The layer that fills the screen behind it is what closes the dropdown when
  /// something else is touched. It lets the touch through (`translucent`) on
  /// purpose: a company that goes straight from the list to the city field gets
  /// the field it aimed at, not a tap spent on closing a list.
  Widget _dropdown(BuildContext context) {
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;

    if (box == null || !box.hasSize) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.places.clear
        )),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, AppSize.gap),
          child: SizedBox(
            width: box.size.width,
            child: _Answer(
              places: widget.places,
              highlighted: _highlighted,
              maxHeight: _room(box),
              onHover: (index) => setState(() => _highlighted = index),
              onPicked: _pick
            )
          )
        )
      ]
    );
  }

  /// How tall the dropdown may be: what is left under the box, never the whole
  /// screen. The panel is a tall column and the search sits at its top, so
  /// there is normally room for the five places Google answers.
  double _room(RenderBox box) {
    final media = MediaQuery.of(context);
    final bottom = box.localToGlobal(Offset.zero).dy + box.size.height;

    final left = media.size.height -
      media.viewInsets.bottom -
      bottom -
      AppSize.gap -
      AppSize.spaceXS;

    return math.max(left, AppSize.action);
  }

  /// A pick closes the dropdown before the place is read: the panel empties the
  /// list once it has it, but reading takes a round trip and a list left open
  /// under the box reads as if the touch had not registered.
  void _pick(PlaceSuggestion suggestion) {
    _portal.hide();
    widget.controller.focus.unfocus();

    widget.onPicked(suggestion);
  }
}

/// What the dropdown holds: the places, or the one line that explains why there
/// are none.
class _Answer extends StatelessWidget {
  const _Answer({
    required this.places,
    required this.highlighted,
    required this.maxHeight,
    required this.onHover,
    required this.onPicked
  });

  final BusinessPlacesService places;
  final int highlighted;
  final double maxHeight;
  final void Function(int index) onHover;
  final void Function(PlaceSuggestion suggestion) onPicked;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.line(
      // Opaque, and the panel's own background: the form keeps running
      // underneath and a list one can read through is not a list.
      color: scheme.modal,
      borderColor: scheme.line,
      radius: AppSize.corner,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: switch (places.status) {
          BusinessPlacesStatus.searching => SizedBox(
            height: AppSize.action,
            child: const Center(child: Loading())
          ),
          BusinessPlacesStatus.ready => _options(context),
          BusinessPlacesStatus.error => _line(
            context,
            S.of(context).business_location_search_failed
          ),
          _ => _line(context, S.of(context).business_location_search_empty)
        }
      )
    );
  }

  /// The places, drawn with the same option row a select uses.
  ///
  /// While a pick is being read the list stops answering: two places read at
  /// once would both write over the same fields.
  Widget _options(BuildContext context) => ListView.builder(
    shrinkWrap: true,
    padding: EdgeInsets.symmetric(vertical: AppSize.gap),
    itemCount: places.suggestions.length,
    itemBuilder: (context, index) {
      final suggestion = places.suggestions[index];

      return SelectOptionTile(
        option: SelectOption(
          value: suggestion.id,
          placeholder: suggestion.title,
          subtitle: suggestion.subtitle.isEmpty ? null : suggestion.subtitle,
          icon: CI.globe_shopping
        ),
        // Nothing is "the chosen one" here: what is picked stops being an
        // option and becomes the address in the fields below.
        selected: false,
        highlighted: index == highlighted,
        onHover: () => onHover(index),
        onTap: () => places.isPicking ? null : onPicked(suggestion)
      );
    }
  );

  Widget _line(BuildContext context, String text) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.padding,
      vertical: AppSize.spaceS
    ),
    child: TextSmall(text, lines: 2, color: ThemeColor.of(context).text.secondary)
  );
}
