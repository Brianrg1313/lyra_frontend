import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/own_job_title_service.dart';
import 'package:app/services/badges/badge_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/employment_invitation_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form/style.dart';
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/pre_start/welcome/_welcome.dart';
import 'package:app/screens/modals/business/create_business/_create_business.dart';
import 'package:app/screens/modals/pre_start/invitation/_invitation.dart';

/// Active business and business switch, at the top of the side bar: what is
/// chosen here rules over everything that is seen (changing it remounts the
/// open section with the chosen data), so it heads the list of sections.
///
/// It reads the width it is given rather than the side bar's state: while the
/// bar animates, a full row in a narrow width would overflow. Wide it shows the
/// name and the chevron; narrow, only the logo.
///
/// It is also where someone who already works at a company finds the other
/// companies' invitations: `ClientService.resolve` lets them into the home
/// without answering, and nothing else in the home lists them.
class BusinessSelector extends StatefulWidget {
  const BusinessSelector({super.key});

  @override
  State<BusinessSelector> createState() => _BusinessSelectorState();
}

class _BusinessSelectorState extends State<BusinessSelector> {
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _portal = OverlayPortalController();

  bool _showing = false;
  int _highlighted = -1;

  /// Minimum width of the dropdown: the anchor shows one business and the list
  /// shows all of them, each with its name and description, so following the
  /// anchor would leave it too narrow to read.
  double get _minWidth => AppSize.action * 5.5;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();
    context.watch<ClientService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(1,1,1,0),
      child: service.hasBusiness
        ? _selectBusiness(context, service)
        : _createBusiness(context)
    );
  }

  /// A master's device sees its one company: nothing to switch to or create,
  /// so the anchor only shows it.
  bool get _single => CapabilityService().singleCompany;

  /// The invitations waiting for an answer. Never on a master's devices: its
  /// one company is the only one there is.
  List<EmploymentInvitation> _invitations(BuildContext context) =>
    _single ? const [] : context.read<ClientService>().invitations;

  // -- Anchor --

  /// Shows the active business and unfolds the list when pressed.
  Widget _selectBusiness(BuildContext context, BusinessService service) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => _dropdown(context, service),
    child: CompositedTransformTarget(
      link: _link,
      child: LayoutBuilder(builder: (context, constraints) => FeedbackButton(
        key: _anchor,
        action: _single ? null : _toggle,
        radius: AppSize.cornerInset(AppSize.gap),
        mouseCursor: _single ? SystemMouseCursors.basic : null,
        message: service.active.name,
        color: ThemeColor.of(context).navBar,
        feedbackColor: _single ? Colors.transparent : ThemeColor.of(context).line,
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: _isWide(constraints)
          ? _current(context, service.active)
          : _collapsed(context, service.active)
      ))
    )
  );

  /// Room for the logo, the name and the chevron; below it only the logo goes.
  bool _isWide(BoxConstraints constraints) => constraints.maxWidth >= AppSize.action * 3;

  /// The collapsed bar: the logo alone, the invitations' dot on its corner.
  Widget _collapsed(BuildContext context, BusinessModel business) => Center(
    child: Stack(clipBehavior: Clip.none, children: [
      _avatar(business),
      if (_invitations(context).isNotEmpty) Positioned(
        top: -AppSize.gap / 2,
        right: -AppSize.gap / 2,
        child: _dot(context)
      )
    ])
  );

  /// The name takes what the logo and the chevron leave; under it, the viewer's
  /// job title there (the dropdown keeps each company's caption).
  Widget _current(BuildContext context, BusinessModel business) {
    final titles = context.watch<OwnJobTitleService>();
    final title = titles.of(business.id);

    // Read once per company: the selector is where the switch lands.
    if (title == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => titles.load(business.id));
    }

    return Row(children: [
      _avatar(business),
      Expanded(child: Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(business.name, ellipsis: true),
            if (title != null && title.isNotEmpty)
              TextSmall(title, ellipsis: true)
          ])
      )),
      if (_single) SizedBox(width: AppSize.spaceXS) else SizedBox(
        width: AppSize.button,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedRotation(
            turns: _showing ? 0.5 : 0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              CI.arrow_down,
              color: ThemeColor.of(context).text.secondary
            )
          ),
          // An invitation is only listed inside: the dot says to look.
          if (_invitations(context).isNotEmpty) Positioned(
            top: AppSize.gap,
            right: AppSize.gap,
            child: _dot(context)
          )
        ])
      )
    ]);
  }

  /// The face of the business: its logo, or the company icon while it has none.
  /// It is the same [ProfilePicture] drawn in its record: a business is
  /// recognized by the same image no matter where it is looked at.
  ///
  /// It asks for the thumbnail and not the whole file: here it takes as much as
  /// an icon takes, and the original is the one the business uploaded, with
  /// whatever weight it has. The anchor's is as wide as the side bar's icons,
  /// so it lines up with them collapsed; the dropdown's fits its rows.
  Widget _avatar(BusinessModel business, {bool inRow = false}) => ProfilePicture(
    kind: ProfileKind.business,
    url: business.logo?.thumbnail,
    size: inRow ? AppSize.action - AppSize.spaceXS : AppSize.action,
    label: business.name
  );

  /// The same dot [BadgeMark] draws for news.
  Widget _dot(BuildContext context) => Container(
    width: AppSize.gap * 1.6,
    height: AppSize.gap * 1.6,
    decoration: BoxDecoration(
      color: badgeColor(context, BadgeLevel.info),
      shape: BoxShape.circle
    )
  );

  // -- Dropdown --

  Widget _dropdown(BuildContext context, BusinessService service) {
    final invitations = _invitations(context);
    final count = service.businesses.length;
    final geometry = _geometry(service, invitations.length);
    if (geometry == null) return const SizedBox.shrink();

    return Stack(children: [
      Positioned.fill(child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close
      )),
      CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: geometry.upward ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: geometry.upward ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, geometry.upward ? -AppSize.gap : AppSize.gap),
        child: SizedBox(
          width: geometry.width,
          child: Container(
            constraints: BoxConstraints(maxHeight: geometry.maxHeight),
            decoration: FormStyle.dropdown(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.cornerInset(1)),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: AppSize.gap),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < count; i++)
                      _option(context, service, service.businesses[i], i),
                    _separator(),
                    for (int i = 0; i < invitations.length; i++)
                      _invitationOption(context, invitations[i], count + i),
                    if (invitations.isNotEmpty) _separator(),
                    _createOption(context, count + invitations.length)
                  ])
              )
            )
          )
        )
      )
    ]);
  }

  Widget _option(
    BuildContext context,
    BusinessService service,
    BusinessModel business,
    int index
  ) {
    final isSelected = business.id == service.active.id;

    return _Hoverable(
      index: index,
      highlighted: _highlighted,
      onHover: (value) => setState(() => _highlighted = value),
      onTap: () {
        service.selectBusiness(business.id);
        _close();
      },
      child: Row(children: [
        _avatar(business, inRow: true),
        Expanded(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(business.name, ellipsis: true),
              if (business.caption.isNotEmpty)
                TextSmall(business.caption, ellipsis: true)
            ])
        )),
        if (isSelected) Icon(
          CI.check,
          size: AppSize.text * 1.2,
          color: ThemeColor.of(context).primary
        )
      ])
    );
  }

  Widget _separator() => Separator.horizontal(
    margin: EdgeInsets.symmetric(
      horizontal: AppSize.padding,
      vertical: AppSize.gap
    )
  );

  /// A company that invited the person, drawn like the ones they work at: once
  /// accepted it is one more to switch to. [overlay] as in [_createOption].
  Widget _invitationOption(BuildContext overlay, EmploymentInvitation invitation, int index) => _Hoverable(
    index: index,
    highlighted: _highlighted,
    onHover: (value) => setState(() => _highlighted = value),
    onTap: () {
      _close();
      _reviewInvitation(context, invitation);
    },
    child: Row(children: [
      ProfilePicture(
        kind: ProfileKind.business,
        url: invitation.businessLogo?.thumbnail,
        size: AppSize.action - AppSize.spaceXS,
        label: invitation.businessName
      ),
      Expanded(child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(invitation.businessName, ellipsis: true),
            TextSmall(S.of(overlay).business_selector_invitation, ellipsis: true)
          ])
      )),
      _dot(overlay)
    ])
  );

  /// Accepting re-reads `/init`, as the welcome does, for the company the
  /// person now works at, and switches to it: they picked it just now.
  Future<void> _reviewInvitation(BuildContext context, EmploymentInvitation invitation) async {
    final accepted = await showModal(
      context: context,
      title: S.of(context).welcome_invitation_modal_title,
      builder: (context) => InvitationModal(invitation: invitation)
    );

    if (accepted != true || !context.mounted) return;

    final businesses = context.read<BusinessService>();
    final route = await context.read<ClientService>().resolve();
    if (!context.mounted) return;

    // The session failed while re-reading, or another task now comes first.
    // Other invitations still pending stay here, not on the welcome.
    if (route != null && route != Welcome.path) {
      Navis.pushAndClearStack(context, route);
      return;
    }

    for (final business in businesses.businesses) {
      if (business.cloudKey == invitation.businessId) {
        businesses.selectBusiness(business.id);
        break;
      }
    }
  }

  /// [overlay] only serves to paint: when pressed the dropdown closes and that
  /// context is left unmounted, so the modal is opened with the selector's one.
  Widget _createOption(BuildContext overlay, int index) => _Hoverable(
    index: index,
    highlighted: _highlighted,
    onHover: (value) => setState(() => _highlighted = value),
    onTap: () {
      _close();
      _openCreateModal(context);
    },
    child: Row(children: [
      SizedBox(
        width: AppSize.action,
        child: Icon(CI.plus, color: ThemeColor.of(overlay).icon)
      ),
      SizedBox(width: AppSize.spaceXS),
      Expanded(child: TextMedium(S.of(overlay).create_business, ellipsis: true))
    ])
  );

  /// Recalculated on each build of the overlay, so the dropdown reacts to
  /// window size changes.
  _DropdownGeometry? _geometry(BusinessService service, int invitations) {
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final media = MediaQuery.of(context);
    final margin = AppSize.spaceXS;

    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;

    final below = (media.size.height - margin) - bottom - AppSize.gap;
    final above = top - (media.padding.top + margin) - AppSize.gap;

    // Businesses + separator + invitations (+ their separator) + the create option.
    final separators = invitations > 0 ? 2 : 1;
    final desired = (AppSize.gap * 2)
      + (_optionHeight * (service.businesses.length + invitations + 1))
      + ((AppSize.gap * 2) + 1) * separators;

    // It goes down unless it does not fit and there is more room up; the
    // anchor heads the side bar, so it almost always goes down.
    final upward = below < desired && above > below;
    double available = upward ? above : below;

    if (available < AppSize.action) {
      available = math.max(above, below);
    }

    return _DropdownGeometry(
      width: math.max(box.size.width, _minWidth),
      maxHeight: math.max(math.min(desired, available), 0),
      upward: upward
    );
  }

  // -- Interaction --

  void _toggle() => _showing ? _close() : _open();

  void _open() {
    if (_showing) return;

    setState(() {
      _showing = true;
      _highlighted = -1;
    });

    _portal.show();
  }

  void _close() {
    if (!_showing) return;

    _portal.hide();

    if (mounted) {
      setState(() {
        _showing = false;
        _highlighted = -1;
      });
    }
  }

  // -- No businesses --

  /// Without any business there is nothing to choose, so instead of the selector
  /// the registration goes: it is the only path from which everything else
  /// starts. Narrow it is the plus alone, named by its tooltip.
  Widget _createBusiness(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: LayoutBuilder(builder: (context, constraints) => _isWide(constraints)
      ? Button(
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          title: S.of(context).create_business,
          action: () => _openCreateModal(context)
        )
      : Center(child: FeedbackButton(
          action: () => _openCreateModal(context),
          message: S.of(context).create_business,
          width: AppSize.action,
          height: AppSize.action,
          radius: AppSize.cornerInset(AppSize.gap),
          color: ThemeColor.of(context).navBar,
          feedbackColor: ThemeColor.of(context).line,
          child: Center(child: Icon(CI.plus, color: ThemeColor.of(context).icon))
        )))
  );

  void _openCreateModal(BuildContext context) => showModal(
    context: context,
    title: S.of(context).create_business,
    builder: (BuildContext context) => const CreateBusinessModal()
  );
}

/// Height of each dropdown row, flush with the avatar. It is shared by the
/// geometry calculation and the rows themselves: if they diverged, the dropdown
/// would be cut or leave dead space at the end.
double get _optionHeight => AppSize.action;

/// Dropdown row: highlighted on hover, with the same padding as the
/// `SelectInput` options.
class _Hoverable extends StatelessWidget {
  const _Hoverable({
    required this.index,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
    required this.child
  });

  final int index;
  final int highlighted;
  final void Function(int index) onHover;
  final void Function() onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHover(index),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _optionHeight,
        color: FormStyle.optionFill(context, index == highlighted),
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
        child: child
      )
    )
  );
}

class _DropdownGeometry {
  const _DropdownGeometry({
    required this.width,
    required this.maxHeight,
    required this.upward
  });

  final double width;
  final double maxHeight;
  final bool upward;
}
