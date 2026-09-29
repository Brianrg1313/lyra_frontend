import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/permission_request.dart';
import 'package:app/services/permissions/permission_requests_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Opens the access request for [permission] (`<area>.<action>`). Answers `true` when the
/// request went out; [requests] already holds it as pending by then.
///
/// [requests] is passed in because the modal opens above the screen that provides it.
/// [section] and [business] only name what is asked for, in the person's words.
Future<bool> showRequestPermission(
  BuildContext context, {
  required PermissionRequestsService requests,
  required String permission,
  required String section,
  required String business
}) async {
  final sent = await showModal(
    context: context,
    title: S.of(context).permission_request_title,
    builder: (_) => RequestPermissionModal(
      requests: requests,
      permission: permission,
      section: section,
      business: business
    )
  );

  return sent == true;
}

/// Asks for a permission with an optional note for whoever reviews it. The request grants
/// nothing: it is recorded for the business's managers.
class RequestPermissionModal extends StatefulWidget {
  const RequestPermissionModal({
    super.key,
    required this.requests,
    required this.permission,
    required this.section,
    required this.business
  });

  final PermissionRequestsService requests;
  final String permission;
  final String section;
  final String business;

  @override
  State<RequestPermissionModal> createState() => _RequestPermissionModalState();
}

class _RequestPermissionModalState extends State<RequestPermissionModal> {
  final _form = FormController();

  /// Optional, bounded by the backend's `REASON` rule.
  late final _reason = InputController(
    key: "REASON",
    form: _form,
    max: kPermissionReasonMax,
    customErrors: {
      InputError.long: S.of(context).permission_request_reason_long(kPermissionReasonMax)
    }
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextSmall(
          S.of(context).permission_request_subtitle(widget.section, widget.business),
          color: ThemeColor.of(context).text.secondary
        ),
        SizedBox(height: AppSize.spaceM),
        Input(
          title: S.of(context).permission_request_reason,
          placeholder: S.of(context).permission_request_reason_hint,
          controller: _reason,
          autofocus: true,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).permission_request_send,
          loading: _form.loading,
          action: _submit
        )
      ]
    )
  );

  Future<void> _submit() async {
    if (_form.loading.value || !_form.validate()) return;

    _form.loading.value = true;

    try {
      await widget.requests.request(widget.permission, reason: _reason.value);
    } catch (error) {
      if (!mounted) return;

      _form.loading.value = false;
      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );

      // Already pending or already granted: the screen behind was reread, there is nothing
      // left to ask here.
      if (error is Map && error["code"] == 409) Navigator.pop(context, false);
      return;
    }

    if (!mounted) return;

    _form.loading.value = false;
    FloatFlag.of(context).message(S.of(context).permission_request_sent(widget.section));
    Navigator.pop(context, true);
  }
}
