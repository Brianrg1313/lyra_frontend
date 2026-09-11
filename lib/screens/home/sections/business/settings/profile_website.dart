import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:url_launcher/url_launcher.dart';

// WIDGETS
import 'package:app/screens/modals/business/edit_business_field/_edit_business_field.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

import 'profile_field.dart';

/// The company's site: the only profile row that **leads elsewhere**.
///
/// That's why it's not drawn like the rest of the data but inside a box that
/// can be touched ([Surface.over]): a loose text in a sheet is read, not
/// touched, and nothing in the row said there was a link there. The box
/// measures what the address measures and not the column's width, so what can
/// be touched is what can be touched.
///
/// Without a site loaded there's no box: the notice that the datum is missing
/// stays, like in any other empty row. An empty box would invite touching
/// something that leads nowhere.
///
/// The address is saved as whoever loads it writes it (`ryzer.com`), so
/// opening it is completing its scheme: without it, the system doesn't know
/// it's a web page.
class BusinessProfileWebsite extends StatelessWidget {
  const BusinessProfileWebsite({super.key, required this.website});

  final String website;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: CI.link,
    label: S.of(context).business_profile_website,
    description: S.of(context).business_profile_website_note,
    action: ProfileAction(
      icon: website.isEmpty ? CI.plus : CI.edit,
      message: website.isEmpty
        ? S.of(context).business_profile_add(
            S.of(context).business_profile_website
          )
        : S.of(context).business_profile_edit(
            S.of(context).business_profile_website
          ),
      action: () => _edit(context)
    ),
    child: website.isEmpty ? _empty(context) : _link(context)
  );

  Widget _empty(BuildContext context) => TextMedium(
    S.of(context).business_profile_empty,
    color: ThemeColor.of(context).text.secondary
  );

  /// The address inside a box that opens. Aligned to the left and measuring
  /// its text: it's a button, and a button the width of the sheet doesn't read
  /// as a link but as a bar.
  Widget _link(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: FeedbackButton(
        action: () => _open(context),
        message: S.of(context).business_profile_website_open,
        radius: AppSize.cornerInset(AppSize.gap),
        color: scheme.surfaceOver,
        feedbackColor: scheme.line,
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.spaceXS,
          vertical: AppSize.gap
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: TextMedium(
              website,
              ellipsis: true,
              color: scheme.primary
            )),
            SizedBox(width: AppSize.gap),
            Icon(
              CI.link,
              size: AppSize.text,
              color: scheme.text.secondary
            )
          ]
        )
      )
    );
  }

  /// Opens the site in the system browser.
  ///
  /// That it can't be opened is announced: it's the only thing that tells a
  /// badly loaded address apart from a touch that did nothing, and whoever
  /// loaded it is the only one who can correct it.
  ///
  /// Opening is the system's business and can fail for something that isn't
  /// the address —no browser, the system denies it—, and that arrives as an
  /// exception. It's caught and told the same: what has to be known is that
  /// the site didn't open, and a bare exception from a button's touch isn't
  /// told to anyone.
  Future<void> _open(BuildContext context) async {
    bool opened = false;

    final url = Uri.tryParse(_address);

    if (url != null) {
      try {
        opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (E) {
        if (kDebugMode) {
          print("Could not open $url: $E");
        }
      }
    }

    if (opened || !context.mounted) return;

    FloatFlag.of(context).error(
      message: S.of(context).business_profile_website_failed
    );
  }

  /// The address as the system understands it. What's saved almost never
  /// carries a scheme —`ryzer.com` is loaded, which is how it's said— and
  /// without it, `Uri` reads it as a file path.
  String get _address {
    final value = website.trim();

    return value.contains("://") ? value : "https://$value";
  }

  /// Changing the site is writing, so it's done where one writes: the single
  /// field modal, same as the rest of the sheet's text data.
  Future<void> _edit(BuildContext context) => showModal(
    context: context,
    title: website.isEmpty
      ? S.of(context).business_profile_add(
          S.of(context).business_profile_website
        )
      : S.of(context).business_profile_edit(
          S.of(context).business_profile_website
        ),
    builder: (BuildContext context) => EditBusinessFieldModal(
      label: S.of(context).business_profile_website,
      field: BusinessField.text(
        key: "WEBSITE",
        value: website,
        pattern: "[A-Za-z0-9_@.:/?&=#%~+-]",
        hint: S.of(context).business_profile_website_hint,
        min: 4,
        max: 255
      )
    )
  );
}
