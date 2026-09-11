import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

import 'profile_block.dart';
import 'profile_field.dart';
import 'profile_incorporation.dart';
import 'profile_select.dart';

/// Who the company is on paper: its legal name, its handle, what it does,
/// which fiscal identifier it answers with and since when it exists.
///
/// It's a block like the others and not the profile's header: the name up
/// large with the legal status goes at the very top ([BusinessProfileHeader])
/// and the logo in the column beside it, and these are data read and edited
/// one by one, like the operation or contact ones.
///
/// The name is on both sides and it isn't a repetition: up top it's read whose
/// the sheet is, and here it's corrected. Same with the handle and the caption,
/// which are shown where they're loaded.
///
/// A newly created company has the name, the sector and little else: the rest
/// of the rows are drawn empty, because since `PUT /business/profile/` exists
/// they're the only place from which they're completed (see [ProfileField]).
///
/// The character sets and lengths of each datum are **the backend's**
/// (`lib/extras/rules.json`), not a similar version: what the sheet accepts
/// and the server doesn't comes back as an error that can't be corrected
/// without guessing, and what the sheet rejects and the server accepts is a
/// datum that can't be loaded.
class BusinessProfileIdentity extends StatelessWidget {
  const BusinessProfileIdentity({super.key, required this.profile});

  final BusinessProfileModel profile;

  /// The short name is the one that goes in lists and menus, so it carries no
  /// punctuation: letters (with accents and ñ), digits, spaces and dashes.
  static const _namePattern = "[A-Za-z0-9 _ñáéíóúÑÁÉÍÓÚ-]";

  /// The caption is a sentence, so it carries a sentence's punctuation: opening
  /// and closing marks, quotes, parentheses and the symbols that appear in a
  /// slogan (`&`, `%`, `+`).
  static const _captionPattern =
    "[A-Za-z0-9 .,;:!¡?¿'\"()/&%@#+=*_üÜñáéíóúÑÁÉÍÓÚ-]";

  /// Letters (with accents and diaeresis), ñ, digits and the habitual
  /// punctuation of a legal name: `Acme S.A.`, `Foo & Bar, Ltd.` It's the same
  /// set the onboarding accepts: it's the same name, written at another time.
  static const _legalNamePattern = "[A-Za-z0-9 .,&'()üÜñáéíóúÑÁÉÍÓÚ-]";

  /// The handle is for links and search, so it carries no spaces or loose
  /// punctuation. The backend stores it in lowercase: writing it in uppercase
  /// isn't an error, it's lowercased on save.
  static const _nicknamePattern = "[A-Za-z0-9._-]";

  /// Fiscal identifiers of any country: letters, digits, dots and dashes
  /// (`J-12345678-9`, `B12345678`).
  static const _taxIdPattern = "[A-Za-z0-9.-]";

  @override
  Widget build(BuildContext context) => ProfileBlock(
    title: S.of(context).business_profile_section_identity,
    fields: [
      // The short name is the only thing of the identity that can't be emptied:
      // it's what the company appears named by everywhere, and a selector row
      // without text isn't a company without a name, it's a broken row.
      ProfileField(
        icon: CI.bookmark,
        label: S.of(context).business_profile_name,
        description: S.of(context).business_profile_name_note,
        value: profile.name,
        field: BusinessField.text(
          key: "NAME",
          value: profile.name,
          pattern: _namePattern,
          min: 1,
          max: 64,
          obligatory: true
        )
      ),
      ProfileField(
        icon: CI.pen,
        label: S.of(context).business_profile_caption,
        description: S.of(context).business_profile_caption_note,
        value: profile.caption,
        field: BusinessField.text(
          key: "DESCRIPTION",
          value: profile.caption,
          pattern: _captionPattern,
          min: 1,
          max: 255
        )
      ),
      ProfileField(
        icon: CI.documents,
        label: S.of(context).business_profile_legal_name,
        description: S.of(context).business_profile_legal_name_note,
        value: profile.legalName,
        field: BusinessField.text(
          key: "LEGAL_NAME",
          value: profile.legalName,
          pattern: _legalNamePattern,
          min: 2,
          max: 160
        )
      ),
      ProfileField(
        icon: CI.user_circle,
        label: S.of(context).business_profile_nickname,
        description: S.of(context).business_profile_nickname_note,
        // Read with the at-sign and edited without it: the at-sign is how a
        // handle is written, not part of what's saved. Without a handle none
        // is written: the bare at-sign isn't a datum.
        value: profile.nickname.isEmpty ? "" : "@${profile.nickname}",
        field: BusinessField.text(
          key: "NICKNAME",
          value: profile.nickname,
          pattern: _nicknamePattern,
          min: 1,
          max: 32
        )
      ),
      // The sector is chosen from the same list the company is created with, so
      // what's chosen here reads the same on both screens.
      ProfileSelectField(
        icon: CI.store,
        label: S.of(context).business_profile_activity,
        description: S.of(context).business_profile_activity_note,
        field: BusinessField.select(
          key: "ACTIVITY_TYPE",
          value: profile.activity.value,
          options: [
            for (final activity in BusinessActivity.catalog) SelectOption(
              value: activity.value,
              placeholder: activity.label(context)
            )
          ]
        )
      ),
      ProfileField(
        icon: CI.safe_password,
        label: S.of(context).business_profile_tax_id,
        description: S.of(context).business_profile_tax_id_note,
        value: profile.taxId,
        selectable: true,
        field: BusinessField.text(
          key: "TAX_ID",
          value: profile.taxId,
          pattern: _taxIdPattern,
          min: 3,
          max: 32
        )
      ),
      // The date isn't typed straight through: it's loaded in three fields, one
      // per part (see [BusinessProfileIncorporation]). Written in full you'd
      // have to hit the backend's format, which isn't the format anyone writes
      // a date in.
      BusinessProfileIncorporation(date: profile.incorporationDate),
      // The legal status is already seen as a tag under the name; what doesn't
      // fit there is since when it's been verified, which is a datum and not a
      // state. It isn't edited: the verification process grants it.
      if (profile.verifiedDate != null) ProfileField(
        icon: CI.chack_circle,
        label: S.of(context).business_profile_verified_date,
        description: S.of(context).business_profile_verified_date_note,
        value: _date(context, profile.verifiedDate!)
      )
    ]
  );

  /// The date in the format of the app's language. It's resolved by
  /// [MaterialLocalizations] and not a custom formatter: it's the same one
  /// everything else in Flutter already uses, and it comes initialized with the
  /// languages the app declares.
  String _date(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatShortDate(value);

}
