import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

class Home extends PageBuilder {
  const Home({super.key});

  @override
  Widget build(BuildContext context) => DeviceSelector(
    phone: (context) => const _HomeBody(),
    desktop: (context) => const _HomeBody()
  );
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: Center(
      child: TextLarge(S.of(context).home)
    )
  );
}
