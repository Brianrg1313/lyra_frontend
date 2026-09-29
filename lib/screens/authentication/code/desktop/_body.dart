import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/sign_in/sign_in_service.dart';
import 'package:app/services/sign_up/sign_up_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import '../../auth_brand.dart';
import '../../auth_footer.dart';
import '../../auth_panel.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// The same frame as the auth entry (panel, form column, footer), so the code
/// reads as the next step of that page and not as a new one.
///
/// With an account only the code is asked and it submits on its own. Without
/// one the backend wants the names on this same screen, so they are asked
/// below the code and nothing submits until a button is pressed.
class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();
  final _resendLoading = ValueNotifier<bool>(false);
  final _continueLoading = ValueNotifier<bool>(false);
  final _passwordLoading = ValueNotifier<bool>(false);

  static const _codeLength = 6;

  static const _resendCooldown = 60;

  Timer? _timer;
  int _secondsLeft = _resendCooldown;

  /// Shown in the subtitle so the person knows which inbox to check.
  String? _email;

  /// `null` until the pending state is read: until then the page cannot tell
  /// whether the names belong on it.
  bool? _account;

  @override
  void initState() {
    super.initState();
    _startTimer();

    context.read<SignInService>().pending().then((pending) {
      if (!mounted) return;

      // Opened without going through the auth page (e.g. a reload): there is
      // no email for the code to belong to.
      if (pending.email == null) return Navis.push(context, "/login");

      setState(() {
        _email = pending.email;
        _account = pending.account;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendLoading.dispose();
    _continueLoading.dispose();
    _passwordLoading.dispose();
    _form.dispose();
    super.dispose();
  }

  /// Same breakpoint as the auth entry, so the panel does not jump between
  /// the two pages.
  static const _panelBreakpoint = 860.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _panelBreakpoint;

    return Skeleton.simple(
      padding: EdgeInsets.all(AppSize.spaceS),
      body: Row(children: [
        if (wide) const Expanded(flex: 5, child: AuthPanel(drop: false)),
        Expanded(flex: 7, child: Padding(
          padding: EdgeInsets.all(AppSize.spaceS),
          child: Column(children: [
            Expanded(child: Center(child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
              // Wide enough for the names side by side in sign up.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: switch (_account) {
                  null => Loading(color: ThemeColor.of(context).primary),
                  true => _signIn(),
                  false => _signUp()
                }
              )
            ))),
            const AuthFooter()
          ])
        ))
      ])
    );
  }

  /// Registered once in `_form`: the factory hands back the same instance on
  /// every rebuild.
  InputController get _code => InputController.code(
    form: _form,
    spaces: _codeLength,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).code_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).code_input)
    }
  );

  /// With an account only the code is asked, and a full one submits: there
  /// is no button, so the line under the code says what is happening.
  Widget _signIn() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AuthBrand(),
      SizedBox(height: AppSize.spaceL * 2),
      TextInter(S.of(context).verify_code_inbox_title, multiplier: 2.4, bold: true, lines: 2),
      Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceS),
        child: TextMedium(
          S.of(context).verify_code_inbox_subtitle(_codeLength),
          lines: 2,
          color: ThemeColor.of(context).subtitle
        )
      ),
      _SentTo(email: _email!),
      SizedBox(height: AppSize.spaceM),
      CodeInput(
        spaces: _codeLength,
        autofocus: true,
        onEditingComplete: (_) => _submit(_continueLoading),
        controller: _code
      ),
      SizedBox(height: AppSize.spaceXS),
      _signInStatus()
    ]
  );

  /// One line under the code: the resend countdown, then the resend link, or
  /// "signing you in" while the code is being checked.
  Widget _signInStatus() {
    final scheme = ThemeColor.of(context);
    final spinner = SizedBox.square(
      dimension: AppSize.text,
      child: Loading(color: scheme.primary)
    );

    return SizedBox(
      height: AppSize.button,
      child: ValueListenableBuilder<bool>(
        valueListenable: _continueLoading,
        builder: (context, submitting, _) => ValueListenableBuilder<bool>(
          valueListenable: _resendLoading,
          builder: (context, resending, _) => Row(children: submitting
            ? [
                spinner,
                SizedBox(width: AppSize.gap),
                TextSmall(S.of(context).verify_code_signing_in, color: scheme.subtitle)
              ]
            : [
                TextSmall(S.of(context).verify_code_not_received, color: scheme.subtitle),
                SizedBox(width: AppSize.gap),
                if (_secondsLeft > 0)
                  TextSmall(
                    S.of(context).verify_code_resend_in(_formattedTime),
                    color: scheme.subtitle
                  )
                else if (resending)
                  spinner
                else
                  FeedbackButton(
                    color: scheme.surface.withAlpha(0),
                    feedbackColor: scheme.surface,
                    action: _resend,
                    padding: EdgeInsets.all(AppSize.gap),
                    child: TextMedium(
                      S.of(context).resend_code,
                      multiplier: 0.9,
                      bold: true,
                      color: scheme.primary
                    )
                  )
              ]
          )
        )
      )
    );
  }

  /// Without an account this step makes the account, so it reads as that: the
  /// two things it still needs, in the order the backend takes them
  /// (`sign_up/code`, then `sign_up/names`).
  Widget _signUp() {
    final code = _code;
    final firstName = _name("FIRST_NAME", S.of(context).first_name_input);
    final lastName = _name("LAST_NAME", S.of(context).last_name_input);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextInter(S.of(context).sign_up_code_title, multiplier: 2.4, bold: true),
        SizedBox(height: AppSize.gap),
        TextMedium(
          S.of(context).sign_up_code_subtitle(_email!),
          lines: 3,
          color: ThemeColor.of(context).subtitle
        ),
        SizedBox(height: AppSize.spaceL),
        _Step(
          number: 1,
          title: S.of(context).sign_up_step_code,
          hint: S.of(context).sign_up_step_code_hint,
          listenables: [code.textController],
          isDone: () => code.text.length == _codeLength,
          // A pasted code must not submit: the names may still be empty and
          // the person picks whether to create a password first.
          child: CodeInput(
            spaces: _codeLength,
            autofocus: true,
            next: firstName.focus,
            controller: code
          )
        ),
        SizedBox(height: AppSize.spaceM),
        _Step(
          number: 2,
          title: S.of(context).sign_up_step_name,
          hint: S.of(context).sign_up_step_name_hint,
          listenables: [firstName.textController, lastName.textController],
          isDone: () => firstName.text.trim().isNotEmpty && lastName.text.trim().isNotEmpty,
          child: InputRow(
            spacing: AppSize.gap,
            children: [
              Input(
                flex: 1,
                placeholder: S.of(context).first_name_input,
                controller: firstName,
                next: lastName.focus
              ),
              Input(
                flex: 1,
                placeholder: S.of(context).last_name_input,
                controller: lastName
              )
            ]
          )
        ),
        _signUpActions(code),
        SizedBox(height: AppSize.spaceL),
        ..._leave()
      ]
    );
  }

  /// The ways out of the sign-up step: resend (after the cooldown) and back
  /// to the email. Centered by their own `Align`, since the column is
  /// left-aligned.
  List<Widget> _leave() => [
    Align(
      child: _secondsLeft > 0
        ? TextMedium(
            S.of(context).resend_code_timer(_formattedTime),
            color: ThemeColor.of(context).subtitle
          )
        // Keeps the box of the `Button` it replaced (full width,
        // `AppSize.button` tall); the label swaps for a spinner while sending.
        : ValueListenableBuilder<bool>(
            valueListenable: _resendLoading,
            builder: (context, loading, _) => FeedbackButton(
              width: double.infinity,
              height: AppSize.button,
              color: ThemeColor.of(context).surface,
              feedbackColor: ThemeColor.of(context).surfaceOver,
              action: loading ? null : _resend,
              padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
              child: Center(
                child: loading
                  ? Loading(color: ThemeColor.of(context).primary)
                  : TextMedium(
                      S.of(context).resend_code,
                      bold: true,
                      textAlign: TextAlign.center,
                      color: ThemeColor.of(context).primary
                    )
              )
            )
          )
    ),
    SizedBox(height: AppSize.gap),
    Align(
      child: FeedbackButton(
        color: ThemeColor.of(context).surface.withAlpha(0),
        feedbackColor: ThemeColor.of(context).surface,
        action: () => Navis.push(context, "/login"),
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
    )
  ];

  /// Limits from `sign_up/names`: 1–64 characters.
  InputController _name(String key, String label) => InputController(
    key: key,
    form: _form,
    obligatory: true,
    max: 64,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(label),
      InputError.empty: S.of(context).form_empty_ma(label)
    }
  );

  /// The password notice only makes sense next to the choice it explains, so
  /// it is revealed together with the buttons once the code is full.
  Widget _signUpActions(InputController code) => ListenableBuilder(
    listenable: code.textController,
    builder: (context, _) => AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: code.text.length < _codeLength
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: EdgeInsets.only(top: AppSize.spaceM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextSmall(
                  S.of(context).verify_code_password_notice,
                  lines: 4,
                  color: ThemeColor.of(context).subtitle
                ),
                SizedBox(height: AppSize.spaceM),
                MainButton(
                  title: S.of(context).verify_code_continue,
                  loading: _continueLoading,
                  action: () => _submit(_continueLoading)
                ),
                SizedBox(height: AppSize.padding),
                // `FeedbackButton` has no `loading`: the label swaps for a
                // spinner while this path is submitting.
                ValueListenableBuilder<bool>(
                  valueListenable: _passwordLoading,
                  // Same box as `MainButton` (full width, `AppSize.action`
                  // tall, `AppSize.corner` radius) so both read as a pair.
                  builder: (context, loading, _) => FeedbackButton(
                    width: double.infinity,
                    height: AppSize.action,
                    color: ThemeColor.of(context).surface,
                    feedbackColor: ThemeColor.of(context).surfaceOver,
                    action: loading
                      ? null
                      : () => _submit(_passwordLoading, createPassword: true),
                    padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
                    child: Center(
                      child: loading
                        ? Loading(color: ThemeColor.of(context).primary)
                        : TextMedium(
                            S.of(context).verify_code_continue_with_password,
                            bold: true,
                            textAlign: TextAlign.center,
                            color: ThemeColor.of(context).primary
                          )
                    )
                  )
                )
              ]
            )
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

  /// [loading] is the spinner of the button that was pressed; `_form.loading`
  /// also goes up so the inputs lock and nothing fires twice. `CodeInput`
  /// fires every time the boxes fill up, not once: a repeated submit while the
  /// first is in flight reaches the backend with a code the first one already
  /// consumed and answers 401 (`invalid_code`).
  ///
  /// [createPassword] has no screen to land on yet (`sign_up/password` has no
  /// page), so for now both sign-up paths finish the same way.
  void _submit(ValueNotifier<bool> loading, {bool createPassword = false}) {
    if (_form.loading.value) return;
    if (!_form.validate()) return;

    _form.loading.value = true;
    loading.value = true;

    final client = context.read<ClientService>();
    final signIn = context.read<SignInService>();
    final signUp = context.read<SignUpService>();
    final data = _form.data;

    final Future<void> request = _account!
      ? signIn.signInWithCode(context, data["CODE"] as String)
      : signUp.signUp(context,
          email: _email!,
          code: data["CODE"] as String,
          firstName: data["FIRST_NAME"] as String,
          lastName: data["LAST_NAME"] as String
        ).then((_) => signIn.clearPending());

    request
      // The token is already saved, but `resolve` only runs when the app
      // starts: without this, the global instance would enter the home with no
      // client loaded and the sidebar widgets would read an empty session.
      .then((_) => client.resolve())
      .then((redirect) {
        if (!mounted) return;
        _form.loading.value = false;
        loading.value = false;
        Navis.pushAndClearStack(context, redirect ?? PreferencesService().homePath);
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;
        loading.value = false;

        // Once sign up holds a ticket the code was accepted: the failure is
        // the names' step and its message is already on screen.
        if (!_account! && signUp.hasTicket) return;

        _form.inputs["CODE"]?.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }

  void _resend() {
    _resendLoading.value = true;

    context.read<SignInService>().resendCode(context)
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

/// One of the two things the sign-up step needs. The number is the order the
/// backend takes them in and turns into a check once [isDone] holds, so the
/// marker says what is still missing rather than decorating.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.hint,
    required this.listenables,
    required this.isDone,
    required this.child
  });

  final int number;
  final String title;
  final String hint;

  /// What [isDone] reads, so only the marker rebuilds while typing.
  final List<Listenable> listenables;
  final bool Function() isDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final marker = AppSize.button * 0.75;

    // The marker labels the step, not the input: the input runs under it at
    // full width, flush with the title above.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          ListenableBuilder(
            listenable: Listenable.merge(listenables),
            builder: (context, _) {
              final complete = isDone();

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: marker,
                height: marker,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: complete ? scheme.primary : scheme.primary.withAlpha(0),
                  border: Border.all(color: scheme.primary, width: 1.5)
                ),
                child: complete
                  ? Icon(CI.check, size: marker * 0.55, color: scheme.background)
                  : TextMedium("$number", multiplier: 0.9, bold: true, color: scheme.primary)
              );
            }
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(title, bold: true),
              TextSmall(hint, color: scheme.subtitle)
            ]
          ))
        ]),
        SizedBox(height: AppSize.spaceXS),
        child
      ]
    );
  }
}

/// The address the code went to, so the person knows which inbox to open.
/// Changing it is the way back to the email step, which is why "Change" sits
/// inside it instead of a separate back button.
class _SentTo extends StatelessWidget {
  const _SentTo({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.line(
      height: AppSize.action,
      thickness: 1,
      borderColor: scheme.surfaceFeedback,
      padding: EdgeInsets.only(left: AppSize.spaceS, right: AppSize.gap),
      child: Row(children: [
        Icon(CI.mail, size: AppSize.text * 1.3, color: scheme.primary),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: TextMedium(email, bold: true, lines: 1)),
        SizedBox(width: AppSize.gap),
        FeedbackButton(
          color: scheme.surface.withAlpha(0),
          feedbackColor: scheme.surface,
          action: () => Navis.push(context, "/login"),
          padding: EdgeInsets.symmetric(
            vertical: AppSize.gap,
            horizontal: AppSize.spaceXS
          ),
          child: TextMedium(
            S.of(context).verify_code_change_email,
            multiplier: 0.9,
            color: scheme.primary
          )
        )
      ])
    );
  }
}
