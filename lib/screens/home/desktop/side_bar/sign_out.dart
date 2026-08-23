import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

class SignOut extends StatelessWidget {
  const SignOut({
    required this.isExpanded,
    required this.toggle,
    super.key
  });

  final bool isExpanded;
  final void Function() toggle;
  
  final _co = const Color(0x00000000);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSize.spaceXS, 0,
      AppSize.spaceXS, AppSize.spaceXS
    ),
    child: LayoutBuilder(builder: (context, constraints) =>
      constraints.maxWidth >= AppSize.action * 2
        ? _expanded(context)
        : _collapsed(context)
    )
  );

  Widget _expanded(BuildContext context) => Surface.line(
    height: AppSize.action,
    child: Row(children: [
      Expanded(child: FeedbackButton(
        action: _signOut,
        height: AppSize.action,
        message: S.of(context).sign_out,
        color: _co,
        feedbackColor: _co,
        child: Center(child: TextMedium(
          S.of(context).sign_out,
          ellipsis: true,
          color: ThemeColor.of(context).snackBar.error
        ))
      )),
      Separator.vertical(size: AppSize.action),
      FeedbackButton(
        action: toggle,
        width: AppSize.action,
        height: AppSize.action,
        color: _co,
        message: S.of(context).collapse,
        feedbackColor: _co,
        child: Center(child: _arrow)
      )
    ])
  );

  Widget _collapsed(BuildContext context) => Surface.line(
    width: AppSize.action,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FeedbackButton(
          color: _co,
          action: toggle,
          feedbackColor: _co,
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).expand,
          child: Center(child: _arrow)
        ),
        Separator.horizontal(size: AppSize.action),
        FeedbackButton(
          color: _co,
          action: _signOut,
          feedbackColor: _co,
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).sign_out,
          child: Center(child: Icon(
            CI.log_out,
            color: ThemeColor.of(context).snackBar.error
          ))
        )
      ]));

  Widget get _arrow => AnimatedRotation(
    turns: isExpanded ? 0.5 : 0,
    duration: const Duration(milliseconds: 200),
    child: const Icon(CI.arrow_right)
  );

  void _signOut() {
    // TODO: sign out
  }
}
