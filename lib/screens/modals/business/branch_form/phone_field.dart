import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/country_model.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/country_flag.dart';

/// A branch's phone: one box with the company's flag and code in front, and
/// the number typed after them.
///
/// The code is not chosen: every branch is in the company's country, so its
/// phone carries that code and asking for it again is one more way to get it
/// wrong. It sits inside the number's own box, with the flag, which is how a
/// code is recognized — a box of its own read as a field that could be opened.
///
/// Without [country] (the company has none with a code, or the saved phone
/// carries another one) the phone is written whole, and the flag in front is
/// the one of the code being typed, once the catalog knows it.
class BranchPhoneField extends StatelessWidget {
  const BranchPhoneField({
    super.key,
    required this.controller,
    required this.country
  });

  final InputController controller;
  final CountryModel? country;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final fixed = country;

    if (fixed != null) {
      return Input(
        title: S.of(context).business_branch_phone,
        placeholder: S.of(context).business_branch_phone_hint,
        controller: controller,
        leading: _Code(country: fixed)
      );
    }

    return ListenableBuilder(
      listenable: controller.textController,
      builder: (context, _) {
        final typed = CountryCatalogService().byPhone(controller.textController.text);

        return Input(
          title: S.of(context).business_branch_phone,
          placeholder: S.of(context).business_branch_phone_full_hint,
          controller: controller,
          leading: typed == null ? null : _Code(country: typed, dial: false),
          leftIcon: Icon(CI.phone, color: scheme.icon)
        );
      }
    );
  }
}

/// The flag and, when the code is not part of the text, the code itself, with
/// a thin line that closes them off from the number.
class _Code extends StatelessWidget {
  const _Code({required this.country, this.dial = true});

  final CountryModel country;

  /// Whether the code is drawn: a phone written whole already carries it.
  final bool dial;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(left: AppSize.padding, right: AppSize.spaceS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountryFlag(country: country),
          if (dial) ...[
            SizedBox(width: AppSize.gap),
            TextMedium(country.dial),
            SizedBox(width: AppSize.spaceS),
            // The theme's line is near invisible on a dark fill.
            Container(
              width: 1,
              height: AppSize.text,
              color: scheme.isDark ? scheme.surfaceFeedback : scheme.line
            )
          ]
        ]
      )
    );
  }
}
