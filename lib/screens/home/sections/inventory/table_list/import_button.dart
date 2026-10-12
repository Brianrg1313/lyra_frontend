import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

/// Secondary action of the list bar: import an already existing table.
///
/// It's a [FeedbackButton] and not a [Button] so it doesn't visually compete
/// with the main action, which is create.
///
/// While [loading] is `true` the icon is swapped for a spinner and the button
/// doesn't respond: uploading the file can take a while, and without this
/// notice the only trace that something is happening would be the table
/// appearing a while later. It listens to that value and doesn't receive it as
/// a `bool` so starting and finishing the upload doesn't rebuild the whole bar,
/// just like the search box next to it.
///
/// It turns off as soon as the table exists, not when the import ends: what
/// follows (the column types and the rows) takes a good half minute, happens
/// with the table already in the list and shows in its row. Leaving the button
/// off all that time would prevent importing the second spreadsheet while the
/// first settles.
class ImportButton extends StatelessWidget {
  const ImportButton({super.key, required this.action, required this.loading});

  final void Function() action;
  final ValueListenable<bool> loading;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: loading,
    builder: (context, busy, _) => FeedbackButton(
      // No action while uploading: a second parallel import would create
      // another table with the same file.
      action: busy ? null : action,
      mouseCursor: busy ? SystemMouseCursors.wait : null,
      height: AppSize.button,
      color: ThemeColor.of(context).surfaceOver,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      message: S.of(context).import_table,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSize.text * 1.2,
            height: AppSize.text * 1.2,
            child: busy
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ThemeColor.of(context).icon
                )
              : Icon(
                  Icons.file_upload_outlined,
                  size: AppSize.text * 1.2,
                  color: ThemeColor.of(context).icon
                )
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(S.of(context).import_table)
        ]
      )
    )
  );
}
