import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

import './two_factor_proof.dart';

/// Turns the email factor on: mails a code to [email] on opening and takes it back. Switching
/// from the app, [prove] asks for the app right before the request. Pops `true` once it is on.
class TwoFactorEmailModal extends StatefulWidget {
  const TwoFactorEmailModal({super.key, required this.service, required this.email, this.prove});

  final AccountSecurityService service;
  final String email;
  final Future<TwoFactorProof?> Function()? prove;

  @override
  State<TwoFactorEmailModal> createState() => _TwoFactorEmailModalState();
}

class _TwoFactorEmailModalState extends State<TwoFactorEmailModal> {
  final _form = FormController();
  final _sending = ValueNotifier<bool>(false);
  late final _code = InputController.code(form: _form, spaces: TwoFactorCode.length);

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _form.dispose();
    _sending.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: TwoFactorCode.width, maxWidth: TwoFactorCode.width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(s.two_factor_email_sent(widget.email), lines: 3, color: ThemeColor.of(context).subtitle),
          SizedBox(height: AppSize.spaceM),
          CodeInput(
            controller: _code,
            spaces: TwoFactorCode.length,
            autofocus: true,
            onEditingComplete: (_) => _submit()
          ),
          SizedBox(height: AppSize.spaceXS),
          MainButton(title: s.two_factor_turn_on, loading: _form.loading, action: _submit),
          SizedBox(height: AppSize.spaceXS),
          Button(title: s.two_factor_resend, loading: _sending, action: _send)
        ]
      )
    );
  }

  Future<void> _send() async {
    if (_sending.value) return;
    _sending.value = true;

    try {
      await widget.service.stageEmail();
    } catch (error) {
      FloatFlag.showFromError(error);
    }

    if (mounted) _sending.value = false;
  }

  Future<void> _submit() async {
    if (_form.loading.value || !_form.validate()) return;

    TwoFactorProof? proof;
    if (widget.prove != null) {
      proof = await widget.prove!();
      if (proof == null || !mounted) return;
    }

    _form.loading.value = true;

    try {
      await widget.service.enableEmail(_code.text, proof: proof);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      FloatFlag.showFromError(error);
      if (!mounted) return;
      _form.loading.value = false;
      _code.textController.clear();
    }
  }
}
