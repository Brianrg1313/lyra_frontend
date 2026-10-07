import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_image.dart';
import 'package:app/toolkit/lan_image.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';

/// The cell of an image-type field.
///
/// **Always a square**, and of the same side in every row: a row's height minus
/// its air. The column can still be widened —it's a column like any other— but
/// the photo doesn't stretch with it: it's drawn in its square against the left
/// border and what's left over stays empty. That's what makes a photo column
/// read as an even strip: with the photo taking up the whole cell, each column
/// width would give a different crop and a vertical photo would look like a band.
///
/// What's shown is the **cover** —the first of the gallery— and not the whole
/// gallery: three photos don't fit in a sheet row, and the one that defines the
/// product is the first (see `Gallery` in the backend). The others exist just
/// the same and are loaded from the same dropdown.
///
/// And it's the thumbnail that's drawn, not the photo: the backend renders a
/// 320px one when it's uploaded ([kProductImageWidth]) and this measures forty.
/// Asking for the big one would download megabytes per row to draw a little square.
///
/// Empty it looks like an add button and not like a blank cell: it's what
/// says a photo goes there and that you put it by tapping. The whole cell opens
/// the dropdown ([SheetController.pickImage]) —[SheetCellView] handles that,
/// like in any other— so there's no tapping of its own here.
class ImageCell extends StatelessWidget {
  const ImageCell({
    super.key,
    required this.raw,
    required this.row,
    required this.column
  });

  /// The cell's stored value, as it came: the gallery's list of ids, a loose
  /// id or the address an import brought. It's read without converting it to
  /// text because a gallery **is not** text: a list's `toString()` gives
  /// `[a, b]`, which is no image.
  final dynamic raw;

  /// Which row it's in. It decides which zebra band its background belongs to,
  /// and with that the frame's fill (see [SheetStyle.frameFill]).
  final int row;

  /// Which column it's in. Together with [row] it's what lets it recognize that
  /// the current upload is its own.
  final int column;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);
    final images = ProductImage.from(raw);
    final cover = images.isEmpty ? null : images.first;

    // The square comes out of the row's height and not of its own number: the row
    // always measures the same, so the cell does too, and with `AspectRatio` there's
    // no need to manually subtract either the cell's air or the border's thickness.
    return SizedBox(
      height: double.infinity,
      child: Center(child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AspectRatio(
          aspectRatio: 1,
          child: ValueListenableBuilder<SheetCell?>(
            valueListenable: context.read<SheetController>().uploading,
            builder: (context, uploading, child) => _frame(
              context,
              sheet,
              cover,
              busy: uploading != null && uploading.at(row, column)
            )
          ))
      ))
    );
  }

  /// The frame: the photo, the loading spinner while one uploads, or the empty
  /// slot when there's none.
  Widget _frame(
    BuildContext context,
    SheetStyle sheet,
    ProductImage? cover, {
    required bool busy
  }) => Surface(
    width: double.infinity,
    height: double.infinity,
    radius: sheet.frameRadius,
    color: sheet.frameFill(row: row),
    child: busy
      ? const Center(child: Loading())
      : cover == null
        ? _empty(sheet)
        : _picture(sheet, cover)
  );

  /// The photo. It crops to the frame and fills it ([BoxFit.cover]): a product
  /// photo needn't be square, and leaving it whole would draw it tiny with two
  /// empty strips on the sides.
  Widget _picture(SheetStyle sheet, ProductImage cover) => ClipRRect(
    borderRadius: BorderRadius.circular(sheet.frameRadius),
    child: Image(
      image: mediaImage(cover.thumbnail),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // An id that no longer resolves, or an import address that
      // fell apart: it shows as a cell without a photo, which is what there is.
      errorBuilder: (context, error, stack) => _empty(sheet)
    )
  );

  /// What shows when the product has no photo: the same frame with the add
  /// icon, in gray. It's not a warning that something's missing —a photo is
  /// optional— but where to tap to put one.
  Widget _empty(SheetStyle sheet) => Center(child: Icon(
    CI.add_image,
    size: AppSize.text * 1.2,
    color: sheet.scheme.text.secondary
  ));
}
