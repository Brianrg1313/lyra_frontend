import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/lan/network_scan_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/sign_in/login_method.dart';
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/images.dart';
import 'package:core/button.dart';
import '../auth_brand.dart';
import '../auth_frame.dart';
import '../auth_hybrid.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// Only the email is asked first; `email/verify` answers whether it has an
/// account and how it continues. A code (sign in or sign up) is completed on
/// the code page; the password is still asked here until it gets its own page.
/// The OAuth buttons do nothing yet.
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

  /// Email for which the backend already answered `method: "password"`.
  ///
  /// The field can still be edited: as long as what is typed matches this,
  /// the next submission signs in; if it changes, it verifies again instead of
  /// sending the password to a different account than the one that asked.
  String? _resolved;

  bool get _askPassword => _resolved != null;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFrame(child: _fields(context));

  /// Left-aligned like the rest of the app's forms; the headline carries the
  /// weight, so the subtitle stays in the subtitle color.
  Widget _fields(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AuthBrand(),
      SizedBox(height: AppSize.spaceL * 2),
      TextInter(S.of(context).auth_title, multiplier: 2.4, bold: true, lines: 2),
      Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceL),
        child: TextMedium(
          S.of(context).auth_subtitle,
          lines: 3,
          color: ThemeColor.of(context).subtitle
        )
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
      SizedBox(height: AppSize.spaceXS),
      MainButton(
        title: _askPassword ? S.of(context).login : S.of(context).auth_continue,
        loading: _form.loading,
        action: _submit
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
        child: Row(children: [
          TextSmall(S.of(context).auth_or_with, color: ThemeColor.of(context).subtitle),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Separator.horizontal(
            thickness: 1,
            color: ThemeColor.of(context).surfaceFeedback
          ))
        ])
      ),
      Row(children: [
        Expanded(child: _provider(context, "google.webp", AppSize.spaceXS)),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: _provider(context, "facebook.webp", AppSize.spaceXS - 2)),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: _provider(context, "apple.webp", AppSize.spaceXS))
      ]),
      Padding(
        padding: EdgeInsets.only(top: AppSize.spaceL),
        child: Wrap(children: [
          TextSmall(S.of(context).auth_terms_prefix, color: ThemeColor.of(context).subtitle),
          // TODO: link to the actual terms and conditions page
          GestureDetector(
            child: TextSmall(
              S.of(context).sign_up_terms_link,
              color: ThemeColor.of(context).primary
            )
          )
        ])
      )
    ]
  );

  /// [inset] evens out the logos: the Facebook one has less air in its asset.
  Widget _provider(BuildContext context, String logo, double inset) => Surface.line(
    height: AppSize.action,
    thickness: 1,
    padding: EdgeInsets.all(inset),
    borderColor: ThemeColor.of(context).surfaceFeedback,
    child: Center(child: ImageDynamic(logo))
  );

  /// Reached from both Enter and the button, and `Button` only blocks its own
  /// taps: without the guard a second submit while the first is in flight
  /// asks the backend for a second code, which invalidates the one already
  /// sent and spends one of the hourly requests.
  void _submit() {
    if (_form.loading.value) return;
    if (_askPassword && _email.value == _resolved) return _signIn();

    _verify();
  }

  /// First step. Only validates the email: the password field may still be on
  /// screen from a previous email and still empty, and it's not what's being
  /// sent.
  void _verify() {
    if (!_email.validate(_email)) return;

    _form.loading.value = true;
    _holdScan();

    final email = _email.value;

    context.read<SignInService>().verifyEmail(context, email)
      .whenComplete(_releaseScan)
      .then((check) {
        if (!mounted) return;
        _form.loading.value = false;

        // Without an account the code is already sent and the sign up
        // (names + code) goes on the code page.
        if (!check.account) {
          Navis.push(context, "/login/code");
          return;
        }

        // Google, Apple and Facebook are reserved by the backend but not
        // implemented: there's no screen to go to, so the page stays as is.
        switch (check.method) {
          case LoginMethod.code: Navis.push(context, "/login/code");
          case LoginMethod.password: setState(() => _resolved = email);
          default: return;
        }
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;
      });
  }

  /// Second step when the method is password.
  void _signIn() {
    if (!_form.validate()) return;

    _form.loading.value = true;
    _holdScan();

    final client = context.read<ClientService>();

    final email = _email.value.trim();
    final password = _password.value;

    context.read<SignInService>().signInWithPassword(context, _email.value, password)
      // On a device with a master, its session too, with the same password.
      .then((_) => mounted ? joinMaster(context, email, password: password) : null)
      // The token is already saved, but `resolve` only runs when the app
      // starts: without this, the global instance would enter the home with no
      // client loaded and the sidebar widgets would read an empty session.
      .then((_) => client.resolve())
      .whenComplete(_releaseScan)
      .then((redirect) {
        if (!mounted) return;
        _form.loading.value = false;
        Navis.pushAndClearStack(context, redirect ?? PreferencesService().homePath);
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        _password.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }

  /// The sign in's look of the network, held while the backend answers: the internet going away
  /// mid-request would swap this form for the offline one with the request half answered.
  late final _scan = context.read<NetworkScanService>();
  void _holdScan() => _scan.hold(true);
  void _releaseScan() => _scan.hold(false);
}
