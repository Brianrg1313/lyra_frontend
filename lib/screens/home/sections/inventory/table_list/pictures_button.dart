import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/picture_import_service.dart';

// WIDGETS
import 'package:app/screens/modals/inventory/import_pictures/_import_pictures.dart';

/// Where the pictures the company's imports named are: "12 photos downloading", "3 photos
/// without their file", "2 photos failed", in that order of what matters now. Opens the
/// pictures panel ([showImportPictures]).
///
/// The only trace of the downloads this device takes on by itself
/// ([PictureImportService]): nothing is asked of the person while they run. Hidden when
/// nothing is pending nor failed, and where the flow does not exist (a master, no
/// `inventory.pictures`).
class PicturesButton extends StatelessWidget {
  const PicturesButton({super.key});

  /// Whether the bar carries it: asked by the bar's owner, so a hidden button leaves no gap
  /// between the actions.
  static bool shown(PictureImportService service) =>
    service.available && (!service.progress.isIdle || service.matching);

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PictureImportService>();
    final progress = service.progress;

    final busy = progress.downloading > 0 || service.draining || service.matching;
    final label = progress.downloading > 0
      ? S.of(context).import_pictures_downloading(progress.downloading)
      : progress.files > 0
        ? S.of(context).import_pictures_missing(progress.files)
        : progress.failed > 0
          ? S.of(context).import_pictures_failed(progress.failed)
          : S.of(context).import_pictures_title;

    return FeedbackButton(
      action: () => showImportPictures(context),
      height: AppSize.button,
      color: ThemeColor.of(context).surfaceOver,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      message: S.of(context).import_pictures_title,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSize.text * 1.2,
            height: AppSize.text * 1.2,
            child: busy
              ? const Loading()
              : Icon(
                  CI.image,
                  size: AppSize.text * 1.2,
                  color: progress.failed > 0 && progress.files == 0
                    ? ThemeColor.of(context).accent
                    : ThemeColor.of(context).icon
                )
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(label)
        ]
      )
    );
  }
}
