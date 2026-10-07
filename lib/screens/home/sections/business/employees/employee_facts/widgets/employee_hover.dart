import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding;

import './employee_hint.dart';

/// Tells its [builder] whether the pointer is over it, for the hints a cell
/// shows only then ([EmployeeHint]). With no mouse at all (a touch screen)
/// it always says yes: there is no hover to wait for.
class EmployeeHover extends StatefulWidget {
  const EmployeeHover({super.key, required this.builder});

  final Widget Function(BuildContext context, bool hover) builder;

  @override
  State<EmployeeHover> createState() => _EmployeeHoverState();
}

class _EmployeeHoverState extends State<EmployeeHover> {
  bool _over = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _over = true),
    onExit: (_) => setState(() => _over = false),
    child: widget.builder(context, _over || !RendererBinding.instance.mouseTracker.mouseIsConnected)
  );
}
