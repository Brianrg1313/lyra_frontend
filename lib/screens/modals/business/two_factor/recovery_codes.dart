import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

import './two_factor_proof.dart';

/// The recovery codes, shown the only time the backend answers them (it keeps only their HMAC).
/// Losing them before saving is mended with a new set ([AccountSecurityService.regenerate]).
Future<void> showRecoveryCodes(BuildContext context, List<String> codes) async {
  if (codes.isEmpty) return;

  await showModal(
    context: context,
    title: S.of(context).two_factor_codes_title,
    builder: (context) => RecoveryCodesModal(codes: codes)
  );
}

class RecoveryCodesModal extends StatelessWidget {
  const RecoveryCodesModal({super.key, required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: TwoFactorCode.width, maxWidth: TwoFactorCode.width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(s.two_factor_codes_subtitle, lines: 4, color: scheme.subtitle),
          SizedBox(height: AppSize.spaceM),
          Surface(
            color: scheme.surface,
            radius: AppSize.cornerInset(AppSize.gap),
            padding: EdgeInsets.all(AppSize.spaceS),
            child: Wrap(
              spacing: AppSize.spaceS,
              runSpacing: AppSize.gap,
              children: [
                for (final code in codes)
                  SizedBox(
                    // Two per row: a column of codes reads as a list to tick off, one by one.
                    width: (TwoFactorCode.width - AppSize.spaceS * 3) / 2,
                    child: TextMedium(code, selectable: true, bold: true, textAlign: TextAlign.center)
                  )
              ]
            )
          ),
          SizedBox(height: AppSize.spaceM),
          Button(
            title: s.two_factor_codes_copy,
            leftIcon: Icon(CI.copy, size: AppSize.text * 1.2, color: scheme.text.secondary),
            action: () async {
              await Clipboard.setData(ClipboardData(text: codes.join("\n")));
              if (context.mounted) FloatFlag.of(context).message(s.two_factor_codes_copied);
            }
          ),
          SizedBox(height: AppSize.spaceXS),
          MainButton(title: s.two_factor_codes_done, action: () => Navigator.pop(context))
        ]
      )
    );
  }
}
