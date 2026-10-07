import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/inventory/product_date.dart';

/// A day of a question (`YYYY-MM-DD`, the company's calendar day) as it is
/// read: `Dec 31, 2026`, in the app's language. A calendar day is never moved
/// across zones ([ProductDate]).
String knowledgeDay(BuildContext context, String day) =>
  ProductDate.parse(day)?.short(Localizations.localeOf(context).toString()) ?? day;
