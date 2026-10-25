import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/local_server/local_server_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import '../../widgets/deployment_frame.dart';
import '../../widgets/recovery_words.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key, this.owner, this.account, this.company, this.onBack, this.onDone});

  /// The sign in's "create the server" (`AuthLan`): the e-mail and password typed there are the
  /// owner's, so the page doesn't ask for them again.
  final ({String email, String password})? owner;

  /// The server section online (plan D16): the signed-in account is the owner, its names
  /// proposed; its password on the server is asked, since the sealed keys hang on it (§6.3).
  final ({String email, String firstName, String lastName})? account;

  /// The company the master starts with (`setup`'s `company`): the cloud company's profile and
  /// its id (`business.md` B-30). Without it, the welcome creates it.
  final Map<String, Object?>? company;

  /// Where "back" goes; the sign in by default.
  final VoidCallback? onBack;

  /// Takes over once the words are confirmed, with the owner's password: the server section
  /// signs in to it and stays online instead of going to `/lan`.
  final Future<void> Function(String password)? onDone;

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

  // Created only when drawn: with an [owner] they never join the form. Each says what's wrong
  // under it; without its own messages a refused field only turned red, and a page that didn't
  // fit the window looked like a button doing nothing.
  late final _username = InputController(
    key: "USERNAME", form: _form, obligatory: true, min: 3, max: 32,
    customErrors: _errors(S.of(context).lan_username_input, short: S.of(context).lan_master_invalid_username)
  );
  late final _firstName = InputController(
    key: "FIRST_NAME", form: _form, obligatory: true, max: 64, initial: widget.account?.firstName,
    customErrors: _errors(S.of(context).first_name_input)
  );
  late final _lastName = InputController(
    key: "LAST_NAME", form: _form, obligatory: true, max: 64, initial: widget.account?.lastName,
    customErrors: _errors(S.of(context).last_name_input)
  );
  late final _password = InputController(
    key: "PASSWORD", form: _form, obligatory: true, type: InputType.password, min: 10, max: 256,
    customErrors: _errors(S.of(context).password_input, short: S.of(context).lan_master_weak_password)
  );
  // The server's own rule is 10 characters (`session.md` S-2); a passphrase gets the same. Obligatory
  // once ticked: it's validated only while drawn (see [_submit]).
  late final _passphrase = InputController(
    key: "PASSPHRASE", form: _form, obligatory: true, type: InputType.password, min: 10, max: 256,
    customErrors: _errors(S.of(context).lan_passphrase_input, short: S.of(context).lan_passphrase_short)
  );

  Map<InputError, String> _errors(String field, {String? short}) => {
    InputError.empty: S.of(context).lan_field_empty(field),
    InputError.long: S.of(context).lan_field_long(field),
    InputError.incomplete: ?short,
    InputError.invalid: ?short
  };

  bool _usePassphrase = false;
  bool _licence = false;
  bool _wroteDown = false;
  String? _error;
  List<String>? _words;

  /// The owner's e-mail when it comes from elsewhere: no username is asked then.
  String? get _email => widget.owner?.email ?? widget.account?.email;

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
      if (_email case final email?)
        DeploymentNote(S.of(context).lan_master_owner_email(email))
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
      if (widget.owner == null) Input(
        placeholder: widget.account == null ? S.of(context).password_input : S.of(context).hybrid_password_title,
        controller: _password,
        onSubmit: _submit
      ),
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
    // Only what is drawn: `_form.validate()` would also check a passphrase typed and then
    // unticked, refusing the page over a field nobody can see.
    final drawn = [
      if (_email == null) _username,
      _firstName,
      _lastName,
      if (widget.owner == null) _password,
      if (_usePassphrase) _passphrase
    ];
    for (final input in drawn) {
      if (!input.validate(input)) return;
    }
    if (!_licence) return setState(() => _error = S.of(context).lan_master_eula_required);

    setState(() => _error = null);
    _form.loading.value = true;

    final server = context.read<LanService>().server;

    final owner = widget.owner;

    final email = _email;

    server.setUp(
      username: email == null ? _username.value : LocalServerService.usernameOf(email),
      password: owner?.password ?? _password.value,
      email: email,
      company: widget.company,
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

    if (widget.onDone case final done?) {
      _form.loading.value = true;
      await done(_password.value);
      if (mounted) _form.loading.value = false;
      return;
    }

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
