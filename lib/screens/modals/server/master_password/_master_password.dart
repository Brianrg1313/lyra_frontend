import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show hybridService, lanService;

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Asks, once, for [login]'s password on this device's master, after an online sign in that
/// couldn't open the master's session by itself (the master took neither the cloud password nor
/// the cloud's grant): with it the session outlives the internet (plan §9.6, D14). Answers whether
/// the master took it; "not now" goes on online only.
Future<bool> showMasterPassword(BuildContext context, {required String login}) => showModal(
  context: context,
  title: S.of(context).hybrid_password_title,
  builder: (context) => MasterPasswordModal(login: login)
).then((value) => value == true);

/// Asks for the person's password on the master to open the protected details of a session the
/// cloud's grant opened (`session.md` S-13): payment accounts, pay, documents. Answers whether the
/// master took it.
Future<bool> showUnseal(BuildContext context) => showModal(
  context: context,
  title: S.of(context).unseal_title,
  builder: (context) => const MasterPasswordModal()
).then((value) => value == true);

/// [login] set: the session itself ([showMasterPassword]); null: the open session's protected
/// details ([showUnseal]).
class MasterPasswordModal extends StatefulWidget {
  const MasterPasswordModal({super.key, this.login});

  final String? login;

  @override
  State<MasterPasswordModal> createState() => _MasterPasswordModalState();
}

class _MasterPasswordModalState extends State<MasterPasswordModal> {
  final _form = FormController();
  late final _password = InputController.password(form: _form, obligatory: true);

  String? _error;

  static const double _width = 400;

  bool get _unseal => widget.login == null;

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
          TextMedium(_unseal ? s.unseal_subtitle : s.hybrid_password_subtitle, lines: 4, color: ThemeColor.of(context).subtitle),
          SizedBox(height: AppSize.spaceM),
          Input(placeholder: s.password_input, controller: _password, autofocus: true, onSubmit: _submit),
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.spaceXS),
              child: TextSmall(_error!, lines: 4, color: ThemeColor.of(context).accent)
            ),
          SizedBox(height: AppSize.spaceXS),
          MainButton(title: _unseal ? s.unseal_button : s.hybrid_password_button, loading: _form.loading, action: _submit),
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

    final login = widget.login;
    final taken = login == null
      ? await lanService.unseal(_password.value)
      : await hybridService.signIn(login, _password.value);
    if (!mounted) return;
    _form.loading.value = false;

    if (taken) return Navigator.pop(context, true);

    _password.textController.clear();
    setState(() => _error = lanService.error);
  }
}
