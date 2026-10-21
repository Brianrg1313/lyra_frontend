import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:genui/genui.dart' as genui;
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/assistant/assistant_service.dart';
import 'package:app/services/assistant/assistant_turn.dart';

// WIDGETS
import './assistant_markdown.dart';
import './assistant_orb.dart';

/// One turn of the thread. The person's lean right in a bubble; the
/// assistant's run the width of the column, unboxed, its mark beside them —
/// an answer is read, not chatted at.
class AssistantTurnView extends StatelessWidget {
  const AssistantTurnView({super.key, required this.turn});

  final AssistantTurn turn;

  @override
  Widget build(BuildContext context) => turn.isUser ? _UserTurn(turn: turn) : _AnswerTurn(turn: turn);
}

class _UserTurn extends StatelessWidget {
  const _UserTurn({required this.turn});

  final AssistantTurn turn;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final action = turn.action != null;

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceM),
      child: LayoutBuilder(builder: (context, constraints) => Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
            decoration: BoxDecoration(
              color: action ? null : scheme.surfaceOver,
              border: action ? Border.all(color: scheme.primary.withValues(alpha: 0.4)) : null,
              borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
            ),
            child: action
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(CI.chekmark, size: AppSize.text, color: scheme.primary),
                  SizedBox(width: AppSize.gap),
                  Flexible(child: TextMedium(S.of(context).assistant_action(turn.text), color: scheme.primary, lines: 3))
                ])
              : TextMedium(turn.text, multiplier: 1.08, selectable: true, lines: 200)
          )
        )
      ))
    );
  }
}

class _AnswerTurn extends StatelessWidget {
  const _AnswerTurn({required this.turn});

  final AssistantTurn turn;

  @override
  Widget build(BuildContext context) {
    final service = context.read<AssistantService>();

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.4),
            child: AssistantOrb(size: AppSize.text * 1.9, active: turn.isStreaming)
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (turn.isEmpty && turn.isStreaming) const _Thinking(),
              for (final part in turn.parts) Padding(
                padding: EdgeInsets.only(bottom: AppSize.spaceXS),
                child: part.isSurface
                  ? genui.Surface(
                      key: ValueKey(part.surface),
                      surfaceContext: service.surface(part.surface!)
                    )
                  : AssistantMarkdown(part.text)
              ),
              _Footer(turn: turn)
            ]
          ))
        ]
      )
    );
  }
}

/// While nothing has arrived: a word that shimmers, the orb beside it turning.
class _Thinking extends StatefulWidget {
  const _Thinking();

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking> with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400)
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.gap * 0.8, bottom: AppSize.spaceXS),
      child: AnimatedBuilder(
        animation: _shine,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [scheme.text.secondary, scheme.primary, scheme.text.secondary],
            stops: const [0, 0.5, 1],
            begin: Alignment(-3 + _shine.value * 6, 0),
            end: Alignment(-1 + _shine.value * 6, 0)
          ).createShader(bounds),
          child: child
        ),
        child: TextMedium(S.of(context).assistant_thinking, multiplier: 1.08)
      )
    );
  }
}

/// Under a closed answer: how it ended, when not normally, and copy.
class _Footer extends StatelessWidget {
  const _Footer({required this.turn});

  final AssistantTurn turn;

  @override
  Widget build(BuildContext context) {
    if (turn.isStreaming) return const SizedBox.shrink();

    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    final note = switch (turn.state) {
      AssistantTurnState.stopped => (s.assistant_stopped, scheme.text.secondary),
      AssistantTurnState.failed => (s.assistant_failed, scheme.chart.critical),
      _ => null
    };

    return Row(children: [
      if (turn.text.isNotEmpty) FocusableWidget(
        message: s.assistant_copy,
        action: () {
          Clipboard.setData(ClipboardData(text: turn.text));
          FloatFlag.of(context).message(s.assistant_copied);
        },
        child: Padding(
          padding: EdgeInsets.all(AppSize.gap),
          child: Icon(CI.copy, size: AppSize.text * 1.1, color: scheme.text.secondary)
        )
      ),
      if (note case (final text, final color)) Padding(
        padding: EdgeInsets.only(left: AppSize.gap),
        child: TextSmall(text, color: color)
      )
    ]);
  }
}
