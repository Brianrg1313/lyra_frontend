import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';

/// A table header data point that can be written from its settings: what the
/// table is called and what it stores.
///
/// It lives apart from the form because it is what the form needs to build
/// itself: the card describes the data point once —where it is read from,
/// what shape it is written with, with what key it is saved— and does not have
/// to know anything about the modal that changes it. It is the same split that
/// `BusinessField` makes with the business profile.
///
/// These are only these two on purpose. The color is chosen and not written,
/// the columns are edited in the spreadsheet itself —which is where they are
/// seen— and which table a bot reads is decided from the bot: the only thing
/// that is **written** here is text.
///
/// The value is named `title` and not `name` because that is what it is called
/// on screen (it is the title of the table, like in the create), even though
/// on the other side the key is `NAME`. That translation is done by [save] and
/// not by the card.
enum TableDetailField {
  title,
  description;

  /// What is saved today: with this the field opens filled.
  String value(TableDetailModel detail) => switch (this) {
    title => detail.name,
    description => detail.description
  };

  /// What the data point is called. It is the same text that names it in the
  /// card, in the modal title and in its errors: they are the same data point
  /// read three times.
  String label(BuildContext context) => switch (this) {
    title => S.of(context).table_settings_name,
    description => S.of(context).table_settings_description
  };

  String placeholder(BuildContext context) => switch (this) {
    title => S.of(context).table_title_placeholder,
    description => S.of(context).table_description_placeholder
  };

  /// A table without a name cannot be listed; one without a description can,
  /// and in fact almost all of them are born that way.
  bool get obligatory => this == title;

  int? get min => this == title ? 3 : null;
  int get max => this == title ? 60 : 240;

  /// The same character set the create accepts: it is the same table name,
  /// written at another time. The description filters nothing —it is free
  /// text— and so it passes with `IGNORE`.
  String get pattern => this == title
    ? "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]"
    : "IGNORE";

  /// Saves [text] as this data point. It is a **partial** write: the other
  /// data point does not travel, so correcting the description cannot stomp a
  /// rename that came in in the meantime.
  Future<bool> save(
    BuildContext context,
    TableDetailService service,
    String text
  ) => switch (this) {
    title => service.edit(context, name: text),
    description => service.edit(context, description: text)
  };
}