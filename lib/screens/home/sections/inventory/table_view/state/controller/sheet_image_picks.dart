part of '../sheet_controller.dart';

/// The dropdown of an image cell (see, upload, remove) and the cells written
/// by a gesture rather than typed (an option, a generated SKU).
extension SheetImagePicks on SheetController {
  /// Opens the dropdown of an image cell, anchored to the cell ([anchor] is
  /// its context).
  ///
  /// It's the equivalent of [pickOption] for photos, and that's why it's a
  /// dropdown and not an editor: an image isn't written. What's chosen isn't
  /// a value but **what to do with it** —see it, load one, remove it— because
  /// the cell's datum isn't something someone can type.
  ///
  /// The options depend on what the cell has: seeing and removing only appear
  /// if there's a photo, because offering them over an empty cell is offering
  /// two things that do nothing. Choosing one from a library isn't available
  /// yet —the backend already accepts it (`FILE_ID`), what's missing is from
  /// which list to choose it— so it's shown announced and does nothing when
  /// touched.
  ///
  /// A row that isn't a record yet can't have photos: the photo is uploaded
  /// **against a product**, and the product doesn't exist yet. It's said so
  /// instead of opening a dropdown where everything would be off.
  Future<void> pickImage(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    if (anchor == null || !anchor.mounted) return;

    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    if (draftIndex(cell.row) >= 0) {
      FloatFlag.of(anchor).error(
        message: S.of(anchor).product_table_view_image_unsaved
      );
      return;
    }

    final slot = columns.slotAt(cell.column);
    final images = ProductImage.from(service.rowAt(cell.row)?.at(slot));
    final cover = images.isEmpty ? null : images.first;

    final picked = await showSelectMenu(
      context: anchor,
      options: [
        if (cover != null) SelectOption(
          value: _kImageView,
          placeholder: S.of(anchor).product_table_view_image_view,
          icon: CI.eye
        ),
        SelectOption(
          value: _kImageUpload,
          placeholder: S.of(anchor).product_table_view_image_upload,
          icon: CI.add_image
        ),
        SelectOption(
          value: _kImageLibrary,
          placeholder: S.of(anchor).product_table_view_image_library,
          subtitle: S.of(anchor).coming_soon,
          icon: CI.image
        ),
        if (cover != null) SelectOption(
          value: _kImageRemove,
          placeholder: S.of(anchor).product_table_view_image_remove,
          icon: CI.trash
        )
      ],
      // Hangs from a cell, which measures one row: with the usual size —a form
      // field's— four options would cover half the spreadsheet.
      dense: true
    );

    if (_disposed || picked == null || !anchor.mounted) return;

    switch (picked.value) {
      case _kImageView:
        await showImageViewer(anchor, url: cover!.url);
      case _kImageUpload:
        await _uploadImage(cell, anchor, slot);
      case _kImageRemove:
        await _removeImage(cell, anchor, slot, cover!);
      // The library isn't available yet: the option is shown announced and does
      // nothing.
      default:
        break;
    }
  }

  /// Picks a photo from the disk and uploads it to the cell.
  ///
  /// The weight is measured **before** uploading anything: the limit is the
  /// backend's multipart one, so going over it is a rejection on the other
  /// side and saying it here saves the whole trip.
  ///
  /// It's not cropped, unlike a company's logo: a logo is always drawn square
  /// and one has to decide which half of a landscape photo is seen, but a
  /// product photo is saved as it is and the cell frames it on its own (see
  /// [ImageCell]). What's uploaded is what was chosen.
  Future<void> _uploadImage(
    SheetCell cell,
    BuildContext anchor,
    int slot
  ) async {
    final bytes = await pickImageBytes(
      label: S.of(anchor).product_table_view_image_files
    );

    if (bytes == null || _disposed) return;

    if (bytes.length > kImageMaxBytes) {
      if (anchor.mounted) {
        FloatFlag.of(anchor).error(
          message: S.of(anchor).product_table_view_image_large
        );
      }
      return;
    }

    // The upload travels as multipart and that asks for a file, not a block
    // of memory: it's left in the temp folder for as long as it lasts and
    // deleted no matter what happens.
    final file = await writeTempImage(bytes, name: "product");

    uploading.value = cell;

    try {
      await service.addImage(
        _context(),
        row: cell.row,
        slot: slot,
        file: file
      );
    } finally {
      await discardTempImage(file);
      if (!_disposed) uploading.value = null;
    }
  }

  /// Removes the cover from the cell.
  ///
  /// They're two different removals depending on whose the photo is, and it
  /// has to be told apart: the one this platform stores is removed against
  /// the backend, which also deletes the bytes when no other product shows
  /// them; an address that arrived in an import isn't a file of ours —there's
  /// nothing to delete— so the cell is emptied, which is what that column
  /// stores.
  Future<void> _removeImage(
    SheetCell cell,
    BuildContext anchor,
    int slot,
    ProductImage cover
  ) async {
    if (!cover.isStored) {
      _writeOption(cell, "");
      return;
    }

    await service.removeImage(
      _context(),
      row: cell.row,
      slot: slot,
      fileId: cover.id
    );
  }

  /// Saves the chosen option in the cell, through the same path as the text
  /// that's written: to the draft if the row is still being put together, and
  /// as a correction of the record if it's already a row of the table.
  void _writeOption(SheetCell cell, String value) {
    final index = draftIndex(cell.row);

    if (index >= 0) {
      drafts.choose(index, columns.slotAt(cell.column), value);
      return;
    }

    finishRecord(cell, value, before: valueOf(cell));
  }

  /// Builds a random SKU and saves it in [cell].
  ///
  /// In a record it's one more correction, like choosing an option from a
  /// list ([_writeOption]). In one of the blank rows below, besides, **it
  /// creates it on the spot**: it doesn't wait for the cursor to leave the
  /// row, which is what creates the record when the row is written by hand
  /// ([_leaveRow]).
  ///
  /// It's the exception to that rule and it has to be. Tapping the button is
  /// a complete gesture —nothing stays half-written after it, like it would
  /// stay after a letter— and on top of that it's tapped without entering the
  /// row: the button eats the cell's tap, so the cursor was never there and
  /// will never leave from there. Without this the row would stay with its
  /// code set and without a record until someone touches it for another
  /// reason, which is exactly what used to happen.
  void generateSku(SheetCell cell) {
    final index = draftIndex(cell.row);

    _writeOption(cell, nextSku());

    if (index < 0) return;

    // The editor can be open in another cell of this same row. It's closed
    // before the creation so what was typed goes into the draft —and travels
    // with it— and doesn't stay editing a row that in an instant is going to
    // be a record: on closing it would send again there, already as a
    // correction, what was just saved.
    if (cursor.editing && cursor.cell?.row == cell.row) close();

    _queueDraft(drafts.at(index));
  }
}
