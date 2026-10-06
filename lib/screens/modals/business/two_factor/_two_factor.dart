import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';

// WIDGETS
import './recovery_codes.dart';
import './two_factor_app.dart';
import './two_factor_email.dart';
import './two_factor_proof.dart';

export './recovery_codes.dart' show showRecoveryCodes;
export './two_factor_proof.dart' show showTwoFactorProof;

/// Turns the second factor on, or moves it to another method or a new phone: the method, then
/// its own step. With a factor in force the backend wants it proven, asked last. Answers whether
/// it changed; the service holds the new state.
Future<bool> showTwoFactorSetup(
  BuildContext context, {
  required AccountSecurityService service,
  required String email
}) async {
  final s = S.of(context);
  final current = service.twoFactor.method;

  final method = await showModal(
    context: context,
    title: s.two_factor_choose_title,
    builder: (context) => TwoFactorChoiceModal(current: current)
  );

  if (method is! TwoFactorMethod || !context.mounted) return false;

  Future<TwoFactorProof?> prove() => showTwoFactorProof(context, current!);
  final proving = current == null ? null : prove;

  if (method == TwoFactorMethod.app) {
    final codes = await showModal(
      context: context,
      title: s.two_factor_choose_app,
      builder: (context) => TwoFactorAppModal(service: service, prove: proving)
    );

    if (codes is! List<String> || !context.mounted) return false;

    FloatFlag.of(context).message(s.two_factor_turned_on);
    await showRecoveryCodes(context, codes);
    return true;
  }

  final done = await showModal(
    context: context,
    title: s.two_factor_choose_email,
    builder: (context) => TwoFactorEmailModal(service: service, email: email, prove: proving)
  );

  if (done != true || !context.mounted) return false;

  FloatFlag.of(context).message(s.two_factor_turned_on);
  return true;
}

/// The two methods, each with what it asks for. The email in force is not offered again (the
/// backend refuses it); the app is, since enrolling it again is how a new phone takes over.
class TwoFactorChoiceModal extends StatelessWidget {
  const TwoFactorChoiceModal({super.key, this.current});

  final TwoFactorMethod? current;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: TwoFactorCode.width, maxWidth: TwoFactorCode.width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(s.two_factor_choose_subtitle, lines: 2, color: ThemeColor.of(context).subtitle),
          SizedBox(height: AppSize.spaceM),
          _Option(
            icon: CI.qr_code,
            title: s.two_factor_choose_app,
            hint: s.two_factor_choose_app_hint,
            current: current == TwoFactorMethod.app,
            action: () => Navigator.pop(context, TwoFactorMethod.app)
          ),
          SizedBox(height: AppSize.spaceXS),
          _Option(
            icon: CI.mail,
            title: s.two_factor_choose_email,
            hint: s.two_factor_choose_email_hint,
            current: current == TwoFactorMethod.email,
            action: current == TwoFactorMethod.email ? null : () => Navigator.pop(context, TwoFactorMethod.email)
          )
        ]
      )
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.hint,
    required this.current,
    required this.action
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool current;

  /// `null`: shown, not chosen.
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final box = AppSize.text * 2.4;

    return FeedbackButton(
      action: action,
      message: title,
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surface,
      feedbackColor: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap, AppSize.spaceS))
          ),
          child: Center(child: Icon(icon, size: AppSize.text * 1.3, color: scheme.primary))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(title, bold: true, ellipsis: true),
            TextSmall(hint, lines: 3, ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        SizedBox(width: AppSize.gap),
        if (current)
          TextSmall(S.of(context).two_factor_choose_current, color: scheme.primary)
        else if (action != null)
          Icon(CI.arrow_right, size: AppSize.text * 1.2, color: scheme.text.secondary)
      ])
    );
  }
}
