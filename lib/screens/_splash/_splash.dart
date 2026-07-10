import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

class Splash extends PageBuilder {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Loading()
  );
}
