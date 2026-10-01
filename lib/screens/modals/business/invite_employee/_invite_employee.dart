import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/business/employee_activation_model.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Opens the invitation form over the employees tab. Answers `true` when the
/// invitation went out; the service has already reread the list and opened
/// the new row by then.
///
/// [employees] is passed in because the modal opens above the business page,
/// which is where that service is provided.
Future<bool> showInviteEmployee(
  BuildContext context, {
  required BusinessEmployeesService employees
}) async {
  final sent = await showModal(
    context: context,
    title: S.of(context).employees_invite_title,
    builder: (_) => InviteEmployeeModal(employees: employees)
  );

  return sent == true;
}

/// Invites someone by email, with or without an account.
///
/// The job title is asked too: the backend files the job with the invitation
/// and a job cannot be without one. The rest of the job is filled in later,
/// from the person's detail.
class InviteEmployeeModal extends StatefulWidget {
  const InviteEmployeeModal({super.key, required this.employees});

  final BusinessEmployeesService employees;

  @override
  State<InviteEmployeeModal> createState() => _InviteEmployeeModalState();
}

class _InviteEmployeeModalState extends State<InviteEmployeeModal> {
  final _form = FormController();

  late final _email = InputController(
    key: "EMAIL",
    form: _form,
    type: InputType.email,
    pattern: "[A-Za-z0-9_@.+-]",
    min: 6,
    max: 255,
    obligatory: true,
    customErrors: _errors(S.of(context).employees_invite_email)
  );

  /// Bounds of the backend's `JOB_TITLE` rule.
  late final _job = InputController(
    key: "JOB_TITLE",
    form: _form,
    min: 2,
    max: 64,
    obligatory: true,
    customErrors: _errors(S.of(context).employees_invite_job)
  );

  Map<InputError, String> _errors(String field) => {
    InputError.empty: S.of(context).form_empty_ma(field),
    InputError.invalid: S.of(context).form_invalid_ma(field),
    InputError.long: S.of(context).form_long_ma(field),
    InputError.incomplete: S.of(context).form_incomplete_ma(field)
  };

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// The width of the business profile forms, opened from the same page.
  static const double _width = 400;

  /// What a master answered for a new account: the form gives way to it, since the code is
  /// shown this once.
  EmployeeActivation? _activation;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: _activation == null ? _fields(context) : _ActivationCode(activation: _activation!)
  );

  Widget _fields(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextSmall(
        // A master has no e-mail to send: it hands over a code instead (`employees.md` E-10).
        CapabilityService().singleCompany
          ? S.of(context).employees_invite_subtitle_local
          : S.of(context).employees_invite_subtitle,
        lines: 5,
        color: ThemeColor.of(context).text.secondary
      ),
      SizedBox(height: AppSize.spaceM),
      Input(
        title: S.of(context).employees_invite_email,
        placeholder: S.of(context).employees_invite_email_hint,
        controller: _email,
        autofocus: true
      ),
      SizedBox(height: AppSize.spaceS),
      Input(
        title: S.of(context).employees_invite_job,
        placeholder: S.of(context).employees_invite_job_hint,
        controller: _job,
        onSubmit: _submit
      ),
      SizedBox(height: AppSize.spaceM),
      Button(
        title: S.of(context).employees_invite_send,
        loading: _form.loading,
        action: _submit
      )
    ]
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    _form.loading.value = true;

    final sent = await widget.employees.invite(
      context,
      email: _email.value.trim().toLowerCase(),
      jobTitle: _job.value.trim()
    );

    if (!mounted) return;

    _form.loading.value = false;

    // A refusal was already shown by the service; what was typed stays to be
    // corrected.
    if (sent == null) return;

    if (sent.activation != null) return setState(() => _activation = sent.activation);

    Navigator.pop(context, true);
  }
}

/// The activation code of an account a master made for the invitation (`session.md` S-8), with
/// what to do with it: the person types it, with a password of their choosing, the first time
/// they sign in on a device paired with the server. The master answers it only once.
class _ActivationCode extends StatelessWidget {
  const _ActivationCode({required this.activation});

  final EmployeeActivation activation;

  @override
  Widget build(BuildContext context) {
    final code = activation.code;
    final expires = activation.expires;
    final scheme = ThemeColor.of(context);
    final text = S.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextSmall(text.employees_invite_code_subtitle, lines: 5, color: scheme.text.secondary),
        SizedBox(height: AppSize.spaceM),
        Surface(
          color: scheme.surfaceOver,
          padding: EdgeInsets.all(AppSize.spaceS),
          child: Column(children: [
            TextSmall(text.lan_activate_code_input, color: scheme.subtitle),
            SizedBox(height: AppSize.gap),
            TextInter(
              code.length == 8 ? "${code.substring(0, 4)} ${code.substring(4)}" : code,
              multiplier: 2.4,
              bold: true,
              selectable: true
            ),
            if (expires != null) ...[
              SizedBox(height: AppSize.gap),
              TextSmall(
                text.employees_invite_code_expires(MaterialLocalizations.of(context).formatMediumDate(expires),
                  TimeOfDay.fromDateTime(expires).format(context)),
                color: scheme.subtitle,
                textAlign: TextAlign.center,
                lines: 2
              )
            ]
          ])
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: text.employees_invite_code_copy,
          action: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) FloatFlag.of(context).message(text.employees_invite_code_copied);
          }
        ),
        SizedBox(height: AppSize.spaceXS),
        MainButton(title: text.employees_invite_code_done, action: () => Navigator.pop(context, true))
      ]
    );
  }
}
