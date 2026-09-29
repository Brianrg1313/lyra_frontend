import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The tab bar of a section whose page is split into tabs.
///
/// It lives up here and not inside one of them because two sections already
/// draw it —a business and the money— and it is the same bar: the same shape,
/// the same colours and, above all, the same idea. Each tab **is a URL**, so
/// the bar never stores which one is open; it receives [active] and reports
/// through [onTab], and the one in charge is the page, which is the one that
/// navigates.
///
/// **It carries no surface.** The only one of a tabbed page is the body's, and
/// the active tab is drawn exactly with that colour: resting on the background,
/// it reads as the tongue of what is below. Wrapping the bar in its own surface
/// would split the page into two loose cards and the tab would stop pointing at
/// anything.
///
/// It is generic over the tab because every section declares its own enum (see
/// `BusinessTab`, `FinanceTab`): the icon and the title are asked for instead of
/// being read off a shared interface, which would force those enums to know
/// about this widget.
class SectionTabs<T> extends StatelessWidget {
  const SectionTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.icon,
    required this.title,
    required this.onTab,
    this.isLocked
  });

  /// Every tab of the section, in the order they are drawn.
  final List<T> tabs;

  /// The open one, the one drawn marked.
  final T active;

  final IconData Function(T tab) icon;
  final String Function(BuildContext context, T tab) title;

  /// Another tab was asked to open. It is a navigation: each tab is a URL.
  final void Function(T tab) onTab;

  /// Tabs the person is not granted: drawn with a lock instead of their icon. They still
  /// open, onto the "no access" message that offers to ask for them.
  final bool Function(T tab)? isLocked;

  /// The tabs scroll instead of shrinking: there are four or five with icon and
  /// text, and in a narrow window they would come in cut off or squeezed until
  /// unreadable. By scrolling them, the one being looked at is seen whole.
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (final tab in tabs) _Tab(
        icon: isLocked?.call(tab) == true ? Icons.lock_outline : icon(tab),
        title: title(context, tab),
        isActive: tab == active,
        action: () => onTab(tab)
      )
    ])
  );
}

/// A tab of the bar.
///
/// The active one takes the surface colour of the body and the inactive one the
/// background's. Both are opaque on purpose: [FeedbackButton] animates the
/// colour when hovering, and starting from a translucent one makes the
/// transition pass through half-alpha values —the flash already avoided in the
/// side bar options—.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.action
  });

  final IconData icon;
  final String title;
  final bool isActive;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: title,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.surface : scheme.background,
      feedbackColor: scheme.line,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSize.text * 1.2,
            color: isActive ? scheme.primary : scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(
            title,
            bold: isActive,
            multiplier: 0.95,
            color: isActive ? scheme.text.primary : scheme.text.secondary
          )
        ]
      )
    );
  }
}
