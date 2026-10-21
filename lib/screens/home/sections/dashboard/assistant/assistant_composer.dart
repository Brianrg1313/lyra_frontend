import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/assistant/assistant_service.dart';

// WIDGETS
import 'package:core/form.dart';

/// Where the person writes to the assistant. Enter sends; while an answer is
/// being written the send button stops it instead.
///
/// Attaching and dictating are drawn but not wired yet ("coming soon"): the
/// assistant's backend decides what it reads.
class AssistantComposer extends StatefulWidget {
  const AssistantComposer({super.key});

  @override
  State<AssistantComposer> createState() => AssistantComposerState();
}

class AssistantComposerState extends State<AssistantComposer> {
  static const int _max = 8000;

  /// Formless: the [Input] owns and disposes it.
  final InputController _controller = InputController(key: "PROMPT", max: _max);

  void focus() => _controller.focus.requestFocus();

  void _send() {
    final service = context.read<AssistantService>();
    final text = _controller.text.trim();

    if (text.isEmpty || service.busy) return;

    service.send(text);
    _controller.textController.clear();
    focus();
  }

  void _soon() => FloatFlag.of(context).message(S.of(context).assistant_soon);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final busy = context.select<AssistantService, bool>((service) => service.busy);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Input(
            controller: _controller,
            placeholder: s.assistant_composer_placeholder,
            buttonSpace: false,
            autofocus: true,
            radius: AppSize.corner,
            onSubmit: _send,
            leading: _RoundIcon(icon: CI.plus, message: s.assistant_composer_attach, action: _soon)
          )),
          SizedBox(width: AppSize.gap),
          _RoundIcon(icon: CI.microphone, message: s.assistant_composer_voice, action: _soon, filled: true),
          SizedBox(width: AppSize.gap),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller.textController,
            builder: (context, value, _) => _SendButton(
              busy: busy,
              enabled: busy || value.text.trim().isNotEmpty,
              action: busy ? context.read<AssistantService>().stop : _send
            )
          )
        ]),
        SizedBox(height: AppSize.gap * 1.4),
        TextSmall(s.assistant_disclaimer, color: scheme.text.secondary, textAlign: TextAlign.center, multiplier: 0.9)
      ]
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.message,
    required this.action,
    this.filled = false
  });

  final IconData icon;
  final String message;
  final VoidCallback action;

  /// Outside the field it needs its own fill; inside it the field's is enough.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox.square(
      dimension: filled ? AppSize.action : AppSize.button,
      child: FeedbackButton(
        action: action,
        message: message,
        radius: AppSize.action,
        color: filled ? scheme.surfaceOver : null,
        child: Center(child: Icon(icon, size: AppSize.text * 1.3, color: scheme.text.secondary))
      )
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.enabled, required this.action});

  final bool busy;
  final bool enabled;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: AppSize.action,
        height: AppSize.action,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.accent]
          ),
          boxShadow: enabled ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: AppSize.spaceXS)] : null
        ),
        child: FeedbackButton(
          action: enabled ? action : null,
          message: busy ? s.assistant_stop : s.assistant_send,
          radius: AppSize.action,
          child: Center(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              busy ? Icons.stop_rounded : CI.arrow_top,
              key: ValueKey(busy),
              size: AppSize.text * (busy ? 1.7 : 1.4),
              color: scheme.surface
            )
          ))
        )
      )
    );
  }
}
