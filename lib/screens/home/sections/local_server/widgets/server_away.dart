import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show clientService, hybridService;
import 'package:app/services/business/business_service.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/local_server/local_server_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/server/master_password/_master_password.dart';
import 'package:app/screens/pre_start/deployment/master/desktop/_body.dart' as master;

/// The server section of a session running online without its server (plan D16): a device
/// paired with one that doesn't answer now ("try again"), or a computer with none, which
/// creates it here: the signed-in account its owner, the company the one online, its profile
/// and its link (`HybridService.companyFrom`). Either way, once the server takes the session the
/// app runs `hybrid` and the session is read again from it.
class ServerAway extends StatefulWidget {
  const ServerAway({super.key});

  @override
  State<ServerAway> createState() => _ServerAwayState();
}

class _ServerAwayState extends State<ServerAway> {
  /// Whether this computer can become a master: read once, the engine asked.
  late final Future<LocalServerStatus> _engine = Deployment.paired == null
    ? context.read<LanService>().server.refresh()
    : Future.value(LocalServerStatus.ready);

  bool _creating = false;
  final _trying = ValueNotifier(false);

  @override
  void dispose() {
    _trying.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (Deployment.paired == null) context.read<BusinessService>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_creating) return _setup(context);

    return FutureBuilder<LocalServerStatus>(
      future: _engine,
      builder: (context, engine) {
        if (!engine.hasData) return const Center(child: Loading());

        if (Deployment.paired != null) return _away(context);
        if (engine.data != LocalServerStatus.notSetUp) {
          return SectionMessage(icon: CI.network, title: S.of(context).server_cannot_host);
        }

        return _create(context);
      }
    );
  }

  Widget _frame(BuildContext context, String title, String subtitle, List<Widget> children) => ScrollableWidget(
    padding: EdgeInsets.all(AppSize.spaceM),
    children: [Align(alignment: Alignment.topLeft, child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextInter(title, multiplier: 1.8, bold: true, lines: 2),
        Padding(
          padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceM),
          child: TextMedium(subtitle, lines: 5, color: ThemeColor.of(context).subtitle)
        ),
        ...children
      ])
    ))]
  );

  static Widget _action(Widget button) =>
    Align(alignment: Alignment.centerLeft, child: SizedBox(width: 260, child: button));

  Widget _away(BuildContext context) => _frame(
    context,
    S.of(context).server_away_title,
    S.of(context).server_away_subtitle,
    [_action(MainButton(title: S.of(context).lan_retry, loading: _trying, action: _retry))]
  );

  Widget _create(BuildContext context) {
    final business = context.watch<BusinessService>();
    final profile = business.profile;
    final name = business.activeId == null ? "" : business.active.name;
    final owner = profile?.owner ?? false;

    return _frame(
      context,
      S.of(context).server_create_title,
      S.of(context).server_create_subtitle(name),
      [
        if (profile == null)
          SizedBox(height: AppSize.action, child: const Align(alignment: Alignment.centerLeft, child: Loading()))
        else if (!owner)
          TextSmall(S.of(context).server_create_owner_only(name), lines: 3, color: ThemeColor.of(context).accent)
        else
          _action(MainButton(title: S.of(context).server_create_button, action: () => setState(() => _creating = true)))
      ]
    );
  }

  Widget _setup(BuildContext context) {
    final client = clientService.client;
    final business = context.read<BusinessService>();
    final profile = business.profile;

    return master.DesktopBody(
      account: (email: client.email, firstName: client.name, lastName: client.lastName),
      company: profile == null ? null : HybridService.companyFrom(profile, business.active.id),
      onBack: () => setState(() => _creating = false),
      onDone: (password) async {
        if (await hybridService.adopt(client.email, password)) return _reenter();
        if (mounted) setState(() => _creating = false);
      }
    );
  }

  /// The server answers again: with the stored session, or this person's password on it.
  Future<void> _retry() async {
    if (_trying.value) return;
    _trying.value = true;

    var joined = await hybridService.resume();
    if (!joined && mounted && context.read<LanService>().status == LanStatus.signedOut) {
      joined = await showMasterPassword(context, login: clientService.email);
    }

    if (!mounted) return;
    _trying.value = false;
    if (joined) await _reenter();
  }

  /// The session is the server's now: read again from it, then back to this section.
  Future<void> _reenter() async {
    final page = await clientService.resolve();
    if (!mounted) return;

    Navis.pushAndClearStack(context, page ?? "/home/server");
  }
}
