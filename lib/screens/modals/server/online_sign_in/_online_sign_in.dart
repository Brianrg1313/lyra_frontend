import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show clientService, hybridService;
import 'package:app/services/client/sources/session_cloud_source.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/sign_in/login_method.dart';
import 'package:app/services/sign_in/sign_in_service.dart';
import 'package:app/services/sign_up/sign_up_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Signs a session opened on the master alone in online too, once the backend answers
/// ([HybridService.canGoOnline]): the same person's cloud session, which [HybridService.join]
/// adds to the master's, so the app runs `hybrid` without leaving the page or the master's
/// session. Answers whether it did.
Future<bool> showOnlineSignIn(BuildContext context) => _open(context, OnlineSignInModal());

/// The home's own offer, which nobody asked for: the e-mail is checked first, quietly, and the
/// modal opens only to sign in (a password or a code). Without an online account it stays shut:
/// creating one is asked for from the server section ([showOnlineSignIn]), not pushed on every start.
Future<bool> offerOnlineSignIn(BuildContext context) async {
  final signIn = SignInService(source: const SessionCloudSource());

  final ({bool account, LoginMethod? method}) check;
  try {
    check = await signIn.verifyEmail(context, clientService.email, quiet: true);
  } on Object {
    return false;
  }

  final signsIn = check.account && (check.method == LoginMethod.password || check.method == LoginMethod.code);
  if (!signsIn || !context.mounted) return false;

  return _open(context, OnlineSignInModal(signIn: signIn, check: check));
}

Future<bool> _open(BuildContext context, OnlineSignInModal modal) => showModal(
  context: context,
  title: S.of(context).online_sign_in_title,
  builder: (context) => modal
).then((value) => value == true);

/// The person is the master session's: only the e-mail on it may join it, so it isn't asked.
/// `email/verify` runs on opening (pressing "sign in online" already asked for it) and says how
/// to go on: a password, or the code it just mailed — which, without an online account, is the
/// sign up's: the account is created there, named as on the master.
class OnlineSignInModal extends StatefulWidget {
  OnlineSignInModal({super.key, SignInService? signIn, this.check})
    : signIn = signIn ?? SignInService(source: const SessionCloudSource());

  /// The cloud's sign in whatever the running mode: in `local` [Sources.session] is the master's.
  final SignInService signIn;

  /// An `email/verify` already made with [signIn] ([offerOnlineSignIn]): not repeated, it would
  /// mail a second code.
  final ({bool account, LoginMethod? method})? check;

  @override
  State<OnlineSignInModal> createState() => _OnlineSignInModalState();
}

enum _Step { verifying, password, code, signUp, unsupported }

