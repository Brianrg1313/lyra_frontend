import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import 'auth_brand.dart';
import 'auth_footer.dart';

/// What the sign in shows while our backend does not answer. A placeholder:
/// what a device without the cloud does from here is still to be decided.
class AuthOffline extends StatelessWidget {
  const AuthOffline({super.key, required this.onRetry});

  /// Asks the backend again; the sign in replaces this once it answers.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceS),
    body: Column(children: [
      Expanded(child: Center(child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSize.spaceM),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthBrand(),
              SizedBox(height: AppSize.spaceL * 2),
              TextInter(S.of(context).auth_offline_title, multiplier: 2.4, bold: true, lines: 2),
              Padding(
                padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceL),
                child: TextMedium(
                  S.of(context).auth_offline_message,
                  lines: 4,
                  color: ThemeColor.of(context).subtitle
                )
              ),
              MainButton(title: S.of(context).auth_offline_retry, action: onRetry)
            ]
          )
        )
      ))),
      const AuthFooter()
    ])
  );
}
