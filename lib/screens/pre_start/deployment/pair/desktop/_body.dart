import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show defaultPort, PairingOffer;

// SERVICES
import 'package:app/toolkit/lan/_lan.dart';
import 'package:app/services/lan/lan_pairing_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';
import '../../widgets/deployment_frame.dart';
import '../widgets/qr_scanner.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// The servers mDNS found fill the address; typing one works the same (discovery is only a
/// hint, plan §5.2). The code is typed, never sent: it is the secret of the exchange. A phone
/// scans the QR instead; a browser pairs with the master that served the page, so it only
/// asks for the code.
class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();
  final _served = lanServingMaster;

  late final _host = InputController(key: "HOST", form: _form, obligatory: true, max: 253, initial: _served?.host);
  late final _port = InputController(
    key: "PORT",
    form: _form,
    type: InputType.numeric,
    max: 5,
    initial: "${_served?.port ?? defaultPort}"
  );
  late final _name = InputController(key: "NAME", form: _form, obligatory: true, max: 64, initial: lanDeviceName);
  late final _code = InputController.code(spaces: 8, form: _form);

  String? _error;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairing = context.watch<LanPairingService>();
    final scheme = ThemeColor.of(context);

    return DeploymentFrame(
      title: S.of(context).lan_pair_title,
      subtitle: S.of(context).lan_pair_subtitle,
      children: [
        if (_served != null)
          DeploymentNote(S.of(context).lan_pair_browser("${_served.host}:${_served.port}"))
        else ...[
          if (lanCanScan) ...[
            MainButton(title: S.of(context).lan_scan_button, loading: _form.loading, action: _scan),
            SizedBox(height: AppSize.spaceS),
            TextSmall(S.of(context).lan_pair_or_code, color: scheme.subtitle),
            SizedBox(height: AppSize.spaceXS),
          ],
          Row(children: [
            Expanded(child: TextSmall(
              pairing.searching
                ? S.of(context).lan_pair_searching
                : pairing.found.isEmpty ? S.of(context).lan_pair_none : S.of(context).lan_pair_found,
              lines: 2,
              color: scheme.subtitle
            )),
            if (!pairing.searching) Button(
              title: S.of(context).lan_search_again,
              width: null,
              action: pairing.search
            )
          ]),
          SizedBox(height: AppSize.spaceXS),
          for (final master in pairing.found) Padding(
            padding: EdgeInsets.only(bottom: AppSize.gap),
            child: FeedbackButton(
              width: double.infinity,
              color: scheme.surface,
              feedbackColor: scheme.surfaceOver,
              padding: EdgeInsets.all(AppSize.spaceS),
              action: () {
                _host.textController.text = master.host;
                _port.textController.text = "${master.port}";
                _code.focus.requestFocus();
              },
              child: Row(children: [
                Icon(CI.network, size: 18, color: scheme.icon),
                SizedBox(width: AppSize.gap),
                Expanded(child: TextMedium(master.name, ellipsis: true)),
                TextSmall("${master.host}:${master.port}", color: scheme.subtitle)
              ])
            )
          ),
          SizedBox(height: AppSize.spaceS),
          InputRow(children: [
            Input(placeholder: S.of(context).lan_pair_address_input, controller: _host, flex: 3, next: _port.focus),
            Input(placeholder: S.of(context).lan_pair_port_input, controller: _port, flex: 1, next: _name.focus)
          ])
        ],
        Input(placeholder: S.of(context).lan_pair_name_input, controller: _name, next: _code.focus),
        SizedBox(height: AppSize.spaceXS),
        TextSmall(S.of(context).lan_pair_code, color: scheme.subtitle),
        SizedBox(height: AppSize.gap),
        CodeInput(controller: _code, spaces: 8, onSubmit: (_) => _submit()),
        if (_error != null) DeploymentNote(_error!, error: true),
        SizedBox(height: AppSize.spaceS),
        MainButton(title: S.of(context).lan_pair_submit, loading: _form.loading, action: _submit),
        if (_served == null) ...[
          SizedBox(height: AppSize.spaceXS),
          Button(title: S.of(context).lan_other_mode, action: () => Navis.pushAndClearStack(context, "/login"))
        ]
      ]
    );
  }

  void _submit() {
    if (_form.loading.value) return;
    if (!_form.validate()) return;

    final port = int.tryParse(_port.value) ?? defaultPort;
    if (port < 1 || port > 65535) return _port.status.setStatus(InputStatus.error, InputError.invalid);

    _run(context.read<LanPairingService>().pair(host: _host.value.trim(), port: port, code: _code.value, name: _name.value.trim()));
  }

  void _scan() {
    if (_form.loading.value) return;

    final pairing = context.read<LanPairingService>();
    final name = _name.value.trim().isEmpty ? lanDeviceName : _name.value.trim();

    showModal(
      context: context,
      title: S.of(context).lan_scan_title,
      builder: (_) => QrScanner(onOffer: (PairingOffer offer) => _run(pairing.pairScanned(offer, name: name)))
    );
  }

  void _run(Future<LanPairingError?> pairing) {
    setState(() => _error = null);
    _form.loading.value = true;

    pairing.then((failure) {
      if (!mounted) return;
      _form.loading.value = false;

      if (failure == null) return Navis.pushAndClearStack(context, "/lan");

      _code.textController.clear();
      setState(() => _error = switch (failure) {
        // `locked` is the password way's (the sign in), never a code's.
        LanPairingError.wrongCode || LanPairingError.locked => S.of(context).lan_pair_wrong_code,
        LanPairingError.wrongMaster => S.of(context).lan_pair_wrong_master,
        LanPairingError.unreachable => S.of(context).lan_pair_unreachable
      });
    });
  }
}
