import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_pairing_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/lan/network_scan_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import 'auth_brand.dart';
import 'auth_frame.dart';

/// The sign in while the backend doesn't answer (plan §7.4), in the cloud sign in's frame ([AuthFrame]).
///
/// With [masters] (found by `NetworkScanService`) it signs in to one: the e-mail and password
/// pair this device first (`LanPairingService.pairWithPassword`, no code), then open the
/// session, and `/lan` takes it from there. Without masters it creates one on this computer:
/// the same two fields become its owner ([onCreate]).
///
/// Both modes are this one widget, so what was typed survives a master appearing or going away
/// while the page is open.
class AuthLan extends StatefulWidget {
  const AuthLan({super.key, required this.masters, required this.onCreate, this.pairing, this.enter});

  final List<LanFound> masters;

  /// The person asked to create the server with these as its owner.
  final void Function(String email, String password) onCreate;

  /// Injected by the tests.
  final LanPairingService? pairing;

  /// Once paired and signed in: `/lan` by default.
  final VoidCallback? enter;

  @override
  State<AuthLan> createState() => _AuthLanState();
}

class _AuthLanState extends State<AuthLan> {
  final _form = FormController();

  late final _email = InputController.email(
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).email_input),
      InputError.empty: S.of(context).form_empty_ma(S.of(context).email_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).email_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).email_input)
    }
  );

  late final _password = InputController.password(form: _form, obligatory: true);

  late final _server = InputController.select(key: "SERVER", form: _form);

  String? _error;

  bool get _create => widget.masters.isEmpty;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFrame(child: _fields(context));

  Widget _fields(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AuthBrand(),
      SizedBox(height: AppSize.spaceL * 2),
      TextInter(
        _create ? S.of(context).auth_create_title : S.of(context).auth_lan_title,
        multiplier: 2.4,
        bold: true,
        lines: 2
      ),
      Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceL),
        child: TextMedium(
          _create ? S.of(context).auth_create_subtitle : S.of(context).auth_lan_subtitle,
          lines: 4,
          color: ThemeColor.of(context).subtitle
        )
      ),
      // Two businesses can share a network; one server needs no choosing.
      if (widget.masters.length > 1)
        SelectInput(
          placeholder: S.of(context).auth_lan_server,
          controller: _server,
          searchable: false,
          options: [
            for (final master in widget.masters) SelectOption(value: _address(master), placeholder: master.name)
          ]
        ),
      Input(placeholder: S.of(context).email_input, controller: _email, next: _password.focus),
      Input(placeholder: S.of(context).password_input, controller: _password, onSubmit: _submit),
      if (_error != null)
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceXS),
          child: TextSmall(_error!, lines: 4, color: ThemeColor.of(context).accent)
        ),
      SizedBox(height: AppSize.spaceXS),
      MainButton(
        title: _create ? S.of(context).auth_create_button : S.of(context).login,
        loading: _form.loading,
        action: _submit
      ),
      SizedBox(height: AppSize.spaceXS),
      Button(
        title: S.of(context).lan_search_again,
        action: () => context.read<NetworkScanService>().scan()
      )
    ]
  );

  static String _address(LanFound master) => "${master.host}:${master.port}";

  /// Enter and the button both land here, and `Button` only blocks its own taps.
  void _submit() {
    if (_form.loading.value) return;
    if (!_email.validate(_email) || !_password.validate(_password)) return;

    if (_create) {
      // The engine's own rule (`session.md` S-2), said before the setup asks for the rest.
      if (_password.value.length < 10) return setState(() => _error = S.of(context).lan_master_weak_password);

      return widget.onCreate(_email.value.trim(), _password.value);
    }

    _signIn();
  }

  Future<void> _signIn() async {
    final scan = context.read<NetworkScanService>();
    final lan = context.read<LanService>();
    final master = widget.masters.firstWhere(
      (master) => _address(master) == _server.value,
      orElse: () => widget.masters.first
    );
    final email = _email.value.trim();
    final password = _password.value;

    setState(() => _error = null);
    _form.loading.value = true;
    // A look that changes the page now would drop the pairing half done.
    scan.hold(true);

    final failure = await (widget.pairing ?? LanPairingService())
      .pairWithPassword(host: master.host, port: master.port, login: email, password: password);

    if (!mounted) return;

    if (failure != null) {
      _form.loading.value = false;
      scan.hold(false);

      return setState(() => _error = switch (failure) {
        LanPairingError.wrongCode => S.of(context).auth_lan_wrong,
        LanPairingError.locked => S.of(context).auth_lan_locked,
        LanPairingError.wrongMaster => S.of(context).lan_pair_wrong_master,
        LanPairingError.unreachable => S.of(context).lan_pair_unreachable
      });
    }

    // Paired: this device is a LAN client now. The same password signs it in; whatever that
    // answers, `/lan` shows it (a refusal there asks for the password again).
    await lan.open();
    if (lan.status == LanStatus.signedOut) await lan.signIn(email, password);

    if (!mounted) return;
    _form.loading.value = false;

    if (widget.enter != null) return widget.enter!();
    Navis.pushAndClearStack(context, "/lan");
  }
}
