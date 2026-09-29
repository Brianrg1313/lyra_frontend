import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_language.dart';

// WIDGETS
import 'package:core/form.dart';

/// Bottom strip of the sign in and sign up pages: copyright, legal links and
/// the language picker.
///
/// It is meant to be read only when looked for, so everything is `TextSmall`
/// in the subtitle color and the links have no fill until hovered.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    runSpacing: AppSize.gap,
    children: [
      TextSmall(
        S.of(context).auth_footer_copyright(DateTime.now().year),
        color: ThemeColor.of(context).subtitle
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: link to the actual privacy policy page
          _FooterLink(label: S.of(context).auth_footer_privacy),
          _dot(context),
          // TODO: link to the actual terms and conditions page
          _FooterLink(label: S.of(context).auth_footer_terms),
          _dot(context),
          const _LanguageButton()
        ]
      )
    ]
  );

  Widget _dot(BuildContext context) => TextSmall(
    "·",
    color: ThemeColor.of(context).subtitle
  );
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.action, this.leading});

  final String label;
  final Widget? leading;
  final void Function()? action;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: action,
    color: ThemeColor.of(context).surface.withAlpha(0),
    feedbackColor: ThemeColor.of(context).surface,
    padding: EdgeInsets.symmetric(
      vertical: AppSize.gap,
      horizontal: AppSize.spaceXS
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) Padding(
          padding: EdgeInsets.only(right: AppSize.gap),
          child: leading
        ),
        TextSmall(label, color: ThemeColor.of(context).subtitle)
      ]
    )
  );
}

/// Switches `AppController().locale`, which rebuilds the whole app in the
/// picked language. Only the locales `S` ships are offered, so the list grows
/// by itself when an `intl_<tag>.arb` is added.
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;

    return _FooterLink(
      label: BusinessLanguage.label(current),
      leading: Icon(
        Icons.language_rounded,
        size: AppSize.text * 1.2,
        color: ThemeColor.of(context).subtitle
      ),
      action: () => _pick(context, current)
    );
  }

  Future<void> _pick(BuildContext context, String current) async {
    final picked = await showSelectMenu(
      context: context,
      selected: current,
      dense: true,
      width: 160,
      searchPlaceholder: S.of(context).auth_footer_language,
      options: [
        for (final locale in S.delegate.supportedLocales) SelectOption(
          value: locale.languageCode,
          placeholder: BusinessLanguage.label(locale.languageCode)
        )
      ]
    );

    if (picked == null || picked.value == current) return;

    AppController().locale.value = Locale(picked.value);
  }
}
