import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'auth_footer.dart';
import 'auth_panel.dart';

/// The page every sign in draws on, whichever network it signs in through: [AuthPanel] on the
/// left from [panelBreakpoint], the form column on the right, [AuthFooter] at the bottom. One
/// frame, so the cloud's and a master's sign in are the same page to whoever uses them.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});

  /// The form column, at most 340 px wide, centered and scrolling in a short window.
  final Widget child;

  /// Below this width the form alone fills the window: the panel is brand, never information,
  /// so it is the first thing to give up its room.
  static const panelBreakpoint = 860.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= panelBreakpoint;

    return Skeleton.simple(
      padding: EdgeInsets.all(AppSize.spaceS),
      body: Row(children: [
        if (wide) const Expanded(flex: 5, child: AuthPanel()),
        Expanded(flex: 7, child: Padding(
          padding: EdgeInsets.all(AppSize.spaceS),
          child: Column(children: [
            Expanded(child: Center(child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 340), child: child)
            ))),
            const AuthFooter()
          ])
        ))
      ])
    );
  }
}
