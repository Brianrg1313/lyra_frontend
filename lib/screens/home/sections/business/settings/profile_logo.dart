import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/files/image_file.dart';

// WIDGETS
import 'package:app/screens/modals/shared/crop_image/_crop_image.dart';

import './profile_header.dart';

/// The company's face: its logo, and from where it's changed.
///
/// It goes to the left of the name and tags, inside the profile's header (see
/// [BusinessProfileHeader]): it's the other half of the same presentation
/// —who the company is— and not a separate block. In its own column it forced
/// crossing the screen to know which sheet the datum being corrected belonged
/// to, and left a whole column taken up by a single image.
///
/// That it can be changed isn't explained with text: it carries the pencil
/// stuck at the bottom right, on top of the image itself. It's the same gesture
/// photos already have everywhere, and it takes up what an icon takes up
/// instead of a row.
///
/// Changing the logo is three steps and none can be skipped: the file is
/// chosen, it's framed ([CropImageModal]) and only then is it uploaded. The
/// framing is in the middle because the logo is always drawn square —in the
/// selector, here— and from a landscape photo the half has to be left out:
/// which half is the only part of all this that the backend can't resolve on
/// its own.
///
/// While uploading it covers the logo with its own loading and not the tab's:
/// the only thing changing is the image, and the rest of the sheet keeps
/// being read.
class BusinessProfileLogo extends StatefulWidget {
  const BusinessProfileLogo({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  State<BusinessProfileLogo> createState() => _BusinessProfileLogoState();
}

class _BusinessProfileLogoState extends State<BusinessProfileLogo> {
  /// Side of the logo. It's the same widget as the selector's drawn large,
  /// but not as large as when it had a column for itself: here it's measured
  /// against the name beside it, and taller than that block of text would
  /// leave the header with a gap on the side.
  static double get _size => AppSize.picture * 1.5;

  /// A logo is being uploaded. It blocks the action —two uploads at once leave
  /// the company with whichever answered last— and covers the image with the
  /// loading.
  bool _busy = false;

  /// Where changing the logo isn't offered (`CapabilityService`), it is only drawn.
  bool get _editable => CapabilityService().shows("business.settings.edit_logo");

  @override
  Widget build(BuildContext context) => _editable
    ? FeedbackButton(
        action: _change,
        message: _label(context),
        radius: AppSize.corner,
        child: _image(context, widget.profile)
      )
    : _image(context, widget.profile);

  /// The logo, with the pencil on top and the loading while the new one is
  /// uploaded.
  Widget _image(BuildContext context, BusinessProfileModel profile) => Stack(
    alignment: Alignment.center,
    children: [
      ProfilePicture(
        kind: ProfileKind.business,
        // The version that covers the side it's drawn with, not the original:
        // the logo is uploaded up to 10 MB and here it fits in a small square.
        url: profile.logo?.sized(_size.round()),
        size: _size,
        label: profile.name
      ),
      if (_busy) Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: ThemeColor.of(context).surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: const Center(child: Loading())
      )
      // The pencil disappears while uploading: the action is already in
      // progress, and offering it over the loading is offering something that
      // doesn't respond.
      else if (_editable) Positioned(
        right: AppSize.gap,
        bottom: AppSize.gap,
        child: _pen(context)
      )
    ]
  );

  /// The badge saying the image is touchable. It goes opaque and with a border
  /// because it rests on the logo: over a light photo, a loose icon isn't seen.
  Widget _pen(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.all(AppSize.gap),
      decoration: BoxDecoration(
        color: scheme.surfaceOver,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.line)
      ),
      child: Icon(CI.pen, size: AppSize.text, color: scheme.icon)
    );
  }

  /// What the action is called: loading the logo if there's none, changing it
  /// if there already is. It's the button's text and what's announced to the
  /// screen reader.
  String _label(BuildContext context) => widget.profile.logo == null
    ? S.of(context).business_logo_add
    : S.of(context).business_logo_change;

  /// Choose, frame and upload. Any of the first two steps can be abandoned
  /// —closing the system dialog or the modal— and there nothing happens: the
  /// company keeps the logo it had.
  Future<void> _change() async {
    if (_busy) return;

    final bytes = await pickImageBytes(
      label: S.of(context).business_logo_files
    );

    if (bytes == null || !mounted) return;

    // The limit is the backend's. It's measured before reading the image: a
    // 40 MB photo has to be decoded entirely into memory to crop it, and that's
    // the work not worth doing for them to reject it later.
    if (bytes.length > kImageMaxBytes) {
      FloatFlag.of(context).error(message: S.of(context).business_logo_large);
      return;
    }

    final cropped = await showModal(
      context: context,
      title: S.of(context).image_crop_title,
      builder: (BuildContext context) => CropImageModal(bytes: bytes)
    );

    // The modal was closed without accepting the framing.
    if (cropped is! Uint8List || !mounted) return;

    setState(() => _busy = true);

    // Nothing to announce when it enters: the new logo is already on screen. If
    // it failed, the error was shown by the service, so the response isn't
    // looked at.
    await _upload(cropped);

    if (!mounted) return;

    setState(() => _busy = false);
  }

  /// Uploads the crop. It travels as a file because that's how a multipart
  /// travels, and the crop was born in memory: it's written to the temp folder
  /// for as long as the upload lasts and deleted no matter what happens, even
  /// if the company changed in the meantime.
  Future<bool> _upload(Uint8List bytes) async {
    final file = await writeTempImage(bytes, name: "logo");

    try {
      if (!mounted) return false;

      return await context.read<BusinessService>().setLogo(context, file);
    } finally {
      await discardTempImage(file);
    }
  }
}
