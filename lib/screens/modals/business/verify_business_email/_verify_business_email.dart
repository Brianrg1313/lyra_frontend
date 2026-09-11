import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Verification of one of the business email addresses.
///
/// An address someone wrote is an assertion; verifying it is what turns it
/// into a fact. A code is sent to the mailbox and reading it **is** the proof:
/// that is why the code never travels in the response and why this modal
/// cannot do anything on its own.
///
/// What is proved is that the mailbox exists and that the business reads it,
/// not that the business is who it says it is: that is its legal situation, it
/// is granted by the verification process and is not touched from any screen.
///
/// The code is asked when opening and not with a button: opening this already
/// is having asked for it to be verified, and a modal that starts with an
/// empty field and a "first ask for the code" notice is a step that decides
/// nothing. The resend is a button, with the minute of wait the backend
/// imposes —it is the only place of the card that writes to an address someone
/// typed—.
///
/// If the request fails the form is shown the same. The most common case is
/// precisely the rejection for waiting: it means that a moment ago one was
/// sent, that it is still valid, so what has to be done is write it and not
/// ask for it again.
///
/// It closes returning `true` when the address remained verified. The list is
/// not returned: the service has already re-read the profile and the card
/// repaints itself.
class VerifyBusinessEmailModal extends StatefulWidget {
  const VerifyBusinessEmailModal({super.key, required this.email});

  /// The address being verified.
  final BusinessEmailModel email;

  @override
  State<VerifyBusinessEmailModal> createState() =>
    _VerifyBusinessEmailModalState();
}

class _VerifyBusinessEmailModalState extends State<VerifyBusinessEmailModal> {
  final _form = FormController();
  final _resending = ValueNotifier<bool>(false);

  /// How many digits the code has. The ones the backend sends.
  static const int _spaces = 6;

  /// How long one has to wait to ask for another code. It is the same minute
  /// the backend applies: counting it here does not replace it —the one that
  /// rules is the one there— but it avoids the button existing only to be
  /// rejected.
  static const int _cooldown = 60;

  /// Where the code was sent. It comes out of the response and not from what
  /// is on screen: it is the **saved** address, so a typo is seen here and
  /// not in a stranger's mailbox.
  late String _sentTo = widget.email.email;

  Timer? _timer;
  int _left = _cooldown;

  late final _code = InputController.code(
    form: _form,
    spaces: _spaces,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).code_input),
      InputError.invalid: S.of(context).form_invalid_ma(
        S.of(context).code_input
      ),
      InputError.incomplete: S.of(context).form_incomplete_ma(
        S.of(context).code_input
      )
    }
  );

  @override
  void initState() {
    super.initState();

    // After the first frame: asking for the code writes in the service, and
    // doing it while the tree mounts notifies whoever is mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resending.dispose();
    _form.dispose();
    super.dispose();
  }

  /// Base width, the same as the profile forms: this modal opens from the
  /// same row as them. It is fixed because the content —a six-slot code—
  /// measures much less than the phrase that explains it.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(
            S.of(context).business_email_verify_sent,
            lines: 3,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.gap),
          // The address can be selected: if the code did not arrive, the
          // first thing done is to read it letter by letter.
          TextMedium(_sentTo, bold: true, lines: 2, selectable: true),
          SizedBox(height: AppSize.spaceS),
          CodeInput(
            spaces: _spaces,
            autofocus: true,
            controller: _code,
            onEditingComplete: (_) => _submit()
          ),
          SizedBox(height: AppSize.gap),
          _resend(context, scheme),
          SizedBox(height: AppSize.spaceM),
          Button(
            title: S.of(context).business_email_verify,
            loading: _form.loading,
            action: _submit
          )
        ]
      )
    );
  }

  /// Ask for another code, or how long until it can be asked. While the
  /// minute runs it is a text and not a dimmed button: a button that cannot
  /// be touched invites touching it, and what has to be done in that while is
  /// to look at the mailbox.
  Widget _resend(BuildContext context, SchemeColor scheme) {
    if (_left > 0) {
      return TextSmall(
        S.of(context).resend_code_timer(_time),
        textAlign: TextAlign.center,
        color: scheme.text.secondary
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _resending,
      builder: (context, busy, _) => FeedbackButton(
        action: busy ? null : _send,
        message: S.of(context).resend_code,
        height: AppSize.button,
        radius: AppSize.cornerInset(AppSize.gap),
        color: scheme.surface,
        feedbackColor: scheme.surfaceOver,
        child: Center(child: TextSmall(
          S.of(context).resend_code,
          color: busy ? scheme.text.secondary : scheme.primary
        ))
      )
    );
  }

  String get _time {
    final minutes = _left ~/ 60;
    final seconds = _left % 60;

    return "$minutes:${seconds.toString().padLeft(2, "0")}";
  }

  /// Asks for the code. It is the same call when opening and when resending:
  /// the only thing that changes is that the second time there is already
  /// something on screen.
  Future<void> _send() async {
    _resending.value = true;

    final sent = await context.read<BusinessService>().sendEmailCode(
      context,
      widget.email.id
    );

    if (!mounted) return;

    _resending.value = false;

    // If it was not sent, the error was already shown and the form stays as
    // it was: there can be a previous code still alive. The clock starts the
    // same, because what prevents asking for another is the backend minute and
    // that one runs since the last send, not since the last attempt.
    setState(() {
      if (sent != null && sent.isNotEmpty) _sentTo = sent;
    });

    _countdown();
  }

  void _countdown() {
    _timer?.cancel();
    setState(() => _left = _cooldown);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_left <= 1) {
        timer.cancel();
        setState(() => _left = 0);
        return;
      }

      setState(() => _left--);
    });
  }

  Future<void> _submit() async {
    if (!_form.validate()) return;

    _form.loading.value = true;

    final verified = await context.read<BusinessService>().verifyEmail(
      context,
      widget.email.id,
      _code.value.trim()
    );

    if (!mounted) return;

    _form.loading.value = false;

    // The error was already shown by the service; here only where to correct
    // is marked, which is the only field there is.
    if (!verified) {
      _code.status.setStatus(InputStatus.error, InputError.invalid);
      return;
    }

    // No notice: when the modal closes the tag of the row already says
    // "verified", which is exactly what the flag was going to tell.
    Navigator.pop(context, true);
  }
}