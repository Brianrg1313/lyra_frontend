import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/permissions/permission_requests_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/permissions/request_permission/_request_permission.dart';

/// What is seen in place of a section (or a tab) the person is not granted in the active
/// business: that they lack it, and a way to ask for it.
///
/// [permission] is the missing id (`finance.view`), which is what the request asks for;
/// [title] names it for the person (the section's title). Once asked, the button gives way
/// to "requested": the backend refuses a second pending request anyway.
///
/// Mounted only with an active business (see `homeContent`); a person with none sees
/// `NoBusinessSection` instead. It owns its [PermissionRequestsService]; the home remounts
/// sections on a business switch, so the list is always the active business's.
///
/// A tab passes `surface: false`: it is drawn on its page's sheet, which is already a surface.
class NoPermissionSection extends StatefulWidget {
  const NoPermissionSection({
    super.key,
    required this.permission,
    required this.title,
    this.surface = true,
    this.requests
  });

  final String permission;
  final String title;
  final bool surface;

  /// Injected by tests; otherwise the widget creates and reads its own.
  final PermissionRequestsService? requests;

  @override
  State<NoPermissionSection> createState() => _NoPermissionSectionState();
}

class _NoPermissionSectionState extends State<NoPermissionSection> {
  late final PermissionRequestsService _requests;

  @override
  void initState() {
    super.initState();
    _requests = widget.requests ?? (PermissionRequestsService()..load());
  }

  @override
  void dispose() {
    if (widget.requests == null) _requests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = context.select<BusinessService, String>(
      (service) => service.activeId == null ? "" : service.active.name
    );

    final message = ListenableBuilder(
      listenable: _requests,
      builder: (context, _) {
        final pending = _requests.isPending(widget.permission);
        // Not offered until the list is read: it may already be requested.
        final known = _requests.status == PermissionRequestsStatus.ready
          || _requests.status == PermissionRequestsStatus.error;

        return SectionMessage(
          icon: Icons.lock_outline,
          title: S.of(context).permission_denied_title(widget.title),
          subtitle: pending
            ? S.of(context).permission_denied_pending(business)
            : S.of(context).permission_denied_subtitle(business),
          action: known && !pending ? () => showRequestPermission(
            context,
            requests: _requests,
            permission: widget.permission,
            section: widget.title,
            business: business
          ) : null,
          actionLabel: S.of(context).permission_request_action,
          actionIcon: Icons.key_outlined
        );
      }
    );

    if (!widget.surface) return message;

    return Surface(padding: EdgeInsets.all(AppSize.padding), child: message);
  }
}
