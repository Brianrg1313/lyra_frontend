import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

/// Tells a home screen that another business was activated.
///
/// Everything seen inside the home belongs to a business —the tables, the
/// products, the reports—, so choosing another one in the side bar selector
/// makes the screen being looked at go stale. The general case is solved by
/// the shell mounting the section again (see `Home`): every section requests
/// its data again in its `initState` without listening to anything on its own.
///
/// This mixin is for what a fresh mount does not fix: the **sub-pages tied to
/// an id** (`/home/channels/:id`, `/home/business/:id`). That id belongs to
/// the previous business —a channel the new business does not have—, so
/// remounting them with the same id would ask for something that no longer
/// exists. What belongs there is to go where the new business does have
/// something to show.
///
/// ```dart
/// class _State extends State<Screen> with BusinessListener<Screen> {
///   @override
///   void onBusinessChanged(String businessId) =>
///     Navis.push(context, "/home/channels");
/// }
/// ```
mixin BusinessListener<T extends StatefulWidget> on State<T> {
  BusinessService? _service;

  /// Last business seen. Each notification is compared against it: the service
  /// notifies about everything (a sign-up, the detail load) and the only thing
  /// that matters here is that the active one changed.
  String? _businessId;

  /// [businessId] was just activated, which is not the business that was active.
  ///
  /// It runs outside the `build`, synchronously with the change, so from here
  /// one can navigate or request data.
  void onBusinessChanged(String businessId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // It is read with `read` and not with `watch`: the subscription is manual
    // because what is wanted is a call when the business changes, not a rebuild
    // for every notification of the service.
    final service = context.read<BusinessService>();
    if (identical(service, _service)) return;

    _service?.removeListener(_onNotified);
    _service = service..addListener(_onNotified);
    _businessId = service.activeId;
  }

  @override
  void dispose() {
    _service?.removeListener(_onNotified);
    super.dispose();
  }

  void _onNotified() {
    final id = _service?.activeId;
    if (id == _businessId) return;

    _businessId = id;

    // Losing the business is not changing businesses: it is the sign-out, and
    // whoever triggers it handles that navigation. Notifying it would send the
    // screen moving towards something the session is about to leave behind.
    if (id == null || !mounted) return;

    onBusinessChanged(id);
  }
}
