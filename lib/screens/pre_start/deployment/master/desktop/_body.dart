import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/local_server/local_server_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import '../../widgets/deployment_frame.dart';
import '../../widgets/recovery_words.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key, this.owner, this.onBack});

  /// The sign in's "create the server" (`AuthLan`): the e-mail and password typed there are the
  /// owner's, so the page doesn't ask for them again.
  final ({String email, String password})? owner;

  /// Where "back" goes; the sign in by default.
  final VoidCallback? onBack;

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// Two steps on one page: the owner's account, then the recovery words. The words exist only in
/// this state: leaving the page before confirming them loses them (the engine keeps no copy), which
/// is why the confirmation is required before the server starts.
///
/// The company isn't asked here: the owner lands on the welcome, whose "create company" makes it
/// (`business.create`), as in the cloud.
class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();

  // Created only when drawn: with an [owner] they never join the form.
  late final _username = InputController(key: "USERNAME", form: _form, obligatory: true, min: 3, max: 32);
  late final _firstName = InputController(key: "FIRST_NAME", form: _form, obligatory: true, max: 64);
  late final _lastName = InputController(key: "LAST_NAME", form: _form, obligatory: true, max: 64);
  late final _password = InputController(key: "PASSWORD", form: _form, obligatory: true, type: InputType.password, min: 10, max: 256);
  // The server's own rule is 10 characters (`session.md` S-2); a passphrase gets the same.
  late final _passphrase = InputController(key: "PASSPHRASE", form: _form, type: InputType.password, min: 10, max: 256);

  bool _usePassphrase = false;
  bool _licence = false;
  bool _wroteDown = false;
  String? _error;
  List<String>? _words;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _words == null ? _setup(context) : _recovery(context, _words!);

  Widget _setup(BuildContext context) => DeploymentFrame(
    title: S.of(context).lan_master_title,
    subtitle: S.of(context).lan_master_subtitle,
    children: [
      TextMedium(S.of(context).lan_master_owner, bold: true),
      SizedBox(height: AppSize.spaceXS),
      if (widget.owner case final owner?)
        DeploymentNote(S.of(context).lan_master_owner_email(owner.email))
      else
        Input(placeholder: S.of(context).lan_username_input, controller: _username, next: _firstName.focus),
      InputRow(children: [
        Input(placeholder: S.of(context).first_name_input, controller: _firstName, next: _lastName.focus),
        Input(
          placeholder: S.of(context).last_name_input,
          controller: _lastName,
          next: widget.owner == null ? _password.focus : null,
          onSubmit: widget.owner == null ? null : _submit
        )
      ]),
      if (widget.owner == null) Input(placeholder: S.of(context).password_input, controller: _password, onSubmit: _submit),
      DeploymentCheck(
        label: S.of(context).lan_passphrase_toggle,
        value: _usePassphrase,
        onChanged: (value) => setState(() => _usePassphrase = value)
      ),
      DeploymentNote(S.of(context).lan_passphrase_hint),
      if (_usePassphrase) Input(placeholder: S.of(context).lan_passphrase_input, controller: _passphrase),
      DeploymentCheck(
        label: S.of(context).lan_eula_accept,
        value: _licence,
        onChanged: (value) => setState(() => _licence = value)
      ),
      if (_error != null) DeploymentNote(_error!, error: true),
      SizedBox(height: AppSize.spaceS),
      MainButton(title: S.of(context).lan_master_create, loading: _form.loading, action: _submit),
      SizedBox(height: AppSize.spaceXS),
      Button(
        title: widget.onBack == null ? S.of(context).lan_other_mode : S.of(context).back,
        action: widget.onBack ?? () => Navis.pushAndClearStack(context, "/login")
      )
    ]
  );

  Widget _recovery(BuildContext context, List<String> words) => DeploymentFrame(
    title: S.of(context).lan_recovery_title,
    subtitle: S.of(context).lan_recovery_subtitle,
    maxWidth: 560,
    children: [
      RecoveryWords(words: words),
      SizedBox(height: AppSize.spaceS),
      DeploymentCheck(
        label: S.of(context).lan_recovery_confirm,
        value: _wroteDown,
        onChanged: (value) => setState(() => _wroteDown = value)
      ),
      if (_error != null) DeploymentNote(_error!, error: true),
      SizedBox(height: AppSize.spaceS),
      MainButton(title: S.of(context).lan_recovery_continue, loading: _form.loading, action: _start)
    ]
  );

  void _submit() {
    if (_form.loading.value) return;
    if (!_form.validate()) return;
    if (_usePassphrase && _passphrase.value.length < 10) {
      _passphrase.status.setStatus(InputStatus.error, InputError.incomplete);
      return;
    }
    if (!_licence) return setState(() => _error = S.of(context).lan_master_eula_required);

    setState(() => _error = null);
    _form.loading.value = true;

    final server = context.read<LanService>().server;

    final owner = widget.owner;

    server.setUp(
      username: owner == null ? _username.value : LocalServerService.usernameOf(owner.email),
      password: owner?.password ?? _password.value,
      email: owner?.email,
      firstName: _firstName.value,
      lastName: _lastName.value,
      passphrase: _usePassphrase ? _passphrase.value : null
    ).then((words) {
      if (!mounted) return;
      _form.loading.value = false;

      if (words == null) return setState(() => _error = _refusal(context, server.error));
      setState(() => _words = words);
    });
  }

  /// The words are confirmed: this computer is the master from now on. Started from the sign in,
  /// the owner's e-mail and password sign it in too, so `/lan` goes on to the welcome; otherwise
  /// `/lan` asks for them.
  Future<void> _start() async {
    if (!_wroteDown) return setState(() => _error = S.of(context).lan_recovery_required);

    Deployment.attach(DeploymentRole.master);

    if (widget.owner case final owner?) {
      final lan = context.read<LanService>();
      _form.loading.value = true;

      await lan.open();
      if (lan.status == LanStatus.signedOut) await lan.signIn(owner.email, owner.password);
      if (!mounted) return;
    }

    Navis.pushAndClearStack(context, "/lan");
  }

  static String _refusal(BuildContext context, String? code) => switch (code) {
    "invalid_field" => S.of(context).lan_master_invalid_username,
    "weak_password" => S.of(context).lan_master_weak_password,
    "already_set_up" || "data_exists" => S.of(context).lan_master_exists,
    _ => S.of(context).lan_error_code(code ?? "unknown")
  };
}
