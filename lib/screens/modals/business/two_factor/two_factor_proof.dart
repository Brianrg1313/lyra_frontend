import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Asks for the factor in force before a change (turn off, switch, new recovery codes): the
/// app's code or one recovery code, or the code `two_factor/code` mails now. Answers the proof;
/// the request it goes with checks it, so a wrong one is said there.
///
/// Asked right before the request, never ahead of it: an app's code lives 30 seconds.
Future<TwoFactorProof?> showTwoFactorProof(BuildContext context, TwoFactorMethod method) => showModal(
  context: context,
  title: S.of(context).two_factor_proof_title,
  builder: (context) => TwoFactorProofModal(method: method)
).then((value) => value is TwoFactorProof ? value : null);

class TwoFactorProofModal extends StatefulWidget {
  const TwoFactorProofModal({super.key, required this.method});

  final TwoFactorMethod method;

  @override
  State<TwoFactorProofModal> createState() => _TwoFactorProofModalState();
}

class _TwoFactorProofModalState extends State<TwoFactorProofModal> {
  final _form = FormController();
  final _recoveryForm = FormController();
  final _sending = ValueNotifier<bool>(false);

  late final _code = InputController.code(form: _form, spaces: TwoFactorCode.length);
  late final _recovery = InputController(key: "RECOVERY_CODE", form: _recoveryForm, obligatory: true, max: 20);

  /// Only the app has recovery codes.
  bool _useRecovery = false;

  bool get _email => widget.method == TwoFactorMethod.email;

  @override
  void initState() {
    super.initState();
    if (_email) _send();
  }

  @override
  void dispose() {
    _form.dispose();
    _recoveryForm.dispose();
    _sending.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: TwoFactorCode.width, maxWidth: TwoFactorCode.width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(
            _useRecovery ? s.two_factor_check_recovery : _email ? s.two_factor_proof_email : s.two_factor_proof_app,
            lines: 3,
            color: scheme.subtitle
          ),
          SizedBox(height: AppSize.spaceM),
          if (_useRecovery)
            Input(
              placeholder: s.two_factor_recovery_input,
              controller: _recovery,
              autofocus: true,
              onSubmit: _submit
            )
          else
            CodeInput(
              controller: _code,
              spaces: TwoFactorCode.length,
              autofocus: true,
              onEditingComplete: (_) => _submit()
            ),
          SizedBox(height: AppSize.spaceXS),
          MainButton(title: s.two_factor_continue, action: _submit),
          SizedBox(height: AppSize.spaceXS),
          if (_email)
            Button(title: s.two_factor_resend, loading: _sending, action: _send)
          else
            Button(
              title: _useRecovery ? s.two_factor_use_code : s.two_factor_use_recovery,
              action: () => setState(() => _useRecovery = !_useRecovery)
            )
        ]
      )
    );
  }

  Future<void> _send() async {
    if (_sending.value) return;
    _sending.value = true;

    try {
      await AccountSecurityService.sendCode();
    } catch (error) {
      FloatFlag.showFromError(error);
    }

    if (mounted) _sending.value = false;
  }

  void _submit() {
    if (_useRecovery) {
      if (!_recoveryForm.validate()) return;
      Navigator.pop(context, TwoFactorProof.recovery(_recovery.text.trim()));
      return;
    }

    if (!_form.validate()) return;
    Navigator.pop(context, TwoFactorProof.code(_code.text));
  }
}

/// What every second-factor code has in common: six digits, in a modal this wide.
abstract final class TwoFactorCode {
  static const int length = 6;
  static const double width = 400;
}
