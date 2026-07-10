// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(days) => "in ${days} days";

  static String m1(days) => "Every ${days} days";

  static String m2(day) => "Day ${day}";

  static String m3(email) => "The ${email} is empty";

  static String m4(email) => "The ${email} is incomplete";

  static String m5(email) => "The ${email} is invalid";

  static String m6(email) => "The ${email} is very long";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "a": MessageLookupByLibrary.simpleMessage("a"),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "add_new_subscription": MessageLookupByLibrary.simpleMessage(
      "Add new subscription",
    ),
    "add_subscription": MessageLookupByLibrary.simpleMessage(
      "Add subscription",
    ),
    "amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "annual": MessageLookupByLibrary.simpleMessage("Annual"),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "billing_date_custom_label": MessageLookupByLibrary.simpleMessage(
      "Date of first charge",
    ),
    "billing_date_month_label": MessageLookupByLibrary.simpleMessage("Month"),
    "billing_date_monthday_label": MessageLookupByLibrary.simpleMessage(
      "Day of the month",
    ),
    "billing_date_title": MessageLookupByLibrary.simpleMessage(
      "When do you get charged?",
    ),
    "billing_date_weekday_label": MessageLookupByLibrary.simpleMessage(
      "Day of the week",
    ),
    "billing_day": MessageLookupByLibrary.simpleMessage("Day"),
    "billing_days_left": m0,
    "billing_label_custom": m1,
    "billing_label_monthly": m2,
    "billing_period": MessageLookupByLibrary.simpleMessage("Billing period"),
    "billing_today": MessageLookupByLibrary.simpleMessage("Today"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "connectionError": MessageLookupByLibrary.simpleMessage(
      "Sorry, there was a connection error, please try again later",
    ),
    "currency": MessageLookupByLibrary.simpleMessage("Currency"),
    "currency_eur": MessageLookupByLibrary.simpleMessage("EUR"),
    "currency_local": MessageLookupByLibrary.simpleMessage("Local"),
    "currency_usd": MessageLookupByLibrary.simpleMessage("USD"),
    "custom": MessageLookupByLibrary.simpleMessage("Custom"),
    "custom_days": MessageLookupByLibrary.simpleMessage("Days"),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "dont_have_account": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account yet?",
    ),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "edit_about_title": MessageLookupByLibrary.simpleMessage(
      "Title and description",
    ),
    "edit_billing_title": MessageLookupByLibrary.simpleMessage(
      "Billing period",
    ),
    "edit_currency_title": MessageLookupByLibrary.simpleMessage(
      "Edit currency",
    ),
    "edit_price_title": MessageLookupByLibrary.simpleMessage("Edit price"),
    "email_input": MessageLookupByLibrary.simpleMessage("Email"),
    "enter_days": MessageLookupByLibrary.simpleMessage("Number of days"),
    "form_empty_ma": m3,
    "form_incomplete_ma": m4,
    "form_invalid_ma": m5,
    "form_long_ma": m6,
    "hide_keyboard": MessageLookupByLibrary.simpleMessage("Hide keyboard"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "how_often_pay": MessageLookupByLibrary.simpleMessage(
      "How often do you pay?",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "new_service": MessageLookupByLibrary.simpleMessage("New service"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "once_a_year": MessageLookupByLibrary.simpleMessage("Once a year"),
    "or_login_with": MessageLookupByLibrary.simpleMessage("or log in with:"),
    "password_input": MessageLookupByLibrary.simpleMessage("password_input"),
    "past_due": MessageLookupByLibrary.simpleMessage("Past"),
    "pending_funds": MessageLookupByLibrary.simpleMessage("Pending Payments"),
    "plan_basic": MessageLookupByLibrary.simpleMessage("Basic"),
    "plan_duo": MessageLookupByLibrary.simpleMessage("Duo"),
    "plan_family": MessageLookupByLibrary.simpleMessage("Family"),
    "plan_freemium": MessageLookupByLibrary.simpleMessage("Freemium"),
    "plan_normal": MessageLookupByLibrary.simpleMessage("Normal"),
    "plan_plus": MessageLookupByLibrary.simpleMessage("Plus"),
    "plan_pro": MessageLookupByLibrary.simpleMessage("Pro"),
    "plan_simple": MessageLookupByLibrary.simpleMessage("Simple"),
    "plan_suggestions": MessageLookupByLibrary.simpleMessage(
      "Description suggestions",
    ),
    "price_title": MessageLookupByLibrary.simpleMessage("What\'s the price?"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "search_subscription": MessageLookupByLibrary.simpleMessage(
      "Search for a subscription",
    ),
    "select_a_service": MessageLookupByLibrary.simpleMessage(
      "Select a service",
    ),
    "shop": MessageLookupByLibrary.simpleMessage("Shop"),
    "sign_in": MessageLookupByLibrary.simpleMessage("Sign in"),
    "sign_in_subtitle": MessageLookupByLibrary.simpleMessage(
      "Log in with your email address",
    ),
    "sign_up": MessageLookupByLibrary.simpleMessage("Sign up"),
    "subscription_details_delete": MessageLookupByLibrary.simpleMessage(
      "Delete subscription",
    ),
    "subscription_details_domain": MessageLookupByLibrary.simpleMessage(
      "Domain",
    ),
    "subscription_details_next_billing": MessageLookupByLibrary.simpleMessage(
      "Next billing",
    ),
    "subscription_details_no": MessageLookupByLibrary.simpleMessage("No"),
    "subscription_details_overdue": MessageLookupByLibrary.simpleMessage(
      "Overdue",
    ),
    "subscription_details_section_about": MessageLookupByLibrary.simpleMessage(
      "About",
    ),
    "subscription_details_section_billing":
        MessageLookupByLibrary.simpleMessage("Billing"),
    "subscription_details_section_details":
        MessageLookupByLibrary.simpleMessage("Details"),
    "subscription_details_service_id": MessageLookupByLibrary.simpleMessage(
      "Service ID",
    ),
    "subscription_details_synced": MessageLookupByLibrary.simpleMessage(
      "Synced",
    ),
    "subscription_details_yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "summary_date": MessageLookupByLibrary.simpleMessage("Billing date"),
    "summary_period": MessageLookupByLibrary.simpleMessage("Period"),
    "summary_price": MessageLookupByLibrary.simpleMessage("Price"),
    "summary_service": MessageLookupByLibrary.simpleMessage("Service"),
    "summary_title": MessageLookupByLibrary.simpleMessage("All set!"),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "title_of_subscription": MessageLookupByLibrary.simpleMessage(
      "Title of subscription",
    ),
    "total_expenses": MessageLookupByLibrary.simpleMessage("Total Expenses"),
    "trial_duration": MessageLookupByLibrary.simpleMessage("Duration"),
    "trial_period": MessageLookupByLibrary.simpleMessage("Trial period"),
    "trial_price": MessageLookupByLibrary.simpleMessage("Trial price"),
    "upcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
    "version": MessageLookupByLibrary.simpleMessage("Version"),
    "wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
    "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "write_a_description": MessageLookupByLibrary.simpleMessage(
      "Optional description...",
    ),
    "write_a_name": MessageLookupByLibrary.simpleMessage("Write a name"),
    "write_here": MessageLookupByLibrary.simpleMessage("Write here..."),
    "you_decide": MessageLookupByLibrary.simpleMessage("You decide"),
  };
}