class _OnlineSignInModalState extends State<OnlineSignInModal> {
  final _form = FormController();
  late final _password = InputController.password(form: _form, obligatory: true);
  late final _code = InputController.code(
    form: _form,
    spaces: _codeLength,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).code_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).code_input)
    }
  );

  late final _firstName = _name("FIRST_NAME", S.of(context).first_name_input, clientService.client.name);
  late final _lastName = _name("LAST_NAME", S.of(context).last_name_input, clientService.client.lastName);

  SignInService get _signIn => widget.signIn;

  /// Holds the ticket between `sign_up/code` and `sign_up/names`: a retry after the names fail
  /// reuses it instead of the spent code.
  final _signUp = SignUpService();

  late final String _email = clientService.email;

  _Step _step = _Step.verifying;
  String? _error;

  static const _codeLength = 6;
  static const double _width = 400;

  @override
  void initState() {
    super.initState();
    final check = widget.check;
    if (check != null) {
      _step = _stepOf(check);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    final children = switch (_step) {
      _Step.verifying => <Widget>[
        SizedBox(height: AppSize.action * 2, child: const Center(child: Loading()))
      ],
      _Step.password => [
        TextMedium(s.online_sign_in_password(_email), lines: 4, color: scheme.subtitle),
        SizedBox(height: AppSize.spaceM),
        Input(placeholder: s.password_input, controller: _password, autofocus: true, onSubmit: _submit)
      ],
      _Step.code => [
        TextMedium(s.online_sign_in_code(_email), lines: 4, color: scheme.subtitle),
        SizedBox(height: AppSize.spaceM),
        CodeInput(spaces: _codeLength, autofocus: true, controller: _code, onEditingComplete: (_) => _submit())
      ],
      _Step.signUp => [
        TextMedium(s.online_sign_in_sign_up(_email), lines: 4, color: scheme.subtitle),
        SizedBox(height: AppSize.spaceM),
        CodeInput(spaces: _codeLength, autofocus: true, controller: _code, next: _firstName.focus),
        SizedBox(height: AppSize.spaceS),
        InputRow(
          spacing: AppSize.gap,
          children: [
            Input(flex: 1, placeholder: s.first_name_input, controller: _firstName, next: _lastName.focus),
            Input(flex: 1, placeholder: s.last_name_input, controller: _lastName, onSubmit: _submit)
          ]
        )
      ],
      _Step.unsupported => [TextMedium(s.online_sign_in_unsupported, lines: 4, color: scheme.subtitle)]
    };
    final asks = _step == _Step.password || _step == _Step.code || _step == _Step.signUp;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(top: AppSize.gap),
              child: TextSmall(_error!, lines: 4, color: scheme.accent)
            ),
          SizedBox(height: AppSize.spaceS),
          if (asks) ...[
            MainButton(
              title: _step == _Step.signUp ? s.online_sign_in_create : s.online_sign_in_button,
              loading: _form.loading,
              action: _submit
            ),
            SizedBox(height: AppSize.spaceXS)
          ],
          Button(
            title: asks || _step == _Step.verifying ? s.online_sign_in_later : s.online_sign_in_close,
            action: () => Navigator.pop(context, false)
          )
        ]
      )
    );
  }

  Future<void> _verify() async {
    try {
      final check = await _signIn.verifyEmail(context, _email);
      if (!mounted) return;

      setState(() => _step = _stepOf(check));
    } on Object {
      // The refusal was already shown: nothing here can go on.
      if (mounted) Navigator.pop(context, false);
    }
  }

  static _Step _stepOf(({bool account, LoginMethod? method}) check) =>
    !check.account ? _Step.signUp : switch (check.method) {
      LoginMethod.password => _Step.password,
      LoginMethod.code => _Step.code,
      _ => _Step.unsupported
    };

  InputController _name(String key, String label, String initial) => InputController(
    key: key,
    form: _form,
    obligatory: true,
    max: 64,
    initial: initial,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(label),
      InputError.empty: S.of(context).form_empty_ma(label)
    }
  );

  Future<void> _submit() async {
    if (_form.loading.value || !_form.validate()) return;

    setState(() => _error = null);
    _form.loading.value = true;

    final password = _step == _Step.password ? _password.value : null;

    try {
      if (password != null) {
        await _signIn.signInWithPassword(context, _email, password);
      } else if (_step == _Step.signUp) {
        await _signUp.signUp(context,
          email: _email,
          code: _code.value.trim(),
          firstName: _firstName.value.trim(),
          lastName: _lastName.value.trim()
        );
        await _signIn.clearPending();
      } else {
        await _signIn.signInWithCode(context, _code.value.trim());
      }
    } on Object {
      if (!mounted) return;
      _form.loading.value = false;
      // Once sign up holds a ticket the code was accepted: the failure is the names', already shown.
      if (_step == _Step.signUp && _signUp.hasTicket) return;
      (password != null ? _password : _code).status.setStatus(InputStatus.error, InputError.invalid);
      return;
    }

    final joined = await hybridService.join(_email, password: password);
    if (!mounted) return;
    _form.loading.value = false;

    if (joined != HybridJoin.joined) return setState(() => _error = S.of(context).online_sign_in_failed);

    // The home opened the socket while it was `local`, where there is none to open.
    unawaited(ConnectionService().open());
    FloatFlag.of(context).message(S.of(context).online_sign_in_done);
    Navigator.pop(context, true);
  }
}
