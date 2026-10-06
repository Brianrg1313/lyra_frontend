import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/local_server/widgets/pairing_qr.dart';

import './two_factor_proof.dart';

/// Enrolls an authenticator app: a staged secret as a QR and as a key, then the app's first
/// code. [prove] asks for the factor in force, when there is one, right before the request.
/// Pops the recovery codes, or nothing when closed.
class TwoFactorAppModal extends StatefulWidget {
  const TwoFactorAppModal({super.key, required this.service, this.prove});

  final AccountSecurityService service;
  final Future<TwoFactorProof?> Function()? prove;

  @override
  State<TwoFactorAppModal> createState() => _TwoFactorAppModalState();
}

class _TwoFactorAppModalState extends State<TwoFactorAppModal> {
  final _form = FormController();
  late final _code = InputController.code(form: _form, spaces: TwoFactorCode.length);

  TwoFactorEnrollment? _enrollment;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _stage();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _stage() async {
    setState(() => _failed = false);

    try {
      final enrollment = await widget.service.stageApp();
      if (mounted) setState(() => _enrollment = enrollment);
    } catch (error) {
      FloatFlag.showFromError(error);
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final enrollment = _enrollment;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: TwoFactorCode.width, maxWidth: TwoFactorCode.width),
      child: enrollment == null
        ? SizedBox(
            height: AppSize.action * 4,
            child: Center(child: _failed
              ? Button(title: s.account_retry, width: null, action: _stage)
              : Loading(color: scheme.primary))
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextMedium(s.two_factor_app_scan, lines: 2, color: scheme.subtitle),
              SizedBox(height: AppSize.spaceS),
              Center(child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap)),
                child: PairingQr(data: enrollment.uri, size: AppSize.action * 4)
              )),
              SizedBox(height: AppSize.spaceS),
              TextSmall(s.two_factor_app_manual, color: scheme.subtitle),
              SizedBox(height: AppSize.gap),
              Surface(
                color: scheme.surface,
                radius: AppSize.cornerInset(AppSize.gap),
                padding: EdgeInsets.only(left: AppSize.spaceS, right: AppSize.gap),
                height: AppSize.action,
                child: Row(children: [
                  Expanded(child: TextMedium(enrollment.groupedSecret, selectable: true, bold: true, ellipsis: true)),
                  FocusableWidget(
                    message: s.two_factor_app_copy,
                    action: () async {
                      await Clipboard.setData(ClipboardData(text: enrollment.secret));
                      if (context.mounted) FloatFlag.of(context).message(s.two_factor_codes_copied);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(AppSize.gap),
                      child: Icon(CI.copy, size: AppSize.text * 1.2, color: scheme.text.secondary)
                    )
                  )
                ])
              ),
              SizedBox(height: AppSize.spaceM),
              TextSmall(s.two_factor_app_code, lines: 2, color: scheme.subtitle),
              SizedBox(height: AppSize.gap),
              CodeInput(
                controller: _code,
                spaces: TwoFactorCode.length,
                onEditingComplete: (_) => _submit()
              ),
              SizedBox(height: AppSize.spaceXS),
              MainButton(title: s.two_factor_turn_on, loading: _form.loading, action: _submit)
            ]
          )
    );
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
      final codes = await widget.service.enableApp(_code.text, proof: proof);
      if (mounted) Navigator.pop(context, codes);
    } catch (error) {
      FloatFlag.showFromError(error);
      if (!mounted) return;
      _form.loading.value = false;
      _code.textController.clear();
    }
  }
}
