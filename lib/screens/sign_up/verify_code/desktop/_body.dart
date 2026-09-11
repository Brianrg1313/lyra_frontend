import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_up/sign_up_service.dart';
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();
  final _resendLoading = ValueNotifier<bool>(false);

  static const _resendCooldown = 60;

  Timer? _timer;
  int _secondsLeft = _resendCooldown;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendLoading.dispose();
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextLarge(S.of(context).verify_code_title),
            Padding(
              padding: EdgeInsets.only(
                top: AppSize.gap,
                bottom: AppSize.action
              ),
              child: TextMedium(S.of(context).verify_code_subtitle)
            ),
            CodeInput(
              spaces: 6,
              autofocus: true,
              onEditingComplete: (_) => _submit(),
              controller: InputController.code(
                form: _form,
                spaces: 6,
                customErrors: {
                  InputError.empty: S.of(context).form_empty_ma(S.of(context).code_input),
                  InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).code_input)
                }
              )
            ),
            SizedBox(height: AppSize.action),
            _secondsLeft > 0
              ? TextMedium(
                  S.of(context).resend_code_timer(_formattedTime),
                  color: ThemeColor.of(context).subtitle
                )
              : Button(
                  title: S.of(context).resend_code,
                  loading: _resendLoading,
                  action: _resend
                ),
            SizedBox(height: AppSize.gap),
            FeedbackButton(
              color: ThemeColor.of(context).surface.withAlpha(0),
              feedbackColor: ThemeColor.of(context).surface,
              action: () => Navis.push(context, "/sign_up"),
              padding: EdgeInsets.symmetric(
                vertical: AppSize.spaceXS,
                horizontal: AppSize.spaceS
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CI.arrow_left, size: 18, color: ThemeColor.of(context).primary),
                  SizedBox(width: AppSize.gap),
                  TextMedium(S.of(context).back, color: ThemeColor.of(context).primary)
                ]
              )
            )
          ])
      )
    )
  );

  String get _formattedTime {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }

      setState(() => _secondsLeft--);
    });
  }

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    final client = context.read<ClientService>();

    context.read<SignUpService>().verifyCode(context, _form.data)
      // The token is already stored, but `resolve` only runs when the app
      // starts: without this, the global instance would enter the home screen
      // without a loaded client and the sidebar widgets would read an empty session.
      .then((_) => client.resolve())
      .then((redirect) {
        if (!mounted) return;
        _form.loading.value = false;
        Navis.pushAndClearStack(context, redirect ?? "/home");
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        _form.inputs["CODE"]?.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }

  void _resend() {
    _resendLoading.value = true;

    context.read<SignUpService>().resendCode(context)
      .then((_) {
        if (!mounted) return;
        _resendLoading.value = false;
        _startTimer();
      })
      .catchError((E) {
        if (!mounted) return;
        _resendLoading.value = false;
      });
  }
}
