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
class LanSignIn extends StatefulWidget {
  const LanSignIn({super.key});

  @override
  State<LanSignIn> createState() => _LanSignInState();
}

class _LanSignInState extends State<LanSignIn> {
  final _form = FormController();

  late final _login = InputController(key: "LOGIN", form: _form, obligatory: true, max: 255);
  late final _password = InputController(key: "PASSWORD", form: _form, obligatory: true, type: InputType.password, max: 1024);

  String? _error;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeploymentFrame(
    title: S.of(context).lan_sign_in_title,
    subtitle: S.of(context).lan_sign_in_subtitle,
    children: [
      Input(placeholder: S.of(context).lan_username_input, controller: _login, next: _password.focus, autofocus: true),
      Input(placeholder: S.of(context).password_input, controller: _password, onSubmit: _submit),
      if (_error != null) DeploymentNote(_error!, error: true),
      SizedBox(height: AppSize.spaceXS),
      MainButton(title: S.of(context).login, loading: _form.loading, action: _submit)
    ]
  );

  void _submit() {
    if (_form.loading.value) return;
    if (!_form.validate()) return;

    _form.loading.value = true;
    final lan = context.read<LanService>();

    lan.signIn(_login.value.trim(), _password.value).then((status) {
      if (!mounted) return;
      _form.loading.value = false;

      if (status != LanStatus.ready) {
        _password.textController.clear();
        setState(() => _error = lan.error);
      }
    });
  }
}
