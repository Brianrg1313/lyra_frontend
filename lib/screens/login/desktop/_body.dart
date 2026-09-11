import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/sign_in/login_method.dart';
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// The login consists of two submissions on the same screen: first the email,
/// and based on the backend's response we know how to proceed. Only the
/// password is asked here; the code is completed in `/login/code` and OAuth
/// methods don't do anything yet.
class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();

  late final _email = InputController.email(
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).email_input),
      InputError.empty: S.of(context).form_empty_ma(S.of(context).email_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).email_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).email_input)
    }
  );

  late final _password = InputController.password(
    form: _form,
    obligatory: true
  );

  /// Email for which the backend already resolved the method, and the method
  /// that was resolved.
  ///
  /// The email is stored along with the method because the field can still be
  /// edited: as long as what is typed matches this, the next submission
  /// completes the method; if it changes, it asks again instead of sending the
  /// password to a different account than the one that requested it.
  String? _resolved;
  LoginMethod? _method;

  bool get _askPassword => _method == LoginMethod.password;

  @override
  void dispose() {
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
            TextLarge(S.of(context).sign_in),
            Padding(
              padding: EdgeInsets.only(
                top: AppSize.gap,
                bottom: AppSize.action
              ),
              child: TextMedium(S.of(context).sign_in_subtitle)
            ),
            Input(
              placeholder: S.of(context).email_input,
              controller: _email,
              next: _askPassword ? _password.focus : null,
              onSubmit: _askPassword ? null : _submit
            ),
            if (_askPassword)
              Input(
                autofocus: true,
                placeholder: S.of(context).password_input,
                controller: _password,
                onSubmit: _submit
              ),
            SizedBox(height: AppSize.padding),
            Button(
              title: _askPassword ? S.of(context).login : S.of(context).next,
              loading: _form.loading,
              action: _submit
            ),
            SizedBox(height: AppSize.action),
            FeedbackButton(
              color: ThemeColor.of(context).surface.withAlpha(0),
              action: () => Navis.push(context, "/sign_up"),
              feedbackColor: ThemeColor.of(context).surface,
              padding: EdgeInsets.symmetric(
                vertical: AppSize.spaceXS,
                horizontal: AppSize.spaceS
              ),
              child: TextMedium(
                S.of(context).dont_have_account,
                color: ThemeColor.of(context).primary
              )
            )
          ])
      )
    )
  );

  void _submit() {
    if (_askPassword && _email.value == _resolved) return _signIn();

    _resolve();
  }

  /// First step. Only validates the email: the password field may still be on
  /// screen from a previous email and still empty, and it's not what's being
  /// sent.
  void _resolve() {
    if (!_email.validate(_email)) return;

    _form.loading.value = true;

    final email = _email.value;

    context.read<SignInService>().resolveMethod(context, email)
      .then((method) {
        if (!mounted) return;
        _form.loading.value = false;

        // Google, Apple and Facebook make it this far but aren't implemented
        // yet: there's no screen to go to or anything else to ask, so the
        // login stays as is.
        if (method == null || !method.isAvailable) return;

        if (method == LoginMethod.code) {
          Navis.push(context, "/login/code");
          return;
        }

        setState(() {
          _method = method;
          _resolved = email;
        });
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        // The backend responds the same for an unregistered email as for
        // one without a configured method —intentionally, so registered
        // emails can't be looked up—, so the only thing that can be marked
        // is the email.
        _email.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }

  /// Second step when the method is password.
  void _signIn() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    final client = context.read<ClientService>();

    context.read<SignInService>().signInWithPassword(context, _email.value, _password.value)
      // The token is already saved, but `resolve` only runs when the app
      // starts: without this, the global instance would enter the home with no
      // client loaded and the sidebar widgets would read an empty session.
      .then((_) => client.resolve())
      .then((redirect) {
        if (!mounted) return;
        _form.loading.value = false;
        Navis.pushAndClearStack(context, redirect ?? "/home");
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        _password.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }
}
