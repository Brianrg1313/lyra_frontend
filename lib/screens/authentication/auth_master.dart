import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'auth_brand.dart';
import 'auth_frame.dart';

/// The sign in of a device paired with a master (or that is one), in the cloud's steps and
/// frame: the e-mail first, then what `auth.identify` answers, as `email/verify` does there.
/// `password` asks for it under the e-mail; `activation` (someone invited, S-8) asks for the code
/// the company gave them and the password they choose. The page around it leaves for `/lan` once
/// the master answers `ready`, so nothing here navigates.
///
/// The field takes a username as well: the master signs in by either, and the owner's username
/// was made from their e-mail. An unknown login answers `password` too, so a wrong one is only
/// told apart by the password's refusal, as the cloud's.
class AuthMaster extends StatefulWidget {
  const AuthMaster({super.key});

  @override
  State<AuthMaster> createState() => _AuthMasterState();
}

class _AuthMasterState extends State<AuthMaster> {
  final _form = FormController();

  late final _login = InputController(key: "LOGIN", form: _form, obligatory: true, max: 255);
  late final _password = InputController.password(form: _form, obligatory: true);
  late final _code = InputController(key: "CODE", form: _form, obligatory: true, type: InputType.numeric, min: 8, max: 8);

  /// The login `auth.identify` answered for, and whether it is still to be activated. As in the
  /// cloud's form, editing the login after it asks again instead of sending the password to an
  /// account other than the one that asked.
  String? _resolved;
  bool _activating = false;

  String? _error;

  bool get _identified => _resolved != null;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFrame(child: _fields(context));

  Widget _fields(BuildContext context) {
    final s = S.of(context);
    final activating = _identified && _activating;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBrand(),
        SizedBox(height: AppSize.spaceL * 2),
        TextInter(activating ? s.lan_activate_title : s.auth_master_title, multiplier: 2.4, bold: true, lines: 2),
        Padding(
          padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceL),
          child: TextMedium(
            activating ? s.auth_master_activate_subtitle : s.auth_master_subtitle,
            lines: 4,
            color: ThemeColor.of(context).subtitle
          )
        ),
        Input(
          autofocus: true,
          placeholder: s.email_input,
          controller: _login,
          next: _identified ? (activating ? _code.focus : _password.focus) : null,
          onSubmit: _identified ? null : _submit
        ),
        if (activating) Input(placeholder: s.lan_activate_code_input, controller: _code, next: _password.focus),
        if (_identified)
          Input(
            autofocus: !activating,
            placeholder: activating ? s.lan_activate_password_input : s.password_input,
            controller: _password,
            onSubmit: _submit
          ),
        if (_error != null)
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceXS),
            child: TextSmall(_error!, lines: 4, color: ThemeColor.of(context).accent)
          ),
        SizedBox(height: AppSize.spaceXS),
        MainButton(
          title: !_identified ? s.auth_continue : activating ? s.lan_activate_button : s.login,
          loading: _form.loading,
          action: _submit
        )
      ]
    );
  }

  /// Enter and the button both land here, and `Button` only blocks its own taps.
  void _submit() {
    if (_form.loading.value) return;

    if (_identified && _login.value.trim() == _resolved) {
      _signIn();
    } else {
      _identify();
    }
  }

  Future<void> _identify() async {
    if (!_login.validate(_login)) return;

    final login = _login.value.trim();
    setState(() => _error = null);
    _form.loading.value = true;

    final lan = context.read<LanService>();
    final activation = await lan.needsActivation(login);
    if (!mounted) return;
    _form.loading.value = false;

    if (activation == null) return setState(() => _error = lan.error);

    setState(() {
      _resolved = login;
      _activating = activation;
      _password.textController.clear();
      _code.textController.clear();
    });
  }

  /// Only the drawn fields are validated: the form holds the code's controller either way.
  Future<void> _signIn() async {
    if (!_password.validate(_password)) return;
    if (_activating && !_code.validate(_code)) return;

    // The engine's own rule (`session.md` S-2), said before the code is spent on a refusal.
    if (_activating && _password.value.length < 10) {
      return setState(() => _error = S.of(context).lan_master_weak_password);
    }

    setState(() => _error = null);
    _form.loading.value = true;

    final lan = context.read<LanService>();
    final status = _activating
      ? await lan.activate(_resolved!, _code.value.trim(), _password.value)
      : await lan.signIn(_resolved!, _password.value);

    if (!mounted) return;
    _form.loading.value = false;

    if (status != LanStatus.ready) {
      _password.textController.clear();
      setState(() => _error = lan.error);
    }
  }
}
