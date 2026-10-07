import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_link.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_offline.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon_list.dart';
import 'package:app/screens/modals/business/create_password/_create_password.dart';
import 'package:app/screens/modals/business/two_factor/_two_factor.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Password and second factor, over [AccountSecurityService] (provided by `OwnSettings`). The
/// cloud account's: without the cloud each row says so.
class OwnSecurity extends StatelessWidget {
  const OwnSecurity({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final online = CapabilityService().shows("account.security");

    return !online
      ? SettingsList(rows: [
          OwnOffline(icon: CI.key, label: s.account_password),
          OwnOffline(icon: CI.safe_password, label: s.account_two_factor)
        ])
      : const _SecurityRows();
  }
}

class _SecurityRows extends StatelessWidget {
  const _SecurityRows();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final service = context.watch<AccountSecurityService>();
    final twoFactor = service.twoFactor;

    final factor = switch (service.status) {
      AccountSecurityStatus.ready => SettingsRow(
        icon: CI.safe_password,
        label: s.account_two_factor,
        hint: s.account_two_factor_hint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SettingsTag(
                label: switch (twoFactor.method) {
                  TwoFactorMethod.app => s.account_two_factor_app,
                  TwoFactorMethod.email => s.account_two_factor_email,
                  null => s.account_two_factor_off
                },
                icon: twoFactor.enabled ? CI.check : null,
                color: twoFactor.enabled ? scheme.chart.good : scheme.text.secondary
              )
            ),
            SizedBox(height: AppSize.spaceXS),
            Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, children: [
              OwnLink(
                label: twoFactor.enabled ? s.account_two_factor_change : s.account_two_factor_turn_on,
                action: () => showTwoFactorSetup(context, service: service, email: _email(context))
              ),
              if (twoFactor.enabled)
                OwnLink(label: s.account_two_factor_turn_off, danger: true, action: () => _turnOff(context, service))
            ])
          ]
        )
      ),
      AccountSecurityStatus.error => SettingsRow(
        icon: CI.safe_password,
        label: s.account_two_factor,
        child: Row(children: [
          Expanded(child: TextSmall(s.account_security_error, lines: 2, color: scheme.text.secondary)),
          OwnLink(label: s.account_retry, action: service.load)
        ])
      ),
      _ => SettingsRow(
        icon: CI.safe_password,
        label: s.account_two_factor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(dimension: AppSize.text * 1.4, child: Loading(color: scheme.primary))
        )
      )
    };

    return SettingsList(rows: [
      SettingsRow(
        icon: CI.key,
        label: s.account_password,
        hint: service.hasPassword ? s.account_password_change_soon : null,
        child: service.hasPassword
          ? TextMedium(s.account_password_set, lines: 2)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextMedium(s.account_password_unknown, lines: 2),
                SizedBox(height: AppSize.gap),
                OwnLink(label: s.account_password_create, action: () => _createPassword(context, service))
              ]
            )
      ),
      factor,
      if (twoFactor.method == TwoFactorMethod.app)
        SettingsRow(
          icon: CI.documents,
          label: s.account_recovery_codes,
          hint: s.account_recovery_hint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                s.account_recovery_left(twoFactor.recoveryLeft ?? 0),
                color: (twoFactor.recoveryLeft ?? 0) <= 2 ? scheme.chart.warning : null
              ),
              SizedBox(height: AppSize.gap),
              OwnLink(label: s.account_recovery_new, action: () => _regenerate(context, service))
            ]
          )
        ),
      OwnSoonList(rows: [
        OwnSoon(icon: CI.sms, label: s.account_sms, hint: s.account_sms_hint),
        OwnSoon(icon: CI.mail, label: s.account_recovery_emails, hint: s.account_recovery_emails_hint)
      ])
    ]);
  }

  static String _email(BuildContext context) {
    final client = context.read<ClientService>();
    return client.isAuthenticated ? client.client.email : "";
  }

  Future<void> _createPassword(BuildContext context, AccountSecurityService service) async {
    if (await showCreatePassword(context, service) && context.mounted) {
      FloatFlag.of(context).message(S.of(context).account_password_created);
    }
  }

  Future<void> _turnOff(BuildContext context, AccountSecurityService service) async {
    final method = service.twoFactor.method;
    if (method == null) return;

    final s = S.of(context);
    final confirmed = await showAlertModal(
      context: context,
      title: s.two_factor_off_title,
      message: s.two_factor_off_body,
      confirmText: s.account_two_factor_turn_off,
      cancelText: s.cancel
    );
    if (!confirmed || !context.mounted) return;

    final proof = await showTwoFactorProof(context, method);
    if (proof == null || !context.mounted) return;

    try {
      await service.disable(proof);
      if (context.mounted) FloatFlag.of(context).message(s.two_factor_turned_off);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  Future<void> _regenerate(BuildContext context, AccountSecurityService service) async {
    final proof = await showTwoFactorProof(context, TwoFactorMethod.app);
    if (proof == null || !context.mounted) return;

    try {
      final codes = await service.regenerate(proof);
      if (!context.mounted) return;

      FloatFlag.of(context).message(S.of(context).two_factor_codes_renewed);
      await showRecoveryCodes(context, codes);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }
}
