import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/client_task.dart';
import 'package:app/services/preferences/preferences_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/authentication/auth_brand.dart';
import 'package:app/screens/authentication/auth_footer.dart';
import 'package:app/screens/authentication/auth_panel.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// The sign in's frame (panel, form column, footer): it is that flow's last step. The code
/// submits once full, like the sign in's; an app's account may use a recovery code instead, an
/// email's may ask for a new code (the sign in mailed the first).
class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();
  final _recoveryForm = FormController();
  final _sending = ValueNotifier<bool>(false);

  static const _codeLength = 6;

  /// Same breakpoint as the sign in, so the panel does not jump between the steps.
  static const _panelBreakpoint = 860.0;

  late final _code = InputController.code(form: _form, spaces: _codeLength);
  late final _recovery = InputController(key: "RECOVERY_CODE", form: _recoveryForm, obligatory: true, max: 20);

  TwoFactorMethod? _method;
  bool _useRecovery = false;

  @override
  void initState() {
    super.initState();

    final task = context.read<ClientService>().tasks
      .where((task) => task.key == ClientTaskKey.twoFactor)
      .firstOrNull;

    // Reached without the task (a reload after it passed): the start decides again.
    if (task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navis.pushAndClearStack(context, "/");
      });
      return;
    }

    _method = TwoFactorMethod.from(task.method) ?? TwoFactorMethod.app;
  }

  @override
  void dispose() {
    _form.dispose();
    _recoveryForm.dispose();
    _sending.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _panelBreakpoint;
    final scheme = ThemeColor.of(context);

    return Skeleton.simple(
      padding: EdgeInsets.all(AppSize.spaceS),
      body: Row(children: [
        if (wide) const Expanded(flex: 5, child: AuthPanel(drop: false)),
        Expanded(flex: 7, child: Padding(
          padding: EdgeInsets.all(AppSize.spaceS),
          child: Column(children: [
            Expanded(child: Center(child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: _method == null ? Loading(color: scheme.primary) : _check(context)
              )
            ))),
            const AuthFooter()
          ])
        ))
      ])
    );
  }

  Widget _check(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final email = _method == TwoFactorMethod.email;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBrand(),
        SizedBox(height: AppSize.spaceL * 2),
        TextInter(s.two_factor_check_title, multiplier: 2.4, bold: true, lines: 2),
        Padding(
          padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceM),
          child: TextMedium(
            _useRecovery ? s.two_factor_check_recovery : email ? s.two_factor_check_email : s.two_factor_check_app,
            lines: 3,
            color: scheme.subtitle
          )
        ),
        if (_useRecovery)
          Input(
            placeholder: s.two_factor_recovery_input,
            controller: _recovery,
            autofocus: true,
            onSubmit: _submit
          )
        else
          CodeInput(
            controller: _code,
            spaces: _codeLength,
            autofocus: true,
            onEditingComplete: (_) => _submit()
          ),
        SizedBox(height: AppSize.spaceXS),
        SizedBox(
          height: AppSize.button,
          child: ValueListenableBuilder<bool>(
            valueListenable: _form.loading,
            builder: (context, checking, _) => Row(children: checking
              ? [
                  SizedBox.square(dimension: AppSize.text, child: Loading(color: scheme.primary)),
                  SizedBox(width: AppSize.gap),
                  TextSmall(s.two_factor_check_verifying, color: scheme.subtitle)
                ]
              : [
                  if (email)
                    ValueListenableBuilder<bool>(
                      valueListenable: _sending,
                      builder: (context, sending, _) => sending
                        ? SizedBox.square(dimension: AppSize.text, child: Loading(color: scheme.primary))
                        : _link(s.two_factor_resend, _resend)
                    )
                  else
                    _link(
                      _useRecovery ? s.two_factor_use_code : s.two_factor_use_recovery,
                      () => setState(() => _useRecovery = !_useRecovery)
                    )
                ]
            )
          )
        ),
        SizedBox(height: AppSize.spaceL),
        _link(s.sign_out, () => context.read<ClientService>().signOut(context))
      ]
    );
  }

  Widget _link(String label, void Function() action) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      color: scheme.surface.withAlpha(0),
      feedbackColor: scheme.surface,
      action: action,
      padding: EdgeInsets.all(AppSize.gap),
      child: TextMedium(label, multiplier: 0.9, bold: true, color: scheme.primary)
    );
  }

  Future<void> _resend() async {
    if (_sending.value) return;
    _sending.value = true;

    try {
      await AccountSecurityService.sendCode();
      if (mounted) FloatFlag.of(context).message(S.of(context).two_factor_check_sent);
    } catch (error) {
      FloatFlag.showFromError(error);
    }

    if (mounted) _sending.value = false;
  }

  /// `_form.loading` guards it: a full code fires more than once, and a second check of an
  /// email code the first one spent would answer "invalid".
  Future<void> _submit() async {
    if (_form.loading.value) return;

    final TwoFactorProof proof;
    if (_useRecovery) {
      if (!_recoveryForm.validate()) return;
      proof = TwoFactorProof.recovery(_recovery.text.trim());
    } else {
      if (!_form.validate()) return;
      proof = TwoFactorProof.code(_code.text);
    }

    _form.loading.value = true;
    final client = context.read<ClientService>();

    try {
      await AccountSecurityService.verify(proof);
      // The session is whole now: `/init` answers the profile and the companies it held back.
      final redirect = await client.resolve();
      if (!mounted) return;

      Navis.pushAndClearStack(context, redirect ?? PreferencesService().homePath);
    } catch (error) {
      FloatFlag.showFromError(error);
      if (!mounted) return;

      _form.loading.value = false;
      _code.textController.clear();
      _recovery.textController.clear();
    }
  }
}
