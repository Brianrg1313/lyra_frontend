import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/assistant/assistant_service.dart';

// WIDGETS
import './assistant_composer.dart';
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

  /// Widest the thread and the composer get.
  static double get maxWidth => AppSize.picture * 16;

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  late final AssistantService _service = AssistantService(
    catalogs: [LyraCatalog.build()],
    onNavigate: Navis.navigate
  );

  final GlobalKey<AssistantComposerState> _composer = GlobalKey();

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

    return ChangeNotifierProvider<AssistantService>.value(
      value: _service,
      child: Surface(child: LayoutBuilder(builder: (context, constraints) => Selector<AssistantService, bool>(
        selector: (_, service) => service.isEmpty,
        builder: (context, empty, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Bar(onNew: _new),
            // Empty, the greeting hugs the composer from above and the
            // suggestions hold it up from below, near the middle. The first
            // message collapses them and the composer glides to the bottom:
            // the chat's one orchestrated motion.
            Expanded(child: AnimatedSwitcher(
              duration: motion ~/ 2,
              child: empty
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
        )
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
  const _Bar({required this.onNew});

  final VoidCallback onNew;

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
          Container(
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
    final turns = context.watch<AssistantService>().turns;

    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(AppSize.spaceM, 0, AppSize.spaceM, AppSize.spaceM),
      itemCount: turns.length,
      itemBuilder: (context, index) => _Centered(
        key: ValueKey(turns[index].id),
        child: AssistantTurnView(turn: turns[index])
      )
    );
  }
}
