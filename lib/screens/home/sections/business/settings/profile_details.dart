import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_language.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

import 'profile_block.dart';
import 'profile_danger.dart';
import 'profile_header.dart';
import 'profile_emails.dart';
import 'profile_field.dart';
import 'profile_id.dart';
import 'profile_identity.dart';
import 'profile_phone.dart';
import 'profile_select.dart';
import 'profile_website.dart';

/// The company's profile: everything it has **loaded**, grouped by what it
/// answers —who it is on paper, how it operates, how it's contacted, and which
/// account it hangs from— and in a single top-to-bottom thread.
///
/// It starts by saying whose everything that follows is —the logo, and beside
/// it the name up large with the legal status and whether the company belongs
/// to whoever is looking— and only then the data begin (see
/// [BusinessProfileHeader]).
///
/// Nearly the whole profile is optional. What **is edited** is drawn the same
/// when it's not loaded —the empty row is the only place from which it's
/// loaded (see [ProfileField])—; what the platform writes and isn't touched
/// from here disappears when it's missing, because that row would offer
/// nothing. A block that runs out of rows isn't drawn either. A half-filled
/// profile looks short, not broken or full of dashes.
class BusinessProfileDetails extends StatelessWidget {
  const BusinessProfileDetails({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  Widget build(BuildContext context) {
    // The groups that can run out of data. Identity isn't in the list because
    // it can't: the sector always comes.
    final optional = <ProfileBlock>[
      ProfileBlock(
        title: S.of(context).business_profile_section_operation,
        fields: _operation(context)
      ),
      ProfileBlock(
        title: S.of(context).business_profile_section_contact,
        fields: _contact(context)
      ),
      // This block is always drawn, even if the company has no address: it's
      // the only place from which the first one is added.
      ProfileBlock(
        title: S.of(context).business_profile_section_emails,
        fields: _emails(context),
        action: const ProfileEmailAdd()
      ),
      ProfileBlock(
        title: S.of(context).business_profile_section_account,
        fields: _account(context)
      )
    ];

    final blocks = <Widget>[
      Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: BusinessProfileHeader(profile: profile),
      ),
      Separator.horizontal(),
      BusinessProfileIdentity(profile: profile),
      ...optional.where((block) => block.fields.isNotEmpty),
      // Deleting the company goes at the very end and only for whoever created
      // it: it's the only thing on the sheet that can't be undone, and it's
      // not one more datum (see [BusinessProfileDanger]).
      if (profile.owner) BusinessProfileDanger(profile: profile)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: AppSize.padding),
          blocks[i]
        ]
      ]);
  }

  /// How it operates: in what language and with which currencies it works.
  ///
  /// The currency doesn't come from a list written here but from the catalog
  /// that `/init` brings ([CurrencyCatalogService]): the platform enables a
  /// currency on the backend side and this sheet offers it without shipping a
  /// version of the app. That's why it's watched and not read once: if the
  /// catalog is re-read with the sheet open, the list rebuilds by itself.
  ///
  /// **Where the business is isn't here.** The street address and the country
  /// are read and edited in the location tab, with the city, the postal code
  /// and the map point, because they are one fact and not five: a business that
  /// moved says so once, in one form. This sheet is who the business *is*.
  List<Widget> _operation(BuildContext context) => [
    ProfileSelectField(
      icon: CI.chat,
      label: S.of(context).business_profile_language,
      description: S.of(context).business_profile_language_note,
      field: BusinessField.select(
        key: "LANGUAGE",
        value: profile.language,
        options: [
          for (final language in BusinessLanguage.values) SelectOption(
            value: language.tag,
            placeholder: language.name
          ),
          // What's saved may not be any of the catalog's: it carries a region
          // (`es-ve`) or it's a language this version doesn't offer yet. It's
          // added as one more option so the list shows what the company has
          // and not an empty field; choosing something else replaces it.
          if (profile.language.isNotEmpty &&
              BusinessLanguage.values.every((l) => l.tag != profile.language))
            SelectOption(
              value: profile.language,
              placeholder: BusinessLanguage.label(profile.language)
            )
        ]
      )
    ),
    _currency(context),
    // The secondaries are a list and not a single datum: choosing several isn't
    // what this form does, so for now they're read and changed where the
    // company's currencies are configured.
    if (profile.currencies.isNotEmpty) ProfileField(
      icon: CI.list,
      label: S.of(context).business_profile_currencies,
      description: S.of(context).business_profile_currencies_note,
      value: profile.currencies.join(" · ")
    )
  ];

  /// The currency it invoices in, chosen among the ones the platform has
  /// enabled.
  ///
  /// The option carries the code and, below it, the symbol and the name: the
  /// code is the data and the symbol is what this company's prices are
  /// recognized by elsewhere in the app.
  ///
  /// Without a catalog it falls to a three-letter text field, for the same
  /// reason as the country: it's better to type the code by hand than to not
  /// be able to change the currency.
  Widget _currency(BuildContext context) {
    final catalog = context.watch<CurrencyCatalogService>();

    if (!catalog.isReady) {
      return ProfileField(
        icon: CI.wallet,
        label: S.of(context).business_profile_currency,
        description: S.of(context).business_profile_currency_note,
        value: profile.currency,
        field: BusinessField.text(
          key: "CURRENCY",
          value: profile.currency,
          pattern: "[A-Za-z]",
          min: 3,
          max: 3
        )
      );
    }

    return ProfileSelectField(
      icon: CI.wallet,
      label: S.of(context).business_profile_currency,
      description: S.of(context).business_profile_currency_note,
      field: BusinessField.select(
        key: "CURRENCY",
        value: profile.currency,
        options: [
          for (final currency in catalog.currencies) SelectOption(
            value: currency.code,
            placeholder: currency.code,
            subtitle: currency.name.isEmpty
              ? currency.symbol
              : "${currency.symbol} · ${currency.name}"
          ),
          // Same as with the country: the saved currency may have been
          // disabled, and hiding it would leave the list without what the
          // company has today.
          if (profile.currency.isNotEmpty &&
              catalog.byCode(profile.currency) == null)
            SelectOption(
              value: profile.currency,
              placeholder: profile.currency,
              subtitle: profile.currency
            )
        ]
      )
    );
  }

  /// How it's contacted, without the emails: those are a list and have their
  /// own block.
  ///
  /// Both are drawn even when empty, like the identity ones and for the same
  /// reason: they're data that get edited, and this row is the only place from
  /// which they're loaded. Hidden, a company that never loaded its site had no
  /// way to load it —which is the situation of **all** of them as soon as the
  /// datum exists—.
  List<Widget> _contact(BuildContext context) => [
    BusinessProfilePhone(phone: profile.phone, country: profile.country),
    BusinessProfileWebsite(website: profile.website)
  ];

  /// The company's addresses, the primary first (the backend orders them).
  ///
  /// With none left there's an empty row and not a loose notice: the block is
  /// drawn the same —a company without emails is precisely the one that has to
  /// be able to load one— and a gray line of text in the place where the rest
  /// of the groups have data reads as the list not having loaded. The row says
  /// which datum it's about and that it isn't there, like any other unfilled
  /// field; with what to load it in the block's title ([ProfileEmailAdd]),
  /// because adding belongs to the list and not to this row.
  List<Widget> _emails(BuildContext context) {
    if (profile.emails.isEmpty) {
      return [ProfileField(
        icon: CI.mail,
        label: S.of(context).business_email_address,
        description: S.of(context).business_email_empty,
        value: ""
      )];
    }

    return [
      for (final email in profile.emails) ProfileEmailField(email: email)
    ];
  }

  /// Which account it hangs from: the identifier the backend names it with and
  /// since when it's been registered. Neither is edited: the platform sets
  /// them.
  List<Widget> _account(BuildContext context) => [
    BusinessProfileId(id: profile.id),
    if (profile.date != null) ProfileField(
      icon: CI.calendar,
      label: S.of(context).business_profile_created,
      value: MaterialLocalizations.of(context).formatShortDate(profile.date!)
    )
  ];
}
