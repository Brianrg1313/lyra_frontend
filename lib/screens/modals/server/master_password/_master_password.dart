import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show hybridService, lanService;

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Asks, once, for [login]'s password on this device's master, after an online sign in that
/// couldn't open the master's session by itself (a code, or a master password other than the
/// cloud's): with it the session outlives the internet (plan §9.6, D14). Answers whether the
/// master took it; "not now" goes on online only.
Future<bool> showMasterPassword(BuildContext context, {required String login}) => showModal(
  context: context,
  title: S.of(context).hybrid_password_title,
  builder: (context) => MasterPasswordModal(login: login)
).then((value) => value == true);

class MasterPasswordModal extends StatefulWidget {
  const MasterPasswordModal({super.key, required this.login});

  final String login;

  @override
  State<MasterPasswordModal> createState() => _MasterPasswordModalState();
}

class _MasterPasswordModalState extends State<MasterPasswordModal> {
  final _form = FormController();
  late final _password = InputController.password(form: _form, obligatory: true);

  String? _error;

  static const double _width = 400;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(s.hybrid_password_subtitle, lines: 4, color: ThemeColor.of(context).subtitle),
          SizedBox(height: AppSize.spaceM),
          Input(placeholder: s.password_input, controller: _password, autofocus: true, onSubmit: _submit),
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.spaceXS),
              child: TextSmall(_error!, lines: 4, color: ThemeColor.of(context).accent)
            ),
          SizedBox(height: AppSize.spaceXS),
          MainButton(title: s.hybrid_password_button, loading: _form.loading, action: _submit),
          SizedBox(height: AppSize.spaceXS),
          Button(title: s.hybrid_password_later, action: () => Navigator.pop(context, false))
        ]
      )
    );
  }

  Future<void> _submit() async {
    if (_form.loading.value || !_form.validate()) return;

    setState(() => _error = null);
    _form.loading.value = true;

    final joined = await hybridService.signIn(widget.login, _password.value);
    if (!mounted) return;
    _form.loading.value = false;

    if (joined) return Navigator.pop(context, true);

    _password.textController.clear();
    setState(() => _error = lanService.error);
  }
}
