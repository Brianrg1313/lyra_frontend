import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// The account's first password (`email/sign_up/password`), typed twice. Answers whether it was
/// made; one that exists already is said by the backend's refusal, and the service remembers it.
Future<bool> showCreatePassword(BuildContext context, AccountSecurityService service) => showModal(
  context: context,
  title: S.of(context).account_password_title,
  builder: (context) => CreatePasswordModal(service: service)
).then((value) => value == true);

class CreatePasswordModal extends StatefulWidget {
  const CreatePasswordModal({super.key, required this.service});

  final AccountSecurityService service;

  @override
  State<CreatePasswordModal> createState() => _CreatePasswordModalState();
}

class _CreatePasswordModalState extends State<CreatePasswordModal> {
  final _form = FormController();
  late final _password = InputController.password(form: _form, obligatory: true);
  late final _repeat = InputController.password(form: _form, key: "REPEAT", obligatory: true);

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
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(s.account_password_subtitle, lines: 4, color: scheme.subtitle),
          SizedBox(height: AppSize.spaceM),
          Input(placeholder: s.password_input, controller: _password, autofocus: true, next: _repeat.focus),
          Input(placeholder: s.confirm_password_input, controller: _repeat, onSubmit: _submit),
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.spaceXS),
              child: TextSmall(_error!, lines: 2, color: scheme.accent)
            ),
          SizedBox(height: AppSize.spaceXS),
          MainButton(title: s.account_password_create, loading: _form.loading, action: _submit),
          SizedBox(height: AppSize.spaceXS),
          Button(title: s.cancel, action: () => Navigator.pop(context, false))
        ]
      )
    );
  }

  Future<void> _submit() async {
    if (_form.loading.value || !_form.validate()) return;

    if (_password.text != _repeat.text) {
      setState(() => _error = S.of(context).password_mismatch);
      return;
    }

    setState(() => _error = null);
    _form.loading.value = true;

    try {
      await widget.service.createPassword(_password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      FloatFlag.showFromError(error);
      if (!mounted) return;
      _form.loading.value = false;
      // Refused because there is one: nothing left to do here.
      if (widget.service.hasPassword) Navigator.pop(context, false);
    }
  }
}
