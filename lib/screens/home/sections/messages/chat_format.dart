import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';

/// Dates of the messages section arrive in UTC and are written in local time,
/// in the language being read.

/// The time of a message, or of a row's last activity: the hour today, the
/// weekday within the week, the date before that.
String chatTimeLabel(BuildContext context, DateTime? at, {DateTime? now}) {
  if (at == null) return "";

  final locale = _locale(context);
  final local = at.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final days = DateTime(today.year, today.month, today.day)
    .difference(DateTime(local.year, local.month, local.day))
    .inDays;

  if (days <= 0) return DateFormat.jm(locale).format(local);
  if (days < 7) return DateFormat.E(locale).format(local);

  return DateFormat.yMd(locale).format(local);
}

/// Day and time in full, for a pause's end.
String chatDateLabel(BuildContext context, DateTime? at) {
  if (at == null) return "";

  final locale = _locale(context);
  final local = at.toLocal();

  return "${DateFormat.MMMd(locale).format(local)} · ${DateFormat.jm(locale).format(local)}";
}

/// How long a customer has been waiting.
String chatWaitLabel(BuildContext context, DateTime? since) {
  if (since == null) return "";

  final minutes = DateTime.now().difference(since.toLocal()).inMinutes;

  if (minutes < 1) return S.of(context).messages_wait_now;
  if (minutes < 60) return S.of(context).messages_wait_minutes(minutes);

  final hours = minutes ~/ 60;
  if (hours < 24) return S.of(context).messages_wait_hours(hours);

  return S.of(context).messages_wait_days(hours ~/ 24);
}

String _locale(BuildContext context) => Localizations.localeOf(context).toString();
