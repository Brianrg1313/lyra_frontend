import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:core/images.dart';

/// The image heading a create step: one of the app's gradients with the
/// step's [icon] large in the middle, so each page is told apart at a glance
/// before reading it.
///
/// White over the gradient on purpose, not a theme colour: it sits on the
/// picture, which is the same in both themes' tones.
class StepArt extends StatelessWidget {
  const StepArt({super.key, required this.gradient, required this.icon});

  /// `gradient-1.png` … `gradient-3.png`, from the themed assets.
  final String gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ImageDynamic(gradient, fit: BoxFit.cover),
      Center(child: Container(
        width: AppSize.action * 1.8,
        height: AppSize.action * 1.8,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5)
        ),
        child: Icon(icon, size: AppSize.action * 0.8, color: Colors.white)
      ))
    ]
  );
}
