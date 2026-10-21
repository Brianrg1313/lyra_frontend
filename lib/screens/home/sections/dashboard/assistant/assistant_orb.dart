import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The assistant's mark: a sphere of the theme's primary and accent turning
/// slowly. [active] (thinking or writing) turns it faster and makes it
/// breathe, the one sign of life the chat needs besides the text itself.
class AssistantOrb extends StatefulWidget {
  const AssistantOrb({super.key, required this.size, this.active = false});

  final double size;
  final bool active;

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9)
  )..repeat();

  @override
  void didUpdateWidget(AssistantOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;

    // Same phase, another pace: restarting would jump the gradient.
    final value = _spin.value;
    _spin.duration = Duration(milliseconds: widget.active ? 2400 : 9000);
    _spin
      ..value = value
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final colors = [scheme.primary, scheme.accent, scheme.chart.at(2), scheme.primary];

    return RepaintBoundary(child: AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        final turn = _spin.value * math.pi * 2;
        final breath = widget.active ? 1 + math.sin(turn * 2) * 0.05 : 1.0;

        return Transform.scale(
          scale: breath,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: colors, transform: GradientRotation(turn)),
              boxShadow: [BoxShadow(
                color: scheme.primary.withValues(alpha: widget.active ? 0.45 : 0.25),
                blurRadius: widget.size * (widget.active ? 0.6 : 0.4)
              )]
            ),
            // The shading stays put while the colours turn under it: reads as a sphere.
            child: DecoratedBox(decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 1,
                colors: [scheme.accent.withValues(alpha: 0), scheme.primary.withValues(alpha: 0.55)]
              )
            ))
          )
        );
      }
    ));
  }
}
