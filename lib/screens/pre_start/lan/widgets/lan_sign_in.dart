import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';

/// Sign in to the master with a local account (`session.md`, `auth.signIn`). A wrong
/// password and an unknown user get the same answer, on purpose.
///
/// Someone invited signs in the first time with the activation code the company gave them and
/// the password they choose (`auth.activate`, S-8): the same page, switched to [_activating].
class LanSignIn extends StatefulWidget {
  const LanSignIn({super.key});

  @override
  State<LanSignIn> createState() => _LanSignInState();
}

class _LanSignInState extends State<LanSignIn> {
  final _form = FormController();

  late final _login = InputController(key: "LOGIN", form: _form, obligatory: true, max: 255);
  late final _password = InputController(key: "PASSWORD", form: _form, obligatory: true, type: InputType.password, max: 1024);
  late final _code = InputController(key: "CODE", form: _form, obligatory: true, type: InputType.numeric, min: 8, max: 8);

  bool _activating = false;

  String? _error;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    return DeploymentFrame(
      title: _activating ? text.lan_activate_title : text.lan_sign_in_title,
      subtitle: _activating ? text.lan_activate_subtitle : text.lan_sign_in_subtitle,
      children: [
        Input(
          placeholder: text.lan_username_input,
          controller: _login,
          next: _activating ? _code.focus : _password.focus,
          autofocus: true
        ),
        if (_activating) Input(placeholder: text.lan_activate_code_input, controller: _code, next: _password.focus),
        Input(
          placeholder: _activating ? text.lan_activate_password_input : text.password_input,
          controller: _password,
          onSubmit: _submit
        ),
        if (_error != null) DeploymentNote(_error!, error: true),
        SizedBox(height: AppSize.spaceXS),
        MainButton(
          title: _activating ? text.lan_activate_button : text.login,
          loading: _form.loading,
          action: _submit
        ),
        SizedBox(height: AppSize.spaceXS),
        Button(
          title: _activating ? text.lan_activate_back : text.lan_activate_link,
          action: _switch
        )
      ]
    );
  }

  /// The code field only counts while it is drawn: the form validates every controller.
  void _switch() => setState(() {
    _activating = !_activating;
    _error = null;
    _password.textController.clear();
    _code.textController.clear();
  });

  void _submit() {
    if (_form.loading.value) return;
    if (!_login.validate(_login) || !_password.validate(_password)) return;
    if (_activating && !_code.validate(_code)) return;

    // The engine's own rule (`session.md` S-2), said before the code is spent on a refusal.
    if (_activating && _password.value.length < 10) {
      return setState(() => _error = S.of(context).lan_master_weak_password);
    }

    _form.loading.value = true;
    final lan = context.read<LanService>();
    final login = _login.value.trim();
    final request = _activating
      ? lan.activate(login, _code.value.trim(), _password.value)
      : lan.signIn(login, _password.value);

    request.then((status) {
      if (!mounted) return;
      _form.loading.value = false;

      if (status != LanStatus.ready) {
        _password.textController.clear();
        setState(() => _error = lan.error);
      }
    });
  }
}
