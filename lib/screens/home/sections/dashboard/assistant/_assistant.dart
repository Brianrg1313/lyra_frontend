import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/assistant/assistant_service.dart';
import 'package:app/services/assistant/sources/assistant_demo_source.dart';
import 'package:app/services/assistant/sources/assistant_source.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import './assistant_composer.dart';
import './assistant_confirm.dart';
import './assistant_orb.dart';
import './assistant_turn_view.dart';
import './assistant_welcome.dart';
import './catalog/lyra_catalog.dart';

/// **The assistant's chat**, the home's main panel.
///
/// Owns its [AssistantService] (a business switch remounts the home and with
/// it a new chat). The thread and the composer share one centred column of a
/// readable width, as the big chat apps do: on a wide window an answer is
/// still a line the eye can follow.
class AssistantPanel extends StatefulWidget {
  const AssistantPanel({super.key});

  /// What the panel answers from instead of the cloud, in tests.
  @visibleForTesting
  static AssistantSource? sourceOverride;

  /// Widest the thread and the composer get.
  static double get maxWidth => AppSize.picture * 16;

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  /// A debug build run with `--dart-define=LYRA_ASSISTANT_DEMO=true` answers
  /// from the preview source: the catalog without a model run (each is billed).
  static const bool _demo = kDebugMode && bool.fromEnvironment("LYRA_ASSISTANT_DEMO");

  late final AssistantSource? _override = AssistantPanel.sourceOverride ?? (_demo ? AssistantDemoSource() : null);

  late final AssistantService _service = AssistantService(
    catalogs: [LyraCatalog.build()],
    source: _override,
    onNavigate: Navis.navigate,
    live: _override == null
  );

  final GlobalKey<AssistantComposerState> _composer = GlobalKey();

  /// The assistant runs on the cloud (the harness): a master's install alone
  /// has none.
  bool get _available => _override != null || CapabilityService().cloudServices;

  @override
  void initState() {
    super.initState();
    if (_available) _load();
  }

  Future<void> _load() async {
    await _service.load();
    if (!mounted || _service.status != AssistantStatus.error) return;

    FloatFlag.of(context).error(message: S.of(context).assistant_load_failed);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _ask(String prompt) {
    _service.send(prompt);
    _composer.currentState?.focus();
  }

  void _new() {
    _service.clear();
    _composer.currentState?.focus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final motion = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 520);

    if (!_available) {
      return Surface(child: SectionMessage(
        icon: CI.cloud_disconected,
        title: S.of(context).assistant_offline_title,
        subtitle: S.of(context).assistant_offline_message
      ));
    }

    return ChangeNotifierProvider<AssistantService>.value(
      value: _service,
      child: Surface(child: LayoutBuilder(builder: (context, constraints) => Selector<AssistantService, (bool, bool)>(
        selector: (_, service) => (service.isEmpty, service.status == AssistantStatus.loading),
        builder: (context, state, _) {
          final (blank, loading) = state;
          // While the conversation is read, neither the greeting nor the
          // suggestions: an open thread would replace them a moment later.
          final empty = blank && !loading;

          return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Bar(onNew: _new, preview: _demo),
            // Empty, the greeting hugs the composer from above and the
            // suggestions hold it up from below, near the middle. The first
            // message collapses them and the composer glides to the bottom:
            // the chat's one orchestrated motion.
            Expanded(child: AnimatedSwitcher(
              duration: motion ~/ 2,
              child: loading && blank
                ? const Center(key: ValueKey("loading"), child: Loading())
                : empty
                  ? const Align(key: ValueKey("greeting"), alignment: Alignment.bottomCenter, child: AssistantGreeting())
                  : const _Thread(key: ValueKey("thread"))
            )),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.spaceM),
              child: _Centered(child: AssistantComposer(key: _composer))
            ),
            AnimatedContainer(
              duration: motion,
              curve: Curves.easeInOutCubic,
              height: empty ? constraints.maxHeight * 0.36 : 0,
              child: ClipRect(child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(AppSize.spaceM, AppSize.spaceS, AppSize.spaceM, 0),
                child: AnimatedOpacity(
                  duration: motion ~/ 3,
                  opacity: empty ? 1 : 0,
                  child: _Centered(child: AssistantSuggestions(onAsk: _ask))
                )
              ))
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSize.spaceM, AppSize.gap * 1.6, AppSize.spaceM, AppSize.spaceS),
              child: TextSmall(S.of(context).assistant_disclaimer, color: scheme.text.secondary, textAlign: TextAlign.center, multiplier: 0.9)
            )
          ]
          );
        }
      )))
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AssistantPanel.maxWidth),
      child: child
    )
  );
}

/// The panel's top: who it is and a new chat once there is one.
class _Bar extends StatelessWidget {
  const _Bar({required this.onNew, required this.preview});

  final VoidCallback onNew;

  /// Answering from the preview source: the tag says nothing is real.
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final service = context.watch<AssistantService>();

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSize.spaceS, AppSize.spaceXS, AppSize.spaceXS, 0),
      child: SizedBox(
        height: AppSize.action,
        child: Row(children: [
          AssistantOrb(size: AppSize.text * 1.6, active: service.busy),
          SizedBox(width: AppSize.spaceXS),
          TextMedium(s.assistant_name, bold: true, multiplier: 1.15),
          SizedBox(width: AppSize.gap * 1.4),
          if (preview) Container(
            padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.4, vertical: AppSize.gap * 0.4),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSize.corner)
            ),
            child: TextSmall(s.assistant_preview, color: scheme.primary, bold: true, multiplier: 0.85)
          ),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: service.isEmpty ? 0 : 1,
            child: IgnorePointer(
              ignoring: service.isEmpty,
              child: FeedbackButton(
                action: onNew,
                message: s.assistant_new_chat,
                radius: AppSize.cornerInset(AppSize.gap),
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap * 1.2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(CI.edit, size: AppSize.text * 1.1, color: scheme.text.secondary),
                  SizedBox(width: AppSize.gap),
                  TextMedium(s.assistant_new_chat, color: scheme.text.secondary)
                ])
              )
            )
          )
        ])
      )
    );
  }
}

/// The turns, newest at the bottom. Follows the answer while it is written,
/// unless the person scrolled up to read something else.
class _Thread extends StatefulWidget {
  const _Thread({super.key});

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final ScrollController _scroll = ScrollController();
  late final AssistantService _service = context.read<AssistantService>();

  /// How close to the end still counts as "at the end".
  double get _slack => AppSize.picture * 2;

  bool _following = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _service.addListener(_onChange);
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    _following = position.maxScrollExtent - position.pixels <= _slack;
  }

  void _onChange() {
    if (!_following) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AssistantService>();
    final turns = service.turns;
    final pending = service.pending;

    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(AppSize.spaceM, 0, AppSize.spaceM, AppSize.spaceM),
      // What waits for a yes goes last: it is what the latest answer asked.
      itemCount: turns.length + pending.length,
      itemBuilder: (context, index) => index < turns.length
        ? _Centered(key: ValueKey(turns[index].id), child: AssistantTurnView(turn: turns[index]))
        : _Centered(
            key: ValueKey("pending_${pending[index - turns.length].id}"),
            child: AssistantConfirm(pending: pending[index - turns.length])
          )
    );
  }
}
