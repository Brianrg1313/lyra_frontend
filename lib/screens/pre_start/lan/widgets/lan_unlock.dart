import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';

/// The passphrase, on the master's own app only (plan §6.2): to unlock the engine
/// (`engine.unlock`), or with [enroll] to certify this app again when it lost its key (then
/// the passphrase is only needed in passphrase mode).
class LanUnlock extends StatefulWidget {
  const LanUnlock({super.key, this.enroll = false});

  final bool enroll;

  @override
  State<LanUnlock> createState() => _LanUnlockState();
}

class _LanUnlockState extends State<LanUnlock> {
  final _form = FormController();

  late final _passphrase = InputController(
    key: "PASSPHRASE",
    form: _form,
    obligatory: !widget.enroll,
    type: InputType.password,
    max: 256
  );

  String? _error;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return DeploymentFrame(
      title: widget.enroll ? s.lan_enroll_title : s.lan_locked_title,
      subtitle: widget.enroll ? s.lan_enroll_subtitle : s.lan_locked_master,
      children: [
        Input(placeholder: s.lan_passphrase_input, controller: _passphrase, onSubmit: _submit, autofocus: true),
        if (_error != null) DeploymentNote(_error!, error: true),
        SizedBox(height: AppSize.spaceXS),
        MainButton(title: widget.enroll ? s.lan_enroll : s.lan_unlock, loading: _form.loading, action: _submit)
      ]
    );
  }

  void _submit() {
    if (_form.loading.value) return;
    if (!_form.validate()) return;

    _form.loading.value = true;
    final lan = context.read<LanService>();
    final passphrase = _passphrase.value.isEmpty ? null : _passphrase.value;
    final done = widget.enroll ? lan.enrollMaster(passphrase: passphrase) : lan.unlock(passphrase!);

    done.then((status) {
      if (!mounted) return;
      _form.loading.value = false;
      _passphrase.textController.clear();
      // Unlocking answers the master's message; enrolling, the engine's refusal code.
      final error = lan.error;
      setState(() => _error = error == null || !widget.enroll ? error : S.of(context).lan_error_code(error));
    });
  }
}
